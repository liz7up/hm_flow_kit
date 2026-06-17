/**
 * bpmn-js-examples — Pool/Lane 泳道渲染 Demo
 *
 * 演示如何用 hm-flow-kit 渲染带泳道（Pool/Lane）的 BPMN 协作图。
 * 包含两个内置示例：紧凑手写版 + pizza-collaboration.bpmn 文件版本。
 *
 * 复制本文件到你的 entry/src/main/ets/pages/Index.ets 即可运行。
 */

import { GraphModel, BpmnXmlParser, FlowViewer, GridType } from 'hmflowkit'

// ============================================================
// 示例 1：紧凑 Pool/Lane 图 — 2 Pools, 3 Lanes, 多个节点连线
// ============================================================
const DEMO_POOL_LANE_XML: string = `<?xml version="1.0" encoding="UTF-8"?>
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
      <!-- Pool 1: 销售部 -->
      <bpmndi:BPMNShape bpmnElement="Pool_Sales" isHorizontal="true">
        <dc:Bounds x="40" y="40" width="720" height="260"/>
      </bpmndi:BPMNShape>
      <!-- Lane: 员工 (Pool_Sales 上半部分) -->
      <bpmndi:BPMNShape bpmnElement="Lane_Staff" isHorizontal="true">
        <dc:Bounds x="40" y="40" width="720" height="130"/>
      </bpmndi:BPMNShape>
      <!-- Lane: 经理 (Pool_Sales 下半部分) -->
      <bpmndi:BPMNShape bpmnElement="Lane_Manager" isHorizontal="true">
        <dc:Bounds x="40" y="170" width="720" height="130"/>
      </bpmndi:BPMNShape>
      <!-- Pool 2: 财务部 -->
      <bpmndi:BPMNShape bpmnElement="Pool_Finance" isHorizontal="true">
        <dc:Bounds x="40" y="320" width="720" height="150"/>
      </bpmndi:BPMNShape>
      <!-- 节点 -->
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

// ============================================================
// 可直接替换为 pizza-collaboration.bpmn 的内容来测试大型泳道图
// ============================================================


@Entry
@Component
struct MainPage {
  @State model: GraphModel = GraphModel.createEmpty()
  @State currentDemo: number = 1
  @State xml: string = ''
  @State parseError: string = ''

  aboutToAppear(): void {
    this.loadDemo(this.currentDemo)
  }

  loadDemo(index: number): void {
    this.parseError = ''
    try {
      if (index === 1) {
        this.model = BpmnXmlParser.parse(DEMO_POOL_LANE_XML)
      }
    } catch (e) {
      this.parseError = '解析失败: ' + e
    }
  }

  build() {
    Column() {
      if (this.parseError.length > 0) {
        Text(this.parseError)
          .fontSize(14).fontColor('#FF0000').padding(16)
      }

      FlowViewer({ model: this.model, canvasHeight: 420, showGrid: true })

      Row() {
        Text(`节点: ${this.model.getNodeCount()}`)
          .fontSize(12).padding(4)
        Text(`连线: ${this.model.getEdgeCount()}`)
          .fontSize(12).padding(4)
        Text(`泳池: ${this.model.getPoolCount()}`)
          .fontSize(12).padding(4)
      }
      .padding(8)

      Text('示例 1: 报销审批流程 — 2 Pools (销售部/财务部) + 2 Lanes (经理/员工)')
        .fontSize(11).fontColor('#888888').padding(4)
    }
  }
}
