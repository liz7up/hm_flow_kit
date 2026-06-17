import { GraphModel, GraphNode, NodeType, NodeRect, Waypoint, GraphEdge, EdgeStyle, BpmnXmlParser, FlowViewer } from 'hmflowkit'
import { LARGE_BPMN_XML, CPLX1_BPMN_XML } from './SampleData'

const SAMPLE_BPMN_XML: string = `<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
             xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
             xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
             targetNamespace="http://bpmn.io/schema/bpmn">
  <process id="Process_1" isExecutable="false">
    <startEvent id="StartEvent_1" name="开始" />
    <task id="Task_1" name="审批任务" />
    <task id="Task_2" name="会签任务" />
    <endEvent id="EndEvent_1" name="结束" />
    <sequenceFlow id="Flow_1" sourceRef="StartEvent_1" targetRef="Task_1" />
    <sequenceFlow id="Flow_2" sourceRef="Task_1" targetRef="Task_2" />
    <sequenceFlow id="Flow_3" sourceRef="Task_2" targetRef="EndEvent_1" />
  </process>
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="StartEvent_1_di" bpmnElement="StartEvent_1">
        <dc:Bounds x="100" y="200" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_1_di" bpmnElement="Task_1">
        <dc:Bounds x="220" y="180" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_2_di" bpmnElement="Task_2">
        <dc:Bounds x="400" y="180" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
        <dc:Bounds x="580" y="200" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
        <di:waypoint x="136" y="218" />
        <di:waypoint x="220" y="220" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
        <di:waypoint x="320" y="220" />
        <di:waypoint x="400" y="220" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_3_di" bpmnElement="Flow_3">
        <di:waypoint x="500" y="220" />
        <di:waypoint x="580" y="218" />
      </bpmndi:BPMNEdge>
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
      this.parsedModel = BpmnXmlParser.parse(SAMPLE_BPMN_XML)
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
                this.parsedModel = BpmnXmlParser.parse(SAMPLE_BPMN_XML)
              } catch (e) {
                console.error('BPMN XML parse error:', e)
              }
            })
          Button('🔍 高亮开始节点')
            .fontSize(12)
            .onClick(() => {
              this.highlightId = 'StartEvent_1'
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
                this.parsedModel = BpmnXmlParser.parse(SAMPLE_BPMN_XML)
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

        Text(`节点数: ${this.parsedModel.getNodeCount()} | 边数: ${this.parsedModel.getEdgeCount()}`)
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