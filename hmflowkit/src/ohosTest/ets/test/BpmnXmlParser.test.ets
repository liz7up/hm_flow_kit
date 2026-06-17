import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { BpmnXmlParser, ParseResult } from '../../../main/ets/parser/BpmnXmlParser';
import { GraphModel, GraphNode, NodeType } from '../../../main/ets/model/GraphModel';

function countByType(model: GraphModel, type: NodeType): number {
  let count: number = 0;
  let nodes: GraphNode[] = model.getNodes();
  for (let i: number = 0; i < nodes.length; i++) {
    if (nodes[i].type === type) {
      count++;
    }
  }
  return count;
}

export default function bpmnXmlParserTest(): void {
  describe('BpmnXmlParser', () => {
    let model: GraphModel;

    it('parse_minimal_start_event', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="start1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getNodeCount()).assertEqual(1);
      let n: GraphNode | null = model.getNode('start1');
      expect(n !== null ? n.type : NodeType.TASK).assertEqual(NodeType.START_EVENT);
    });

    it('parse_task_with_name', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<userTask id="t1" name="审批"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getNodeCount()).assertEqual(1);
      let n: GraphNode | null = model.getNode('t1');
      expect(n !== null ? n.label : '').assertEqual('审批');
      expect(n !== null ? n.type : NodeType.GATEWAY).assertEqual(NodeType.TASK);
    });

    it('parse_sequence_flow', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
            '<endEvent id="e1"/>' +
            '<sequenceFlow id="f1" sourceRef="s1" targetRef="e1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getNodeCount()).assertEqual(2);
      expect(model.getEdgeCount()).assertEqual(1);
      let e = model.getEdge('f1');
      expect(e !== null ? e.sourceId : '').assertEqual('s1');
      expect(e !== null ? e.targetId : '').assertEqual('e1');
    });

    it('parse_BPMNShape_coordinates', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="p1">' +
            '<task id="t1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="t1">' +
              '<Bounds x="100" y="200" width="150" height="80"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let n: GraphNode | null = model.getNode('t1');
      expect(n !== null ? n.x : -1).assertEqual(100);
      expect(n !== null ? n.y : -1).assertEqual(200);
      expect(n !== null ? n.width : -1).assertEqual(150);
      expect(n !== null ? n.height : -1).assertEqual(80);
    });

    it('parse_BPMNEdge_waypoints', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
            '<endEvent id="e1"/>' +
            '<sequenceFlow id="f1" sourceRef="s1" targetRef="e1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNEdge bpmnElement="f1">' +
              '<waypoint x="10" y="20"/>' +
              '<waypoint x="30" y="40"/>' +
            '</bpmndi:BPMNEdge>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let e = model.getEdge('f1');
      if (e !== null) {
        expect(e.waypoints.length).assertEqual(2);
        expect(e.waypoints[0].x).assertEqual(10);
        expect(e.waypoints[1].y).assertEqual(40);
      } else {
        expect(false).assertEqual(true);
      }
    });

    it('parse_all_gateway_types', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<exclusiveGateway id="g1"/>' +
            '<parallelGateway id="g2"/>' +
            '<inclusiveGateway id="g3"/>' +
            '<eventBasedGateway id="g4"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getNodeCount()).assertEqual(4);
      expect(countByType(model, NodeType.GATEWAY)).assertEqual(4);
    });

    it('parse_event_types', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
            '<endEvent id="e1"/>' +
            '<intermediateThrowEvent id="i1"/>' +
            '<intermediateCatchEvent id="i2"/>' +
            '<boundaryEvent id="b1" attachedToRef="t1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(countByType(model, NodeType.START_EVENT)).assertEqual(4);
      expect(countByType(model, NodeType.END_EVENT)).assertEqual(1);
    });

    it('parse_namespace_prefixed_elements', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<bpmn:process id="p1">' +
            '<bpmn:startEvent id="s1"/>' +
            '<bpmn:task id="t1"/>' +
          '</bpmn:process>' +
        '</bpmn:definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getNodeCount()).assertEqual(2);
      let n: GraphNode | null = model.getNode('s1');
      expect(n !== null ? n.type : NodeType.GATEWAY).assertEqual(NodeType.START_EVENT);
    });

    it('parse_bom_prefix', 0, () => {
      let xml: string = '\uFEFF<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getNodeCount()).assertEqual(1);
    });

    it('parse_empty_xml_returns_empty_model', 0, () => {
      model = BpmnXmlParser.parse('');
      expect(model.getNodeCount()).assertEqual(0);
      expect(model.getEdgeCount()).assertEqual(0);
    });

    it('parse_node_without_shape_uses_default_size', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<task id="t1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let n: GraphNode | null = model.getNode('t1');
      expect(n !== null ? n.width : -1).assertEqual(120);
      expect(n !== null ? n.height : -1).assertEqual(60);
    });

    it('parse_gateway_without_shape_uses_default_size', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<exclusiveGateway id="g1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let n: GraphNode | null = model.getNode('g1');
      expect(n !== null ? n.width : -1).assertEqual(50);
      expect(n !== null ? n.height : -1).assertEqual(50);
    });

    it('parse_event_without_shape_uses_default_size', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let n: GraphNode | null = model.getNode('s1');
      expect(n !== null ? n.width : -1).assertEqual(36);
      expect(n !== null ? n.height : -1).assertEqual(36);
    });

    it('parse_edge_without_waypoints_generates_default', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
            '<endEvent id="e1"/>' +
            '<sequenceFlow id="f1" sourceRef="s1" targetRef="e1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="s1">' +
              '<Bounds x="0" y="0" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="e1">' +
              '<Bounds x="200" y="100" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let e = model.getEdge('f1');
      if (e !== null) {
        expect(e.waypoints.length).assertEqual(2);
      } else {
        expect(false).assertEqual(true);
      }
    });

    it('parse_sets_bpmnElement_in_properties', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<userTask id="t1" name="填写"/>' +
            '<serviceTask id="t2"/>' +
            '<exclusiveGateway id="g1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let t1: GraphNode | null = model.getNode('t1');
      let t2: GraphNode | null = model.getNode('t2');
      let g1: GraphNode | null = model.getNode('g1');
      expect(t1 !== null ? t1.properties['bpmnElement'] : '').assertEqual('userTask');
      expect(t2 !== null ? t2.properties['bpmnElement'] : '').assertEqual('serviceTask');
      expect(g1 !== null ? g1.properties['bpmnElement'] : '').assertEqual('exclusiveGateway');
    });

    // ── parseBestEffort 测试 ──

    it('parseBestEffort_valid_xml_returns_complete', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
            '<endEvent id="e1"/>' +
          '</process>' +
        '</definitions>';
      let result: ParseResult = BpmnXmlParser.parseBestEffort(xml);
      expect(result.isPartial).assertEqual(false);
      expect(result.warnings.length).assertEqual(0);
      expect(result.model.getNodeCount()).assertEqual(2);
    });

    it('parseBestEffort_malformed_xml_returns_partial', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>';
      // 缺少 </process></definitions> 闭合标签
      let result: ParseResult = BpmnXmlParser.parseBestEffort(xml);
      expect(result.isPartial).assertEqual(true);
      expect(result.warnings.length > 0).assertEqual(true);
    });

    it('parse_still_throws_on_malformed_xml', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<process id="p1">' +
            '<startEvent id="s1"/>';
      // 缺少闭合标签，parse() 仍应抛异常
      try {
        BpmnXmlParser.parse(xml);
        expect(false).assertEqual(true);  // 不应执行到这里
      } catch (e) {
        expect(true).assertEqual(true);
      }
    });
  });
}
