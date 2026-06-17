import { GraphModel, GraphNode, NodeType, NodeRect, Waypoint, GraphEdge, EdgeStyle, BpmnXmlParser, FlowViewer, Pool } from 'hmflowkit'
import { LARGE_BPMN_XML, CPLX1_BPMN_XML } from './SampleData'

// ── Pool/Lane 泳道 Demo ──
const POOL_LANE_XML: string = `<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
             xmlns:dc="http://www.omg.org/spec/DD/20100524/DC">
  <collaboration id="Collab_1">
    <participant id="Pool_Sales" name="销售部" processRef="Process_1"/>
    <participant id="Pool_Finance" name="财务部" processRef="Process_1"/>
  </collaboration>
  <process id="Process_1">
    <laneSet>
      <lane id="Lane_Manager" name="经理">
        <flowNodeRef>Task_Approve</flowNodeRef>
      </lane>
      <lane id="Lane_Staff" name="员工">
        <flowNodeRef>Start_1</flowNodeRef>
        <flowNodeRef>Task_Fill</flowNodeRef>
        <flowNodeRef>Gateway_1</flowNodeRef>
        <flowNodeRef>Task_Pay</flowNodeRef>
        <flowNodeRef>End_1</flowNodeRef>
      </lane>
    </laneSet>
    <startEvent id="Start_1" name="发起"/>
    <userTask id="Task_Fill" name="填写报销单"/>
    <userTask id="Task_Approve" name="经理审批"/>
    <exclusiveGateway id="Gateway_1" name="通过?"/>
    <userTask id="Task_Pay" name="财务打款"/>
    <endEvent id="End_1" name="完成"/>
    <sequenceFlow id="Flow_s_f" sourceRef="Start_1" targetRef="Task_Fill"/>
    <sequenceFlow id="Flow_f_g" sourceRef="Task_Fill" targetRef="Gateway_1"/>
    <sequenceFlow id="Flow_g_a" sourceRef="Gateway_1" targetRef="Task_Approve" name="是"/>
    <sequenceFlow id="Flow_a_p" sourceRef="Task_Approve" targetRef="Task_Pay"/>
    <sequenceFlow id="Flow_g_f" sourceRef="Gateway_1" targetRef="Task_Fill" name="否"/>
    <sequenceFlow id="Flow_p_e" sourceRef="Task_Pay" targetRef="End_1"/>
  </process>
  <bpmndi:BPMNDiagram>
    <bpmndi:BPMNPlane bpmnElement="Process_1">
      <bpmndi:BPMNShape bpmnElement="Pool_Sales" isHorizontal="true">
        <dc:Bounds x="40" y="40" width="720" height="260"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Lane_Staff" isHorizontal="true">
        <dc:Bounds x="40" y="40" width="720" height="130"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Lane_Manager" isHorizontal="true">
        <dc:Bounds x="40" y="170" width="720" height="130"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Pool_Finance" isHorizontal="true">
        <dc:Bounds x="40" y="320" width="720" height="150"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Start_1">
        <dc:Bounds x="80" y="65" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Task_Fill">
        <dc:Bounds x="160" y="55" width="100" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Gateway_1">
        <dc:Bounds x="310" y="58" width="50" height="50"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Task_Approve">
        <dc:Bounds x="420" y="205" width="100" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="Task_Pay">
        <dc:Bounds x="560" y="365" width="100" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="End_1">
        <dc:Bounds x="710" y="377" width="36" height="36"/>
      </bpmndi:BPMNShape>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</definitions>`

// 生成手动构建的示例模型（不依赖 XML 解析）
function buildDemoModel(): GraphModel {
  let model = GraphModel.createEmpty()

  const startNode = new GraphNode('start_1', NodeType.START_EVENT, 80, 160, 40, 40, '开始', {})
  const taskNode = new GraphNode('task_1', NodeType.TASK, 200, 140, 120, 80, '请假审批', { 'assignee': '经理' })
  const task2Node = new GraphNode('task_2', NodeType.TASK, 400, 140, 120, 80, '会签', { 'assignee': '部门主管' })
  const gatewayNode = new GraphNode('gateway_1', NodeType.GATEWAY, 560, 155, 50, 50, '审批通过?', {})
  const endNode = new GraphNode('end_1', NodeType.END_EVENT, 700, 160, 40, 40, '结束', {})

  model = model.addNode(startNode)
  model = model.addNode(taskNode)
  model = model.addNode(task2Node)
  model = model.addNode(gatewayNode)
  model = model.addNode(endNode)

  const edge1: GraphEdge = new GraphEdge('e1', 'start_1', 'task_1',
    [new Waypoint(120, 180), new Waypoint(200, 180)],
    EdgeStyle.POLYLINE, '提交申请', {})
  const edge2: GraphEdge = new GraphEdge('e2', 'task_1', 'task_2',
    [new Waypoint(320, 180), new Waypoint(400, 180)],
    EdgeStyle.POLYLINE, '转交', {})
  const edge3: GraphEdge = new GraphEdge('e3', 'task_2', 'gateway_1',
    [new Waypoint(520, 180), new Waypoint(560, 180)],
    EdgeStyle.POLYLINE, '完成', {})
  const edge4: GraphEdge = new GraphEdge('e4', 'gateway_1', 'end_1',
    [new Waypoint(610, 180), new Waypoint(700, 180)],
    EdgeStyle.POLYLINE, '同意', {})
  const edge5: GraphEdge = new GraphEdge('e5', 'gateway_1', 'task_1',
    [new Waypoint(585, 205), new Waypoint(585, 260), new Waypoint(260, 260), new Waypoint(260, 220)],
    EdgeStyle.POLYLINE, '驳回', {})

  model = model.addEdge(edge1)
  model = model.addEdge(edge2)
  model = model.addEdge(edge3)
  model = model.addEdge(edge4)
  model = model.addEdge(edge5)

  return model
}

@Entry
@Component
struct Index {
  @State model: GraphModel = buildDemoModel()
  @State parsedModel: GraphModel = GraphModel.createEmpty()
  @State viewId: number = 0
  @State fullscreen: boolean = false
  @State highlightId: string = ''
  @State showSample: boolean = false

  aboutToAppear(): void {
    try {
      this.parsedModel = BpmnXmlParser.parse(POOL_LANE_XML)
    } catch (e) {
      console.error('BPMN XML parse error:', e)
    }
  }

  build() {
    Stack() {
      Column() {
        // --- 手动构建的简单流程图 ---
        FlowViewer({ model: this.model, canvasHeight: 200, showGrid: true,
          highlightNodeId: this.highlightId,
          onNodeClick: (id: string) => { console.info('FlowViewer node clicked: ' + id) } })
          .width('100%')

        // --- BPMN 解析渲染的流程图 ---
        FlowViewer({ model: this.parsedModel, canvasHeight: 300, showGrid: true,
          highlightNodeId: this.highlightId,
          onNodeClick: (id: string) => { console.info('FlowViewer node clicked: ' + id) } })
          .width('100%')

        // --- 操作按钮 ---
        Row() {
          Button('🔁 重新解析 BPMN')
            .fontSize(12)
            .onClick(() => {
              this.model = buildDemoModel()
              try {
                this.parsedModel = BpmnXmlParser.parse(POOL_LANE_XML)
              } catch (e) {
                console.error('BPMN XML parse error:', e)
              }
            })
          Button('🔍 高亮发起节点')
            .fontSize(12)
            .onClick(() => {
              this.highlightId = 'Start_1'
            })
          Button('✕ 清除高亮')
            .fontSize(12)
            .onClick(() => {
              this.highlightId = ''
            })
          Button('🔄 重新加载')
            .fontSize(12)
            .onClick(() => {
              this.viewId++
              this.model = buildDemoModel()
              this.parsedModel = GraphModel.createEmpty()
              try {
                this.parsedModel = BpmnXmlParser.parse(POOL_LANE_XML)
              } catch (e) {
                console.error('BPMN XML parse error:', e)
              }
            })
          Button('🔍 新窗口查看')
            .fontSize(12)
            .onClick(() => { this.fullscreen = true; this.viewId++ })
          Button('🧩 复杂流程图')
            .fontSize(11)
            .onClick(() => {
              this.showSample = true
              this.parsedModel = BpmnXmlParser.parse(CPLX1_BPMN_XML)
              this.viewId++
            })
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        .padding(8)

        Text(`节点: ${this.parsedModel.getNodeCount()} | 连线: ${this.parsedModel.getEdgeCount()} | 泳池: ${this.parsedModel.getPoolCount()}`)
          .fontSize(12)
          .padding(8)
      }
      .width('100%')
      .height('100%')

      if (this.fullscreen) {
        Stack() {
          Column() {
            FlowViewer({ model: this.parsedModel, showGrid: true,
              highlightNodeId: this.highlightId,
              onNodeClick: (id: string) => { console.info('FlowViewer node clicked: ' + id) } })
              .width('100%').layoutWeight(1)
          }
          .width('100%').height('100%').backgroundColor('#ffffff')
          Button('✕ 关闭')
            .position({ right: 16, top: 16 })
            .onClick(() => { this.fullscreen = false })
        }
        .width('100%').height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}