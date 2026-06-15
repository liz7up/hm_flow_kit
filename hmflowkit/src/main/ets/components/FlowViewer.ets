import { NodeRenderer } from '../renderer/NodeRenderer'
import { EdgeRenderer, NodeRect } from '../renderer/EdgeRenderer'
import { GridRenderer, GridType, GridConfig } from '../renderer/GridRenderer'
import { CanvasManager, ViewportState } from '../renderer/CanvasManager'
import { HitTestManager, HitType, HitResult } from '../renderer/HitTestManager'
import { GraphModel, GraphNode, GraphEdge } from '../model/GraphModel'
import { RenderConfig } from '../renderer/RenderConfig'
import { BpmnXmlParser } from '../parser/BpmnXmlParser'

@Component
export struct FlowViewer {
  @Prop model: GraphModel = GraphModel.createEmpty()
  @Prop xml: string = ''
  @Prop canvasHeight: number = 600
  @Prop showGrid: boolean = true
  @Prop gridType: GridType = GridType.DOT
  @Prop highlightNodeId: string = ''
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

  aboutToAppear(): void {
    if (this.xml.length > 0) {
      this.model = BpmnXmlParser.parse(this.xml)
    }
    this._needFit = true
    this._highlightId = ''
  }

  build() {
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
            this.renderAll()
          })
      )
  }

  handleClick(event: ClickEvent): void {
    if (!this._canvasReady) return
    this.hitTestManager.rebuild(this.model, this.canvasManager)
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

  getNodePosition(nodeId: string): NodeRect {
    let node: GraphNode | null
    node = this.model.getNode(nodeId)
    if (node !== null) {
      return new NodeRect(node.x, node.y, node.width, node.height)
    }
    return new NodeRect(0, 0, 60, 40)
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

    // Auto-fit: 首次渲染时自动缩放使所有节点可见
    if (this._needFit) {
      this._needFit = false
      let allNodes: GraphNode[]
      allNodes = this.model.getNodes()
      if (allNodes.length > 0 && w > 0 && h > 0) {
        let minX: number = allNodes[0].x
        let minY: number = allNodes[0].y
        let maxX: number = allNodes[0].x + allNodes[0].width
        let maxY: number = allNodes[0].y + allNodes[0].height
        for (let i: number = 1; i < allNodes.length; i++) {
          let nd: GraphNode = allNodes[i]
          if (nd.x < minX) { minX = nd.x }
          if (nd.y < minY) { minY = nd.y }
          let rx: number = nd.x + nd.width
          let ry: number = nd.y + nd.height
          if (rx > maxX) { maxX = rx }
          if (ry > maxY) { maxY = ry }
        }
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

    // Edges
    let edges: GraphEdge[]
    edges = this.model.getEdges()
    for (let i: number = 0; i < edges.length; i++) {
      EdgeRenderer.render(this.ctx, edges[i], (id: string): NodeRect => {
        return this.getNodePosition(id)
      }, 0, 0, 1)
    }

    // Nodes
    let nodes: GraphNode[]
    nodes = this.model.getNodes()
    for (let i: number = 0; i < nodes.length; i++) {
      NodeRenderer.render(this.ctx, nodes[i], this.renderConfig, 0, 0, 1)
    }

    // Highlight overlay — 点击高亮
    if (this._highlightId.length > 0) {
      let hlNode: GraphNode | null
      hlNode = this.model.getNode(this._highlightId)
      if (hlNode !== null) {
        this.ctx.save()
        this.ctx.fillStyle = 'rgba(24, 144, 255, 0.35)'
        this.ctx.fillRect(hlNode.x - 4, hlNode.y - 4, hlNode.width + 8, hlNode.height + 8)
        this.ctx.restore()
      }
    }
  }
}