import { GraphModel, GraphModelSnapshot, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle, RenderConfig, NodeRenderer, EdgeRenderer, GridRenderer, CanvasManager, NodeRect, HitTestManager, HitResult } from 'hmflowkit'

@Entry
@Component
struct Index {
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private model: GraphModel = GraphModel.createEmpty()
  private canvasManager: CanvasManager = new CanvasManager()
  private renderConfig: RenderConfig = new RenderConfig()
  @State testResults: string[] = []
  @State allPassed: boolean = false
  @State testDone: boolean = false

  aboutToAppear(): void {
    this.model = this.buildDemoModel()
    this.runAllTests()
  }

  buildDemoModel(): GraphModel {
    let emptyProps: Record<string, string> = {}
    let model: GraphModel = GraphModel.createEmpty()
    model = model.addNode(new GraphNode('node_1', NodeType.START_EVENT, 80, 240, 48, 48, '开始', emptyProps))
    model = model.addNode(new GraphNode('node_2', NodeType.TASK, 180, 225, 120, 60, '填写申请', emptyProps))
    model = model.addNode(new GraphNode('node_3', NodeType.GATEWAY, 360, 230, 64, 64, '审批判断', emptyProps))
    model = model.addNode(new GraphNode('node_4', NodeType.TASK, 500, 225, 120, 60, '经理审批', emptyProps))
    model = model.addNode(new GraphNode('node_5', NodeType.END_EVENT, 680, 240, 48, 48, '结束', emptyProps))
    model = model.addEdge(new GraphEdge('e1', 'node_1', 'node_2', [], EdgeStyle.POLYLINE, '', emptyProps))
    model = model.addEdge(new GraphEdge('e2', 'node_2', 'node_3', [], EdgeStyle.POLYLINE, '提交', emptyProps))
    model = model.addEdge(new GraphEdge('e3', 'node_3', 'node_4', [], EdgeStyle.POLYLINE, '通过', emptyProps))
    model = model.addEdge(new GraphEdge('e4', 'node_4', 'node_5', [], EdgeStyle.POLYLINE, '', emptyProps))
    return model
  }

  getNodePosition(nodeId: string): NodeRect {
    let node: GraphNode | null = this.model.getNode(nodeId)
    if (node !== null) {
      return new NodeRect(node.x, node.y, node.width, node.height)
    }
    return new NodeRect(0, 0, 60, 40)
  }

  renderAll(): void {
    let zoom: number = this.canvasManager.zoom
    let offsetX: number = this.canvasManager.offsetX
    let offsetY: number = this.canvasManager.offsetY
    let w: number = 800
    let h: number = 500

    // 1. 清屏
    this.ctx.setTransform(1, 0, 0, 1, 0, 0)
    this.ctx.clearRect(0, 0, w, h)

    // 2. 视口变换
    this.canvasManager.applyTransform(this.ctx)

    // 3. 网格
    GridRenderer.render(this.ctx, w, h, offsetX, offsetY, zoom)

    // 4. 连线
    let edges: GraphEdge[] = this.model.getEdges()
    let edgeCount: number = edges.length
    for (let i: number = 0; i < edgeCount; i++) {
      EdgeRenderer.render(this.ctx, edges[i], (id: string): NodeRect => {
        return this.getNodePosition(id)
      }, offsetX, offsetY, zoom)
    }

    // 5. 节点
    let nodes: GraphNode[] = this.model.getNodes()
    let nodeCount: number = nodes.length
    for (let i: number = 0; i < nodeCount; i++) {
      NodeRenderer.render(this.ctx, nodes[i], this.renderConfig, offsetX, offsetY, zoom)
    }
  }

  build(): void {
    Column() {
      Canvas(this.ctx)
        .width('100%')
        .height('60%')
        .onReady(() => {
          this.renderAll()
        })

      Divider().margin({ top: 4, bottom: 4 })

      if (!this.testDone) {
        Text('Model 层测试中...')
          .fontSize(14)
          .fontColor(Color.Gray)
          .padding(12)
      }

      List() {
        ForEach(this.testResults, (item: string) => {
          ListItem() {
            Text(item)
              .fontSize(14)
              .padding(4)
              .fontColor(item.startsWith('❌') ? Color.Red : Color.Green)
          }
        })
      }
      .layoutWeight(1)
      .width('100%')

      if (this.testDone) {
        Text(this.allPassed ? 'Model 验收: 全部通过' : 'Model 验收: 存在失败')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.allPassed ? Color.Green : Color.Red)
          .padding({ top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
  }

  private runAllTests(): void {
    let m: GraphModel = GraphModel.createEmpty()
    let passed: number = 0
    let failed: number = 0

    let logTest = (msg: string, ok: boolean): void => {
      let prefix: string = ok ? '✅ ' : '❌ '
      this.testResults.push(prefix + msg)
      if (ok) { passed++; } else { failed++; }
    }

    // Test 1: 空模型
    logTest('空模型 nodeCount=0', m.getNodeCount() === 0)

    // Test 2: 添加节点
    let n1: GraphNode = new GraphNode('a', NodeType.START_EVENT, 50, 50, 80, 80, '开始', {})
    let n2: GraphNode = new GraphNode('b', NodeType.END_EVENT, 400, 200, 80, 80, '结束', {})
    m = m.addNodes([n1, n2])
    logTest('添加节点 nodeCount=2', m.getNodeCount() === 2)

    // Test 3: 添加连线
    let wp1: Waypoint = new Waypoint(130, 90)
    let wp2: Waypoint = new Waypoint(400, 240)
    let e1: GraphEdge = new GraphEdge('e1', 'a', 'b', [wp1, wp2], EdgeStyle.STRAIGHT, '', {})
    m = m.addEdge(e1)
    logTest('添加连线 edgeCount=1', m.getEdgeCount() === 1)

    // Test 4: 不可变
    let orig: GraphModel = GraphModel.createEmpty()
    let updated: GraphModel = orig.addNode(n1)
    logTest('不可变-原实例不变', orig.getNodeCount() === 0)
    logTest('不可变-新实例包含节点', updated.getNodeCount() === 1)

    // Test 5: 级联删除
    let mDel: GraphModel = m.removeNode('a')
    logTest('删除节点+级联删边', mDel.getNodeCount() === 1 && mDel.getEdgeCount() === 0)

    // Test 6: 序列化 roundtrip
    let snap: GraphModelSnapshot = m.toJSON()
    let restored: GraphModel = GraphModel.fromJSON(snap)
    logTest('序列化 roundtrip', restored.getNodeCount() === 2 && restored.getEdgeCount() === 1)

    // ==================== Spec 02: Canvas + HitTest ====================
    let cm: CanvasManager = new CanvasManager()
    let cp = cm.screenToCanvas(100, 100)
    logTest('Spec02 screenToCanvas', cp.x === 100 && cp.y === 100)

    let sp = cm.canvasToScreen(50, 50)
    logTest('Spec02 canvasToScreen', sp.x === 50 && sp.y === 50)

    cm.zoomAt(200, 200, 2)
    let cp2 = cm.screenToCanvas(300, 300)
    logTest('Spec02 缩放后坐标转换', cp2.x !== 300)

    cm = new CanvasManager()
    cm.pan(10, 20)
    let cp3 = cm.screenToCanvas(60, 80)
    logTest('Spec02 平移后坐标转换', cp3.x === 50 && cp3.y === 60)

    let hitMgr: HitTestManager = new HitTestManager()
    hitMgr.rebuild(m, cm)
    // 节点 b 画布坐标 (400,200)，cm pan(10,20) → 屏幕坐标 (410,220)
    let hit: HitResult = hitMgr.hitTest(410, 220, cm)
    logTest('Spec02 HitTest-命中', hit.nodeId === 'b')
    // (0,0) 屏幕 → 画布 (-10,-20)，不在任何节点内
    let miss: HitResult = hitMgr.hitTest(0, 0, cm)
    logTest('Spec02 HitTest-空白', miss.nodeId === '')

    this.testResults.push('───────')
    let total: number = passed + failed
    this.testResults.push('合计: ' + passed + '/' + total + ' 通过')

    this.allPassed = failed === 0
    this.testDone = true
  }
}