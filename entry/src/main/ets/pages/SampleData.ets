import { BpmnXmlParser } from 'hmflowkit';

// Large BPMN diagram from examples directory
export const LARGE_BPMN_XML: string = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn2:definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:bpmn2="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI" xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL BPMN20.xsd" id="sample-diagram" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn2:process id="Process_1" isExecutable="false">
    <bpmn2:startEvent id="StartEvent_1" name="客户提交贷款申请">
      <bpmn2:outgoing>Flow_1</bpmn2:outgoing>
    </bpmn2:startEvent>
    <bpmn2:userTask id="Activity_1" name="信用评估">
      <bpmn2:incoming>Flow_1</bpmn2:incoming>
      <bpmn2:outgoing>Flow_2</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_1" name="提交" sourceRef="StartEvent_1" targetRef="Activity_1"/>
    <bpmn2:exclusiveGateway id="Gateway_1" name="信用良好?">
      <bpmn2:incoming>Flow_2</bpmn2:incoming>
      <bpmn2:outgoing>Flow_3</bpmn2:outgoing>
      <bpmn2:outgoing>Flow_4</bpmn2:outgoing>
    </bpmn2:exclusiveGateway>
    <bpmn2:sequenceFlow id="Flow_2" name="评估完成" sourceRef="Activity_1" targetRef="Gateway_1"/>
    <bpmn2:userTask id="Activity_2" name="人工审核">
      <bpmn2:incoming>Flow_3</bpmn2:incoming>
      <bpmn2:outgoing>Flow_5</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_3" name="需要审核" sourceRef="Gateway_1" targetRef="Activity_2">
      <bpmn2:conditionExpression xsi:type="bpmn2:tFormalExpression">信用分 < 600</bpmn2:conditionExpression>
    </bpmn2:sequenceFlow>
    <bpmn2:userTask id="Activity_3" name="自动审批">
      <bpmn2:incoming>Flow_4</bpmn2:incoming>
      <bpmn2:outgoing>Flow_6</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_4" name="自动通过" sourceRef="Gateway_1" targetRef="Activity_3">
      <bpmn2:conditionExpression xsi:type="bpmn2:tFormalExpression">信用分 >= 600</bpmn2:conditionExpression>
    </bpmn2:sequenceFlow>
    <bpmn2:exclusiveGateway id="Gateway_2" name="审核通过?">
      <bpmn2:incoming>Flow_5</bpmn2:incoming>
      <bpmn2:incoming>Flow_6</bpmn2:incoming>
      <bpmn2:outgoing>Flow_7</bpmn2:outgoing>
      <bpmn2:outgoing>Flow_8</bpmn2:outgoing>
    </bpmn2:exclusiveGateway>
    <bpmn2:sequenceFlow id="Flow_5" name="审核完成" sourceRef="Activity_2" targetRef="Gateway_2"/>
    <bpmn2:sequenceFlow id="Flow_6" name="自动完成" sourceRef="Activity_3" targetRef="Gateway_2"/>
    <bpmn2:userTask id="Activity_4" name="放款">
      <bpmn2:incoming>Flow_7</bpmn2:incoming>
      <bpmn2:outgoing>Flow_9</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_7" name="通过" sourceRef="Gateway_2" targetRef="Activity_4">
      <bpmn2:conditionExpression xsi:type="bpmn2:tFormalExpression">审核通过</bpmn2:conditionExpression>
    </bpmn2:sequenceFlow>
    <bpmn2:endEvent id="EndEvent_1" name="贷款发放完成">
      <bpmn2:incoming>Flow_9</bpmn2:incoming>
    </bpmn2:endEvent>
    <bpmn2:sequenceFlow id="Flow_9" name="放款完成" sourceRef="Activity_4" targetRef="EndEvent_1"/>
    <bpmn2:userTask id="Activity_5" name="补充材料">
      <bpmn2:incoming>Flow_8</bpmn2:incoming>
      <bpmn2:outgoing>Flow_10</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_8" name="驳回" sourceRef="Gateway_2" targetRef="Activity_5">
      <bpmn2:conditionExpression xsi:type="bpmn2:tFormalExpression">审核不通过</bpmn2:conditionExpression>
    </bpmn2:sequenceFlow>
    <bpmn2:userTask id="Activity_6" name="重新评估">
      <bpmn2:incoming>Flow_10</bpmn2:incoming>
      <bpmn2:outgoing>Flow_11</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_10" name="材料已补充" sourceRef="Activity_5" targetRef="Activity_6"/>
    <bpmn2:sequenceFlow id="Flow_11" name="重新提交" sourceRef="Activity_6" targetRef="Activity_1"/>
    <bpmn2:intermediateCatchEvent id="Event_1" name="等待客户确认">
      <bpmn2:incoming>Flow_12</bpmn2:incoming>
      <bpmn2:outgoing>Flow_13</bpmn2:outgoing>
      <bpmn2:timerEventDefinition/>
    </bpmn2:intermediateCatchEvent>
    <bpmn2:sequenceFlow id="Flow_12" name="需确认" sourceRef="Activity_4" targetRef="Event_1"/>
    <bpmn2:userTask id="Activity_7" name="客户确认">
      <bpmn2:incoming>Flow_13</bpmn2:incoming>
      <bpmn2:outgoing>Flow_14</bpmn2:outgoing>
    </bpmn2:userTask>
    <bpmn2:sequenceFlow id="Flow_13" name="超时提醒" sourceRef="Event_1" targetRef="Activity_7"/>
    <bpmn2:serviceTask id="Activity_8" name="生成合同">
      <bpmn2:incoming>Flow_14</bpmn2:incoming>
      <bpmn2:outgoing>Flow_15</bpmn2:outgoing>
    </bpmn2:serviceTask>
    <bpmn2:sequenceFlow id="Flow_14" name="已确认" sourceRef="Activity_7" targetRef="Activity_8"/>
    <bpmn2:sendTask id="Activity_9" name="发送通知">
      <bpmn2:incoming>Flow_15</bpmn2:incoming>
      <bpmn2:outgoing>Flow_16</bpmn2:outgoing>
    </bpmn2:sendTask>
    <bpmn2:sequenceFlow id="Flow_15" name="合同生成完成" sourceRef="Activity_8" targetRef="Activity_9"/>
    <bpmn2:endEvent id="EndEvent_2" name="流程结束">
      <bpmn2:incoming>Flow_16</bpmn2:incoming>
    </bpmn2:endEvent>
    <bpmn2:sequenceFlow id="Flow_16" name="通知已发送" sourceRef="Activity_9" targetRef="EndEvent_2"/>
  </bpmn2:process>
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="_BPMNShape_StartEvent_2" bpmnElement="StartEvent_1">
        <dc:Bounds x="100" y="200" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_1_di" bpmnElement="Activity_1">
        <dc:Bounds x="200" y="180" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_1_di" bpmnElement="Gateway_1">
        <dc:Bounds x="400" y="190" width="50" height="50"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_2_di" bpmnElement="Activity_2">
        <dc:Bounds x="520" y="80" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_3_di" bpmnElement="Activity_3">
        <dc:Bounds x="520" y="280" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_2_di" bpmnElement="Gateway_2">
        <dc:Bounds x="720" y="190" width="50" height="50"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_4_di" bpmnElement="Activity_4">
        <dc:Bounds x="850" y="80" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
        <dc:Bounds x="1050" y="90" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_5_di" bpmnElement="Activity_5">
        <dc:Bounds x="850" y="280" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_6_di" bpmnElement="Activity_6">
        <dc:Bounds x="1050" y="280" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Event_1_di" bpmnElement="Event_1">
        <dc:Bounds x="1050" y="380" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_7_di" bpmnElement="Activity_7">
        <dc:Bounds x="1160" y="360" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_8_di" bpmnElement="Activity_8">
        <dc:Bounds x="1360" y="360" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_9_di" bpmnElement="Activity_9">
        <dc:Bounds x="1560" y="360" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_2_di" bpmnElement="EndEvent_2">
        <dc:Bounds x="1750" y="370" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
        <di:waypoint x="136" y="218"/>
        <di:waypoint x="200" y="210"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="155" y="200" width="30" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
        <di:waypoint x="320" y="210"/>
        <di:waypoint x="400" y="215"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="345" y="198" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_3_di" bpmnElement="Flow_3">
        <di:waypoint x="425" y="190"/>
        <di:waypoint x="425" y="110"/>
        <di:waypoint x="520" y="110"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="435" y="135" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_4_di" bpmnElement="Flow_4">
        <di:waypoint x="425" y="240"/>
        <di:waypoint x="425" y="310"/>
        <di:waypoint x="520" y="310"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="435" y="270" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_5_di" bpmnElement="Flow_5">
        <di:waypoint x="640" y="110"/>
        <di:waypoint x="720" y="190"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="665" y="135" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_6_di" bpmnElement="Flow_6">
        <di:waypoint x="640" y="310"/>
        <di:waypoint x="720" y="240"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="665" y="260" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_7_di" bpmnElement="Flow_7">
        <di:waypoint x="770" y="215"/>
        <di:waypoint x="850" y="110"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="795" y="150" width="30" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_9_di" bpmnElement="Flow_9">
        <di:waypoint x="970" y="110"/>
        <di:waypoint x="1050" y="108"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="995" y="95" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_8_di" bpmnElement="Flow_8">
        <di:waypoint x="770" y="240"/>
        <di:waypoint x="850" y="310"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="795" y="260" width="30" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_10_di" bpmnElement="Flow_10">
        <di:waypoint x="970" y="310"/>
        <di:waypoint x="1050" y="310"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="995" y="295" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_11_di" bpmnElement="Flow_11">
        <di:waypoint x="1110" y="310"/>
        <di:waypoint x="1110" y="210"/>
        <di:waypoint x="260" y="210"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="1080" y="255" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_12_di" bpmnElement="Flow_12">
        <di:waypoint x="970" y="140"/>
        <di:waypoint x="1010" y="398"/>
        <di:waypoint x="1050" y="398"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="975" y="265" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_13_di" bpmnElement="Flow_13">
        <di:waypoint x="1086" y="398"/>
        <di:waypoint x="1160" y="390"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="1110" y="380" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_14_di" bpmnElement="Flow_14">
        <di:waypoint x="1280" y="390"/>
        <di:waypoint x="1360" y="390"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="1305" y="375" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_15_di" bpmnElement="Flow_15">
        <di:waypoint x="1480" y="390"/>
        <di:waypoint x="1560" y="390"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="1505" y="375" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_16_di" bpmnElement="Flow_16">
        <di:waypoint x="1680" y="390"/>
        <di:waypoint x="1750" y="388"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="1700" y="375" width="50" height="14"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn2:definitions>`;

export const SAMPLE_BPMN_XML: string = `<?xml version="1.0" encoding="UTF-8"?><bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI"><bpmn:process id="Process_loan_approval" name="贷款审批"><bpmn:startEvent id="Start" name="提交"/><bpmn:userTask id="Task1" name="初审"/><bpmn:exclusiveGateway id="Gate1" name="金额"/><bpmn:task id="Task2" name="经理审批"/><bpmn:task id="Task3" name="风控审核"/><bpmn:endEvent id="End" name="完成"/><bpmn:sequenceFlow id="f1" sourceRef="Start" targetRef="Task1"/><bpmn:sequenceFlow id="f2" sourceRef="Task1" targetRef="Gate1"/><bpmn:sequenceFlow id="f3" sourceRef="Gate1" targetRef="Task2" name="<50万"/><bpmn:sequenceFlow id="f4" sourceRef="Gate1" targetRef="Task3" name=">=50万"/><bpmn:sequenceFlow id="f5" sourceRef="Task2" targetRef="End"/><bpmn:sequenceFlow id="f6" sourceRef="Task3" targetRef="End"/></bpmn:process><bpmndi:BPMNDiagram><bpmndi:BPMNShape bpmnElement="Start"><dc:Bounds x="80" y="240" width="36" height="36"/></bpmndi:BPMNShape><bpmndi:BPMNShape bpmnElement="Task1"><dc:Bounds x="180" y="220" width="120" height="60"/></bpmndi:BPMNShape><bpmndi:BPMNShape bpmnElement="Gate1"><dc:Bounds x="380" y="230" width="50" height="50"/></bpmndi:BPMNShape><bpmndi:BPMNShape bpmnElement="Task2"><dc:Bounds x="520" y="140" width="120" height="60"/></bpmndi:BPMNShape><bpmndi:BPMNShape bpmnElement="Task3"><dc:Bounds x="520" y="320" width="120" height="60"/></bpmndi:BPMNShape><bpmndi:BPMNShape bpmnElement="End"><dc:Bounds x="720" y="240" width="36" height="36"/></bpmndi:BPMNShape></bpmndi:BPMNDiagram></bpmn:definitions>`;

export const CPLX1_BPMN_XML: string = `<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:omgdi="http://www.omg.org/spec/DD/20100524/DI" xmlns:omgdc="http://www.omg.org/spec/DD/20100524/DC" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" id="sid-38422fae-e03e-43a3-bef4-bd33b32041b2" targetNamespace="http://bpmn.io/bpmn" exporter="bpmn-js (https://demo.bpmn.io)" exporterVersion="18.16.0">
  <process id="Process_1" isExecutable="false">
    <startEvent id="StartEvent_1y45yut" name="hunger noticed">
      <outgoing>SequenceFlow_0h21x7r</outgoing>
      <outgoing>Flow_1wy3s13</outgoing>
    </startEvent>
    <task id="Task_1hcentk" name="choose recipe">
      <incoming>SequenceFlow_0h21x7r</incoming>
      <incoming>Flow_0l04tch</incoming>
      <outgoing>SequenceFlow_0wnb4ke</outgoing>
    </task>
    <sequenceFlow id="SequenceFlow_0h21x7r" sourceRef="StartEvent_1y45yut" targetRef="Task_1hcentk" />
    <exclusiveGateway id="ExclusiveGateway_15hu1pt" name="desired dish?">
      <incoming>SequenceFlow_0wnb4ke</incoming>
    </exclusiveGateway>
    <sequenceFlow id="SequenceFlow_0wnb4ke" sourceRef="Task_1hcentk" targetRef="ExclusiveGateway_15hu1pt" />
    <sequenceFlow id="Flow_1wy3s13" sourceRef="StartEvent_1y45yut" targetRef="Activity_1plsw3q" />
    <intermediateThrowEvent id="Event_0bfecns" name="12">
      <incoming>Flow_0cy097d</incoming>
      <outgoing>Flow_1i5crlf</outgoing>
    </intermediateThrowEvent>
    <sequenceFlow id="Flow_0cy097d" sourceRef="Activity_1plsw3q" targetRef="Event_0bfecns" />
    <sequenceFlow id="Flow_1i5crlf" sourceRef="Event_0bfecns" targetRef="Activity_1af7d2w" />
    <userTask id="Activity_0qp0vie" name="发">
      <incoming>Flow_1fiis3r</incoming>
      <outgoing>Flow_0l04tch</outgoing>
      <outgoing>Flow_08tbg3y</outgoing>
    </userTask>
    <sequenceFlow id="Flow_1fiis3r" sourceRef="Activity_1af7d2w" targetRef="Activity_0qp0vie" />
    <sequenceFlow id="Flow_0l04tch" sourceRef="Activity_0qp0vie" targetRef="Task_1hcentk" />
    <parallelGateway id="Gateway_0005kl1">
      <incoming>Flow_08tbg3y</incoming>
      <outgoing>Flow_19n2ta5</outgoing>
      <outgoing>Flow_1ynnnfl</outgoing>
      <outgoing>Flow_0jlqzf4</outgoing>
      <outgoing>Flow_0ievvxk</outgoing>
      <outgoing>Flow_1i5anre</outgoing>
      <outgoing>Flow_0yx14j6</outgoing>
    </parallelGateway>
    <sequenceFlow id="Flow_08tbg3y" sourceRef="Activity_0qp0vie" targetRef="Gateway_0005kl1" />
    <sequenceFlow id="Flow_19n2ta5" sourceRef="Gateway_0005kl1" targetRef="Activity_1f05p3r" />
    <exclusiveGateway id="Gateway_1gquo6h">
      <incoming>Flow_1ynnnfl</incoming>
    </exclusiveGateway>
    <sequenceFlow id="Flow_1ynnnfl" sourceRef="Gateway_0005kl1" targetRef="Gateway_1gquo6h" />
    <intermediateThrowEvent id="Event_1cmscuw" name="2134">
      <incoming>Flow_0jlqzf4</incoming>
      <incoming>Flow_1at8ty9</incoming>
      <outgoing>Flow_0vbmm83</outgoing>
    </intermediateThrowEvent>
    <sequenceFlow id="Flow_0jlqzf4" sourceRef="Gateway_0005kl1" targetRef="Event_1cmscuw" />
    <sequenceFlow id="Flow_0ievvxk" sourceRef="Gateway_0005kl1" targetRef="Activity_1h3a3h0" />
    <sendTask id="Activity_1h3a3h0" name="UI">
      <incoming>Flow_0ievvxk</incoming>
      <outgoing>Flow_0djr5im</outgoing>
    </sendTask>
    <manualTask id="Activity_1f05p3r" name="很高">
      <incoming>Flow_19n2ta5</incoming>
      <incoming>Flow_0vbmm83</incoming>
      <outgoing>Flow_0yoqmjc</outgoing>
    </manualTask>
    <scriptTask id="Activity_1af7d2w" name="给他">
      <incoming>Flow_1i5crlf</incoming>
      <outgoing>Flow_1fiis3r</outgoing>
    </scriptTask>
    <callActivity id="Activity_1plsw3q" name="choose recipe">
      <incoming>Flow_1wy3s13</incoming>
      <outgoing>Flow_0cy097d</outgoing>
    </callActivity>
    <sequenceFlow id="Flow_1i5anre" sourceRef="Gateway_0005kl1" targetRef="Activity_1rmpc4s" />
    <businessRuleTask id="Activity_1rmpc4s" name="今年">
      <incoming>Flow_1i5anre</incoming>
      <incoming>Flow_1y51k2u</incoming>
      <outgoing>Flow_1at8ty9</outgoing>
    </businessRuleTask>
    <sequenceFlow id="Flow_0yx14j6" sourceRef="Gateway_0005kl1" targetRef="Activity_1r4iow4" />
    <receiveTask id="Activity_1r4iow4" name="很高1">
      <incoming>Flow_0yx14j6</incoming>
      <incoming>Flow_0djr5im</incoming>
      <outgoing>Flow_1y51k2u</outgoing>
    </receiveTask>
    <sequenceFlow id="Flow_0djr5im" sourceRef="Activity_1h3a3h0" targetRef="Activity_1r4iow4" />
    <sequenceFlow id="Flow_1y51k2u" sourceRef="Activity_1r4iow4" targetRef="Activity_1rmpc4s" />
    <sequenceFlow id="Flow_1at8ty9" sourceRef="Activity_1rmpc4s" targetRef="Event_1cmscuw" />
    <sequenceFlow id="Flow_0vbmm83" sourceRef="Event_1cmscuw" targetRef="Activity_1f05p3r" />
    <exclusiveGateway id="Gateway_0xn6hov">
      <incoming>Flow_0yoqmjc</incoming>
    </exclusiveGateway>
    <sequenceFlow id="Flow_0yoqmjc" sourceRef="Activity_1f05p3r" targetRef="Gateway_0xn6hov" />
    <textAnnotation id="TextAnnotation_1ohab1w">
      <text>note提示</text>
    </textAnnotation>
    <association id="Association_1gyh7vc" associationDirection="None" sourceRef="Event_0bfecns" targetRef="TextAnnotation_1ohab1w" />
    <textAnnotation id="TextAnnotation_0uac5b5">
      <text>note2</text>
    </textAnnotation>
    <association id="Association_0e9yszf" associationDirection="None" sourceRef="Activity_1rmpc4s" targetRef="TextAnnotation_0uac5b5" />
  </process>
  <bpmndi:BPMNDiagram id="BpmnDiagram_1">
    <bpmndi:BPMNPlane id="BpmnPlane_1" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="StartEvent_1y45yut_di" bpmnElement="StartEvent_1y45yut">
        <omgdc:Bounds x="152" y="102" width="36" height="36" />
        <bpmndi:BPMNLabel>
          <omgdc:Bounds x="134" y="145" width="73" height="14" />
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="ExclusiveGateway_15hu1pt_di" bpmnElement="ExclusiveGateway_15hu1pt" isMarkerVisible="true">
        <omgdc:Bounds x="845" y="95" width="50" height="50" />
        <bpmndi:BPMNLabel>
          <omgdc:Bounds x="838" y="152" width="66" height="14" />
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_1hcentk_di" bpmnElement="Task_1hcentk">
        <omgdc:Bounds x="310" y="80" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Event_0bfecns_di" bpmnElement="Event_0bfecns">
        <omgdc:Bounds x="532" y="262" width="36" height="36" />
        <bpmndi:BPMNLabel>
          <omgdc:Bounds x="543" y="238" width="13" height="14" />
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_0qp0vie_di" bpmnElement="Activity_0qp0vie">
        <omgdc:Bounds x="700" y="230" width="100" height="80" />
        <bpmndi:BPMNLabel />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_0005kl1_di" bpmnElement="Gateway_0005kl1">
        <omgdc:Bounds x="905" y="245" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Event_1cmscuw_di" bpmnElement="Event_1cmscuw">
        <omgdc:Bounds x="1072" y="472" width="36" height="36" />
        <bpmndi:BPMNLabel>
          <omgdc:Bounds x="1077" y="515" width="26" height="14" />
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_0zx61p3_di" bpmnElement="Activity_1h3a3h0">
        <omgdc:Bounds x="1070" y="560" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_1i1w5ue_di" bpmnElement="Activity_1f05p3r">
        <omgdc:Bounds x="1060" y="230" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_0ovx86y_di" bpmnElement="Activity_1af7d2w">
        <omgdc:Bounds x="500" y="350" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_15mt6av_di" bpmnElement="Activity_1plsw3q">
        <omgdc:Bounds x="310" y="240" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_0tlw6x4_di" bpmnElement="Activity_1r4iow4">
        <omgdc:Bounds x="1070" y="780" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_1yvfor5_di" bpmnElement="Activity_1rmpc4s">
        <omgdc:Bounds x="700" y="670" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_1gquo6h_di" bpmnElement="Gateway_1gquo6h" isMarkerVisible="true">
        <omgdc:Bounds x="805" y="355" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_0xn6hov_di" bpmnElement="Gateway_0xn6hov" isMarkerVisible="true">
        <omgdc:Bounds x="1265" y="245" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Association_1gyh7vc_di" bpmnElement="Association_1gyh7vc">
        <omgdi:waypoint x="561" y="266" />
        <omgdi:waypoint x="604" y="210" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Association_0e9yszf_di" bpmnElement="Association_0e9yszf">
        <omgdi:waypoint x="750" y="670" />
        <omgdi:waypoint x="749" y="620" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="SequenceFlow_0h21x7r_di" bpmnElement="SequenceFlow_0h21x7r">
        <omgdi:waypoint x="188" y="120" />
        <omgdi:waypoint x="310" y="120" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="SequenceFlow_0wnb4ke_di" bpmnElement="SequenceFlow_0wnb4ke">
        <omgdi:waypoint x="410" y="120" />
        <omgdi:waypoint x="845" y="120" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_1wy3s13_di" bpmnElement="Flow_1wy3s13">
        <omgdi:waypoint x="188" y="120" />
        <omgdi:waypoint x="249" y="120" />
        <omgdi:waypoint x="249" y="280" />
        <omgdi:waypoint x="310" y="280" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0cy097d_di" bpmnElement="Flow_0cy097d">
        <omgdi:waypoint x="410" y="280" />
        <omgdi:waypoint x="532" y="280" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNShape id="TextAnnotation_1ohab1w_di" bpmnElement="TextAnnotation_1ohab1w">
        <omgdc:Bounds x="570" y="170" width="101.99835968017578" height="40" />
        <bpmndi:BPMNLabel />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1i5crlf_di" bpmnElement="Flow_1i5crlf">
        <omgdi:waypoint x="550" y="298" />
        <omgdi:waypoint x="550" y="350" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_1fiis3r_di" bpmnElement="Flow_1fiis3r">
        <omgdi:waypoint x="600" y="390" />
        <omgdi:waypoint x="750" y="390" />
        <omgdi:waypoint x="750" y="310" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0l04tch_di" bpmnElement="Flow_0l04tch">
        <omgdi:waypoint x="700" y="270" />
        <omgdi:waypoint x="665" y="270" />
        <omgdi:waypoint x="665" y="90" />
        <omgdi:waypoint x="410" y="90" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_08tbg3y_di" bpmnElement="Flow_08tbg3y">
        <omgdi:waypoint x="800" y="270" />
        <omgdi:waypoint x="905" y="270" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_19n2ta5_di" bpmnElement="Flow_19n2ta5">
        <omgdi:waypoint x="955" y="270" />
        <omgdi:waypoint x="1060" y="270" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_1ynnnfl_di" bpmnElement="Flow_1ynnnfl">
        <omgdi:waypoint x="930" y="295" />
        <omgdi:waypoint x="930" y="380" />
        <omgdi:waypoint x="855" y="380" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0jlqzf4_di" bpmnElement="Flow_0jlqzf4">
        <omgdi:waypoint x="930" y="295" />
        <omgdi:waypoint x="930" y="490" />
        <omgdi:waypoint x="1072" y="490" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0ievvxk_di" bpmnElement="Flow_0ievvxk">
        <omgdi:waypoint x="930" y="295" />
        <omgdi:waypoint x="930" y="600" />
        <omgdi:waypoint x="1070" y="600" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_1i5anre_di" bpmnElement="Flow_1i5anre">
        <omgdi:waypoint x="930" y="295" />
        <omgdi:waypoint x="930" y="710" />
        <omgdi:waypoint x="800" y="710" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0yx14j6_di" bpmnElement="Flow_0yx14j6">
        <omgdi:waypoint x="930" y="295" />
        <omgdi:waypoint x="930" y="820" />
        <omgdi:waypoint x="1070" y="820" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0djr5im_di" bpmnElement="Flow_0djr5im">
        <omgdi:waypoint x="1120" y="640" />
        <omgdi:waypoint x="1120" y="780" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_1y51k2u_di" bpmnElement="Flow_1y51k2u">
        <omgdi:waypoint x="1070" y="820" />
        <omgdi:waypoint x="935" y="820" />
        <omgdi:waypoint x="935" y="740" />
        <omgdi:waypoint x="800" y="740" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_1at8ty9_di" bpmnElement="Flow_1at8ty9">
        <omgdi:waypoint x="800" y="710" />
        <omgdi:waypoint x="1149" y="710" />
        <omgdi:waypoint x="1149" y="490" />
        <omgdi:waypoint x="1108" y="490" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNShape id="TextAnnotation_0uac5b5_di" bpmnElement="TextAnnotation_0uac5b5">
        <omgdc:Bounds x="699" y="580" width="101.99835968017578" height="40" />
        <bpmndi:BPMNLabel />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_0vbmm83_di" bpmnElement="Flow_0vbmm83">
        <omgdi:waypoint x="1090" y="472" />
        <omgdi:waypoint x="1090" y="391" />
        <omgdi:waypoint x="1110" y="391" />
        <omgdi:waypoint x="1110" y="310" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_0yoqmjc_di" bpmnElement="Flow_0yoqmjc">
        <omgdi:waypoint x="1160" y="270" />
        <omgdi:waypoint x="1265" y="270" />
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</definitions>`;

export function getLargeModel() {
  return BpmnXmlParser.parse(LARGE_BPMN_XML);
}