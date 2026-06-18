import { NodeRenderer } from '../renderer/NodeRenderer'
import { EdgeRenderer, NodeRect } from '../renderer/EdgeRenderer'
import { GridRenderer, GridType, GridConfig } from '../renderer/GridRenderer'
import { CanvasManager, ViewportState } from '../renderer/CanvasManager'
import { HitTestManager, HitType, HitResult } from '../renderer/HitTestManager'
import { GraphModel, GraphNode, GraphEdge, NodeType, Pool } from '../model/GraphModel'
import { RenderConfig } from '../renderer/RenderConfig'
import { PoolLaneRenderer } from '../renderer/PoolLaneRenderer'
import { BpmnXmlParser } from '../parser/BpmnXmlParser'

@Component
export struct FlowViewer {
  @Prop model: GraphModel = GraphModel.createEmpty()
  @Prop xml: string = ''
  @Prop canvasHeight: number = 600
  @Prop showGrid: boolean = true
  @Prop gridType: GridType = GridType.DOT
  @Prop @Watch('onHighlightChange') highlightNodeId: string = ''
  @Prop readonly: boolean = true

  onNodeClick?: (nodeId: string) => void
  onCanvasReady?: () => void

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private canvasManager: CanvasManager = new CanvasManager()
  private renderConfig: RenderConfig = new RenderConfig()
  private hitTestManager: HitTestManager = new HitTestManager()
  private _canvasWidth: number = 0
  private _canvasHeight: number = 0
  private _canvasReady: boolean = false
  private _lastPanX: number = 0
  private _lastPanY: number = 0
  private _needFit: boolean = true
  private _highlightId: string = ''
  private _pinchStartZoom: number = 1
  private _lastRenderTime: number = 0

  aboutToAppear(): void {
    if (this.xml.length > 0) {
      this.model = BpmnXmlParser.parse(this.xml)
    }
    this.hitTestManager.rebuild(this.model, this.canvasManager, this.renderConfig)
    this._needFit = true
    this._highlightId = ''
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width('100%')
        .height(this.canvasHeight)
        .onReady(() => {
          this._canvasReady = true
          this.renderAll()
          if (this.onCanvasReady) {
            this.onCanvasReady()
          }
        })
        .onAreaChange((_oldValue: Area, newValue: Area) => {
          let w: number = newValue.width as number
          let h: number = newValue.height as number
          if (w > 0 && h > 0) {
            this._canvasWidth = w
            this._canvasHeight = h
            this.renderAll()
          }
        })
        .onClick((event: ClickEvent) => {
          this.handleClick(event)
        })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PanGesture({ distance: 5 })
              .onActionStart((event: GestureEvent) => {
                this._lastPanX = event.offsetX
                this._lastPanY = event.offsetY
              })
              .onActionUpdate((event: GestureEvent) => {
                let dx: number = event.offsetX - this._lastPanX
                let dy: number = event.offsetY - this._lastPanY
                this._lastPanX = event.offsetX
                this._lastPanY = event.offsetY
                this.canvasManager.pan(dx, dy)
                this.renderFrame()
              }),
            PinchGesture({ fingers: 2, distance: 5 })
              .onActionStart((event: GestureEvent) => {
                this._pinchStartZoom = this.canvasManager.zoom
              })
              .onActionUpdate((event: GestureEvent) => {
                let newZoom: number = this._pinchStartZoom * event.scale
                let cx: number = this._canvasWidth > 0 ? this._canvasWidth / 2 : 400
                let cy: number = this._canvasHeight > 0 ? this._canvasHeight / 2 : 300
                this.canvasManager.zoomTo(cx, cy, newZoom)
                this.renderFrame()
              })
          )
        )

      // 缩放控制按钮（触屏 & PC 通用）
      Column() {
        Button({ type: ButtonType.Circle }) {
          Text('+')
            .fontSize(22)
            .fontColor('#333')
            .textAlign(TextAlign.Center)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#D0D0D0' })
        .shadow({ radius: 4, color: '#00000020', offsetY: 2 })
        .onClick(() => {
          this.canvasManager.zoomIn(this._canvasWidth, this._canvasHeight)
          this.renderAll()
        })
        Button({ type: ButtonType.Circle }) {
          Text('-')
            .fontSize(22)
            .fontColor('#333')
            .textAlign(TextAlign.Center)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#D0D0D0' })
        .shadow({ radius: 4, color: '#00000020', offsetY: 2 })
        .margin({ top: 6 })
        .onClick(() => {
          this.canvasManager.zoomOut(this._canvasWidth, this._canvasHeight)
          this.renderAll()
        })
      }
      .position({ right: 14, bottom: 14 })
    }
    .width('100%')
    .height(this.canvasHeight)
  }

  handleClick(event: ClickEvent): void {
    if (!this._canvasReady) return
    let result: HitResult = this.hitTestManager.hitTest(event.x, event.y, this.canvasManager)
    if (result.type === HitType.NODE) {
      this._highlightId = result.nodeId
      this.renderAll()
      if (this.onNodeClick) {
        this.onNodeClick(result.nodeId)
      }
    } else {
      // 点击空白处取消高亮
      if (this._highlightId.length > 0) {
        this._highlightId = ''
        this.renderAll()
      }
    }
  }

  // 节流渲染：限制手势回调重绘频率 ≤ 60fps
  private renderFrame(): void {
    let now: number = Date.now()
    if (now - this._lastRenderTime < 16) {
      return
    }
    this._lastRenderTime = now
    this.renderAll()
  }

  getNodePosition(nodeId: string): NodeRect {
    let node: GraphNode | null
    node = this.model.getNode(nodeId)
    if (node !== null) {
      return new NodeRect(node.x, node.y, node.width, node.height)
    }
    return new NodeRect(0, 0, 60, 40)
  }

  // 外部 prop 变化时触发重绘（无需等待 Canvas onReady）
  onHighlightChange(): void {
    if (this._canvasReady) {
      this.renderAll()
    }
  }

  renderAll(): void {
    let w: number = this._canvasWidth
    let h: number = this._canvasHeight
    // 用 canvasHeight prop 兜底初始渲染尺寸
    if (w <= 0) { w = 800 }
    if (h <= 0) { h = this.canvasHeight }

    let zoom: number = this.canvasManager.zoom
    let offsetX: number = this.canvasManager.offsetX
    let offsetY: number = this.canvasManager.offsetY

    this.ctx.setTransform(1, 0, 0, 1, 0, 0)
    this.ctx.clearRect(0, 0, w, h)

    // Auto-fit: 首次渲染时自动缩放使所有节点和泳道可见
    if (this._needFit) {
      this._needFit = false
      let allNodes: GraphNode[]
      allNodes = this.model.getNodes()
      let allPools: Pool[]
      allPools = this.model.getPools()
      let hasContent: boolean = false
      let minX: number = 0
      let minY: number = 0
      let maxX: number = 0
      let maxY: number = 0

      // 考虑节点范围
      if (allNodes.length > 0) {
        minX = allNodes[0].x
        minY = allNodes[0].y
        maxX = allNodes[0].x + allNodes[0].width
        maxY = allNodes[0].y + allNodes[0].height
        hasContent = true
        for (let i: number = 1; i < allNodes.length; i++) {
          let nd: GraphNode = allNodes[i]
          if (nd.x < minX) { minX = nd.x }
          if (nd.y < minY) { minY = nd.y }
          let rx: number = nd.x + nd.width
          let ry: number = nd.y + nd.height
          if (rx > maxX) { maxX = rx }
          if (ry > maxY) { maxY = ry }
        }
      }

      // 考虑泳道范围
      if (allPools.length > 0) {
        for (let i: number = 0; i < allPools.length; i++) {
          let pool: Pool = allPools[i]
          let px: number = pool.bounds.x
          let py: number = pool.bounds.y
          let prx: number = px + pool.bounds.width
          let pry: number = py + pool.bounds.height
          if (!hasContent) {
            minX = px; minY = py; maxX = prx; maxY = pry
            hasContent = true
          } else {
            if (px < minX) { minX = px }
            if (py < minY) { minY = py }
            if (prx > maxX) { maxX = prx }
            if (pry > maxY) { maxY = pry }
          }
        }
      }

      if (hasContent && w > 0 && h > 0) {
        let contentW: number = maxX - minX
        let contentH: number = maxY - minY
        if (contentW > 0 && contentH > 0) {
          let pad: number = 40
          let fitZoom: number = Math.min((w - pad * 2) / contentW, (h - pad * 2) / contentH)
          if (fitZoom < 0.1) { fitZoom = 0.1 }
          if (fitZoom > 3.0) { fitZoom = 3.0 }
          let fitOX: number = (w - contentW * fitZoom) / 2 - minX * fitZoom
          let fitOY: number = (h - contentH * fitZoom) / 2 - minY * fitZoom
          this.canvasManager.setViewport(new ViewportState(fitZoom, fitOX, fitOY))
          zoom = fitZoom
          offsetX = fitOX
          offsetY = fitOY
        }
      }
    }

    // Grid in screen coords (before canvas transform)
    if (this.showGrid) {
      GridRenderer.render(this.ctx, w, h, offsetX, offsetY, zoom, new GridConfig(this.gridType))
    }

    // Apply canvas transform for content
    this.canvasManager.applyTransform(this.ctx)

    // Pools & Lanes (background, before nodes and edges)
    let pools: Pool[]
    pools = this.model.getPools()
    if (pools.length > 0) {
      PoolLaneRenderer.render(this.ctx, pools, this.renderConfig, 0, 0, 1)
    }

    // 重新应用 Canvas 变换（防止泳道渲染的 save/restore 导致变换矩阵丢失）
    this.canvasManager.applyTransform(this.ctx)

    // Edges
    let edges: GraphEdge[]
    edges = this.model.getEdges()
    for (let i: number = 0; i < edges.length; i++) {
      EdgeRenderer.render(this.ctx, edges[i], (id: string): NodeRect => {
        return this.getNodePosition(id)
      }, 0, 0, 1, this.renderConfig)
    }

    // Nodes — 先普通节点，再边界事件（保证边界事件在最上层不被遮挡）
    let nodes: GraphNode[]
    nodes = this.model.getNodes()
    let boundaryNodes: GraphNode[] = []
    for (let i: number = 0; i < nodes.length; i++) {
      let n: GraphNode = nodes[i]
      if (n.type === NodeType.BOUNDARY_EVENT) {
        boundaryNodes.push(n)
      } else {
        NodeRenderer.render(this.ctx, n, this.renderConfig, 0, 0, 1)
      }
    }
    for (let i: number = 0; i < boundaryNodes.length; i++) {
      NodeRenderer.render(this.ctx, boundaryNodes[i], this.renderConfig, 0, 0, 1)
    }

    // Highlight overlay
    this.canvasManager.applyTransform(this.ctx)
    let activeHighlightId: string = this.highlightNodeId.length > 0
      ? this.highlightNodeId
      : this._highlightId
    if (activeHighlightId.length > 0) {
      let hlNode: GraphNode | null
      hlNode = this.model.getNode(activeHighlightId)
      if (hlNode !== null) {
        this.ctx.fillStyle = 'rgba(24, 144, 255, 0.35)'
        this.ctx.fillRect(hlNode.x - 4, hlNode.y - 4, hlNode.width + 8, hlNode.height + 8)
      }
    }
  }
}