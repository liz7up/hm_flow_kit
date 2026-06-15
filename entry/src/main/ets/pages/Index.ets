import { GraphModel, GraphModelSnapshot, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle, RenderConfig, NodeRenderer, EdgeRenderer, GridRenderer, CanvasManager, NodeRect, HitTestManager, HitResult, BpmnXmlParser } from 'hmflowkit'

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

      Scroll() {
        Text(this.testResults.join('\n'))
          .fontSize(13)
          .padding(8)
          .copyOption(CopyOptions.LocalDevice)
          .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

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
    // logTestV 失败时显示 期望/实际 值
    let logTestV = (msg: string, expected: number, actual: number, ok: boolean): void => {
      let prefix: string = ok ? '✅ ' : '❌ '
      let detail: string = ok ? '' : ' (期望=' + expected + ' 实际=' + actual + ')'
      this.testResults.push(prefix + msg + detail)
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

    // ==================== Spec 03: BPMN Parser ====================
    // 复杂 XML：命名空间 + 6种节点 + 坐标 + waypoints + 条件标签
    let xml: string = '<?xml version="1.0" encoding="UTF-8"?>' +
      '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
      ' xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"' +
      ' xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"' +
      ' xmlns:di="http://www.omg.org/spec/DD/20100524/DI">' +
      '<bpmn:process id="Process_1" name="报销流程">' +
      '<bpmn:startEvent id="Start" name="提交申请"/>' +
      '<bpmn:userTask id="Task1" name="填写报销单"/>' +
      '<bpmn:exclusiveGateway id="Gate1" name="金额判断"/>' +
      '<bpmn:task id="Task2" name="经理审批"/>' +
      '<bpmn:serviceTask id="Task3" name="财务审核"/>' +
      '<bpmn:endEvent id="End" name="完成"/>' +
      '<bpmn:sequenceFlow id="Flow1" sourceRef="Start" targetRef="Task1"/>' +
      '<bpmn:sequenceFlow id="Flow2" sourceRef="Task1" targetRef="Gate1" name="提交"/>' +
      '<bpmn:sequenceFlow id="Flow3" sourceRef="Gate1" targetRef="Task2" name="&gt;1000"/>' +
      '<bpmn:sequenceFlow id="Flow4" sourceRef="Gate1" targetRef="Task3" name="&lt;=1000"/>' +
      '<bpmn:sequenceFlow id="Flow5" sourceRef="Task2" targetRef="End"/>' +
      '<bpmn:sequenceFlow id="Flow6" sourceRef="Task3" targetRef="End"/>' +
      '</bpmn:process>' +
      '<bpmndi:BPMNDiagram>' +
      '<bpmndi:BPMNShape id="s1" bpmnElement="Start"><dc:Bounds x="100" y="200" width="36" height="36"/></bpmndi:BPMNShape>' +
      '<bpmndi:BPMNShape id="s2" bpmnElement="Task1"><dc:Bounds x="200" y="180" width="120" height="60"/></bpmndi:BPMNShape>' +
      '<bpmndi:BPMNShape id="s3" bpmnElement="Gate1"><dc:Bounds x="400" y="190" width="50" height="50"/></bpmndi:BPMNShape>' +
      '<bpmndi:BPMNShape id="s4" bpmnElement="Task2"><dc:Bounds x="550" y="100" width="120" height="60"/></bpmndi:BPMNShape>' +
      '<bpmndi:BPMNShape id="s5" bpmnElement="Task3"><dc:Bounds x="550" y="280" width="120" height="60"/></bpmndi:BPMNShape>' +
      '<bpmndi:BPMNShape id="s6" bpmnElement="End"><dc:Bounds x="750" y="190" width="36" height="36"/></bpmndi:BPMNShape>' +
      '<bpmndi:BPMNEdge id="e1" bpmnElement="Flow1"><di:waypoint x="136" y="218"/><di:waypoint x="200" y="210"/></bpmndi:BPMNEdge>' +
      '<bpmndi:BPMNEdge id="e2" bpmnElement="Flow2"><di:waypoint x="320" y="210"/><di:waypoint x="400" y="215"/></bpmndi:BPMNEdge>' +
      '</bpmndi:BPMNDiagram>' +
      '</bpmn:definitions>'

    let parsed: GraphModel = BpmnXmlParser.parse(xml)
    let nodes: GraphNode[] = parsed.getNodes()
    let edges: GraphEdge[] = parsed.getEdges()

    // 数量校验
    let nodeCount: number = parsed.getNodeCount()
    let edgeCount: number = parsed.getEdgeCount()
    logTestV('Spec03 解析节点数', 6, nodeCount, nodeCount === 6)
    logTestV('Spec03 解析连线数', 6, edgeCount, edgeCount === 6)

    // 调试：第一个节点的实际坐标
    if (nodes.length > 0) {
      let first: GraphNode = nodes[0]
      this.testResults.push('  📐 首节点 ' + first.id + ': x=' + first.x + ' y=' + first.y + ' w=' + first.width + ' h=' + first.height)
    }

    // 类型映射校验
    let byType: Record<string, number> = {}
    for (let i: number = 0; i < nodes.length; i++) {
      let tp: string = nodes[i].type
      byType[tp] = (byType[tp] || 0) + 1
    }
    logTest('Spec03 开始事件=1', (byType['startEvent'] || 0) === 1)
    logTest('Spec03 任务节点=3', (byType['task'] || 0) === 3)  // userTask+task+serviceTask → TASK
    logTest('Spec03 网关节点=1', (byType['gateway'] || 0) === 1)
    logTest('Spec03 结束事件=1', (byType['endEvent'] || 0) === 1)

    // 坐标校验：Gate1 应该从 BPMNShape 读取坐标
    // 调试：手工统计 XML 中的 BPMNShape 数量
    let shapeCount: number = 0
    let pos: number = 0
    while (true) {
      pos = xml.indexOf('BPMNShape', pos)
      if (pos === -1) { break }
      shapeCount++
      pos = pos + 1
    }
    this.testResults.push('  📐 BPMNShape 出现次数: ' + shapeCount)

    // 全部节点坐标
    for (let i: number = 0; i < nodes.length; i++) {
      this.testResults.push('  📐 ' + nodes[i].id + ': (' + nodes[i].x + ',' + nodes[i].y + ') ' + nodes[i].width + 'x' + nodes[i].height)
    }

    let gate: GraphNode | null = parsed.getNode('Gate1')
    if (gate !== null) {
      logTestV('Spec03 Gate1坐标x', 400, gate.x, gate.x === 400)
      logTestV('Spec03 Gate1坐标y', 190, gate.y, gate.y === 190)
    } else {
      logTest('Spec03 Gate1存在', false)
    }

    // Start 坐标
    let start: GraphNode | null = parsed.getNode('Start')
    if (start !== null) {
      logTestV('Spec03 Start坐标x', 100, start.x, start.x === 100)
    } else {
      logTest('Spec03 Start存在', false)
    }

    // 边名映射
    let flow2: GraphEdge | null = parsed.getEdge('Flow2')
    let flow2Label: string = flow2 !== null ? flow2.label : '(null)'
    logTest('Spec03 连线标签=' + flow2Label, flow2 !== null && flow2.label === '提交')

    // waypoints 校验 (Flow1 有2个 waypoints)
    let flow1: GraphEdge | null = parsed.getEdge('Flow1')
    if (flow1 !== null) {
      logTestV('Spec03 waypoints数量', 2, flow1.waypoints.length, flow1.waypoints.length === 2)
    } else {
      logTest('Spec03 Flow1存在', false)
    }

    // 无条件标签的边标签为空
    let f1: GraphEdge | null = parsed.getEdge('Flow1')
    logTest('Spec03 无条件边标签为空', f1 !== null && f1.label === '')

    // 无 BPMNDiagram 的 XML 也能解析（缺省坐标）
    let simpleXml: string = '<?xml version="1.0"?>' +
      '<definitions><process id="p2">' +
      '<startEvent id="s0" name="s"/>' +
      '<endEvent id="e0" name="e"/>' +
      '<sequenceFlow id="f0" sourceRef="s0" targetRef="e0"/>' +
      '</process></definitions>'
    let simpleModel: GraphModel = BpmnXmlParser.parse(simpleXml)
    logTest('Spec03 无DI解析节点=2', simpleModel.getNodeCount() === 2)
    logTest('Spec03 无DI解析连线=1', simpleModel.getEdgeCount() === 1)

    this.testResults.push('───────')
    let total: number = passed + failed
    this.testResults.push('合计: ' + passed + '/' + total + ' 通过')

    this.allPassed = failed === 0
    this.testDone = true
  }
}