/**
 * bpmn-viewer — hm-flow-kit BPMN XML 查看器示例
 *
 * 演示如何解析 BPMN 2.0 XML 字符串并用 FlowViewer 渲染。
 * 复制本文件到你的 entry/src/main/ets/pages/Index.ets 即可运行。
 */

import { GraphModel, BpmnXmlParser, FlowViewer } from 'hmflowkit'

const DEMO_XML: string = `<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
             xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
             xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
             targetNamespace="http://bpmn.io/schema/bpmn">
  <process id="Process_1" isExecutable="false">
    <startEvent id="StartEvent_1" name="开始" />
    <userTask id="Task_Apply" name="提交申请" />
    <exclusiveGateway id="Gateway_Approve" name="审批?" />
    <serviceTask id="Task_Auto" name="自动处理" />
    <userTask id="Task_Manual" name="人工审核" />
    <endEvent id="EndEvent_1" name="结束" />
    <sequenceFlow id="Flow_1" sourceRef="StartEvent_1" targetRef="Task_Apply" />
    <sequenceFlow id="Flow_2" sourceRef="Task_Apply" targetRef="Gateway_Approve" />
    <sequenceFlow id="Flow_3" sourceRef="Gateway_Approve" targetRef="Task_Auto" name="通过" />
    <sequenceFlow id="Flow_4" sourceRef="Gateway_Approve" targetRef="Task_Manual" name="驳回" />
    <sequenceFlow id="Flow_5" sourceRef="Task_Auto" targetRef="EndEvent_1" />
    <sequenceFlow id="Flow_6" sourceRef="Task_Manual" targetRef="EndEvent_1" />
  </process>
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="StartEvent_1_di" bpmnElement="StartEvent_1">
        <dc:Bounds x="80" y="180" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_Apply_di" bpmnElement="Task_Apply">
        <dc:Bounds x="180" y="160" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_Approve_di" bpmnElement="Gateway_Approve">
        <dc:Bounds x="360" y="175" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_Auto_di" bpmnElement="Task_Auto">
        <dc:Bounds x="480" y="100" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_Manual_di" bpmnElement="Task_Manual">
        <dc:Bounds x="480" y="240" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
        <dc:Bounds x="660" y="180" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
        <di:waypoint x="116" y="198" />
        <di:waypoint x="180" y="200" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
        <di:waypoint x="280" y="200" />
        <di:waypoint x="360" y="200" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_3_di" bpmnElement="Flow_3">
        <di:waypoint x="410" y="190" />
        <di:waypoint x="480" y="140" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_4_di" bpmnElement="Flow_4">
        <di:waypoint x="410" y="210" />
        <di:waypoint x="480" y="280" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_5_di" bpmnElement="Flow_5">
        <di:waypoint x="580" y="140" />
        <di:waypoint x="660" y="198" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_6_di" bpmnElement="Flow_6">
        <di:waypoint x="580" y="280" />
        <di:waypoint x="660" y="216" />
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</definitions>`

@Entry
@Component
struct MainPage {
  @State model: GraphModel = GraphModel.createEmpty()
  @State parseError: string = ''

  aboutToAppear(): void {
    try {
      this.model = BpmnXmlParser.parse(DEMO_XML)
    } catch (e) {
      this.parseError = 'Parse error: ' + e
    }
  }

  build() {
    Column() {
      if (this.parseError.length > 0) {
        Text(this.parseError)
          .fontSize(14).fontColor('#FF0000').padding(16)
      }

      FlowViewer({ model: this.model, canvasHeight: 400, showGrid: true })

      Text(`节点: ${this.model.getNodeCount()}  |  连线: ${this.model.getEdgeCount()}`)
        .fontSize(12).padding(8)
    }
  }
}
