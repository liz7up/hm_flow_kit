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
  @Prop fitOnLoad: boolean = true
  @Prop highlightNodeId: string = ''
  @Prop readonly: boolean = true

  onNodeClick?: (nodeId: string) => void
  onCanvasReady?: () => void

  private _model: GraphModel = GraphModel.createEmpty()
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
  private _fitDone: boolean = false

  aboutToAppear(): void {
    if (this.xml.length > 0) {
      this._model = BpmnXmlParser.parse(this.xml)
    } else {
      this._model = this.model
    }
    this.hitTestManager.rebuild(this._model, this.canvasManager)
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(this.canvasHeight)
      .onReady(() => {
        this._canvasReady = true
        if (this._canvasWidth > 0 && this._canvasHeight > 0) {
          if (this.fitOnLoad && !this._fitDone) {
            this.fitViewport()
            this._fitDone = true
          }
          this.renderAll()
        }
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
        }
        if (this._canvasReady) {
          if (this.fitOnLoad && !this._fitDone) {
            this.fitViewport()
            this._fitDone = true
          }
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
    this.hitTestManager.rebuild(this._model, this.canvasManager)
    let result: HitResult = this.hitTestManager.hitTest(event.x, event.y, this.canvasManager)
    if (result.type === HitType.NODE && this.onNodeClick) {
      this.onNodeClick(result.nodeId)
    }
  }

  fitViewport(): void {
    let nodes: GraphNode[] = this._model.getNodes()
    if (nodes.length === 0) return

    let minX: number = nodes[0].x
    let minY: number = nodes[0].y
    let maxX: number = nodes[0].x + nodes[0].width
    let maxY: number = nodes[0].y + nodes[0].height

    for (let i: number = 1; i < nodes.length; i++) {
      let node: GraphNode = nodes[i]
      if (node.x < minX) minX = node.x
      if (node.y < minY) minY = node.y
      if (node.x + node.width > maxX) maxX = node.x + node.width
      if (node.y + node.height > maxY) maxY = node.y + node.height
    }

    let contentW: number = maxX - minX
    let contentH: number = maxY - minY
    if (contentW <= 0 || contentH <= 0) return

    let padding: number = 50
    let availableW: number = this._canvasWidth - padding * 2
    let availableH: number = this._canvasHeight - padding * 2
    if (availableW <= 0 || availableH <= 0) return

    let zoomX: number = availableW / contentW
    let zoomY: number = availableH / contentH
    let zoom: number = Math.min(zoomX, zoomY, 1.5)
    zoom = Math.max(0.1, zoom)

    let offsetX: number = (this._canvasWidth - contentW * zoom) / 2 - minX * zoom
    let offsetY: number = (this._canvasHeight - contentH * zoom) / 2 - minY * zoom

    this.canvasManager.setViewport(new ViewportState(zoom, offsetX, offsetY))
  }

  getNodePosition(nodeId: string): NodeRect {
    let node: GraphNode | null = this._model.getNode(nodeId)
    if (node !== null) {
      return new NodeRect(node.x, node.y, node.width, node.height)
    }
    return new NodeRect(0, 0, 60, 40)
  }

  renderAll(): void {
    let w: number = this._canvasWidth
    let h: number = this._canvasHeight
    if (w <= 0 || h <= 0) return

    let zoom: number = this.canvasManager.zoom
    let offsetX: number = this.canvasManager.offsetX
    let offsetY: number = this.canvasManager.offsetY

    this.ctx.setTransform(1, 0, 0, 1, 0, 0)
    this.ctx.clearRect(0, 0, w, h)

    // Grid in screen coords (before canvas transform)
    if (this.showGrid) {
      GridRenderer.render(this.ctx, w, h, offsetX, offsetY, zoom, new GridConfig(this.gridType))
    }

    // Apply canvas transform for content
    this.canvasManager.applyTransform(this.ctx)

    // Edges
    let edges: GraphEdge[] = this._model.getEdges()
    for (let i: number = 0; i < edges.length; i++) {
      EdgeRenderer.render(this.ctx, edges[i], (id: string): NodeRect => {
        return this.getNodePosition(id)
      }, 0, 0, 1)
    }

    // Nodes
    let nodes: GraphNode[] = this._model.getNodes()
    for (let i: number = 0; i < nodes.length; i++) {
      NodeRenderer.render(this.ctx, nodes[i], this.renderConfig, 0, 0, 1)
    }

    // Highlight overlay
    if (this.highlightNodeId.length > 0) {
      let hlNode: GraphNode | null = this._model.getNode(this.highlightNodeId)
      if (hlNode !== null) {
        this.ctx.save()
        this.ctx.fillStyle = 'rgba(24, 144, 255, 0.3)'
        this.ctx.fillRect(hlNode.x - 4, hlNode.y - 4, hlNode.width + 8, hlNode.height + 8)
        this.ctx.restore()
      }
    }
  }
}