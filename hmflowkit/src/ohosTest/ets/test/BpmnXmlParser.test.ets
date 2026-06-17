import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { BpmnXmlParser, ParseResult } from '../../../main/ets/parser/BpmnXmlParser';
import { GraphModel, GraphNode, NodeType, Pool, Lane } from '../../../main/ets/model/GraphModel';

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

    // ── Pool/Lane 解析 ──

    it('parse_collaboration_participant_creates_pool', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getPoolCount()).assertEqual(1);
      let p: Pool | null = model.getPool('Pool1');
      expect(p !== null ? p.name : '').assertEqual('Sales');
      expect(p !== null ? p.isHorizontal : false).assertEqual(true);
    });

    it('parse_laneSet_creates_lanes', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<laneSet>' +
              '<lane id="Lane1" name="Manager">' +
                '<flowNodeRef>task1</flowNodeRef>' +
              '</lane>' +
              '<lane id="Lane2" name="Staff">' +
                '<flowNodeRef>task2</flowNodeRef>' +
              '</lane>' +
            '</laneSet>' +
            '<userTask id="task1"/>' +
            '<userTask id="task2"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="Pool1" isHorizontal="true">' +
              '<Bounds x="0" y="0" width="600" height="400"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="Lane1" isHorizontal="true">' +
              '<Bounds x="0" y="0" width="600" height="200"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="Lane2" isHorizontal="true">' +
              '<Bounds x="0" y="200" width="600" height="200"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let pool: Pool | null = model.getPool('Pool1');
      expect(pool !== null ? pool.lanes.length : -1).assertEqual(2);
      expect(pool !== null ? pool.lanes[0].id : '').assertEqual('Lane1');
      expect(pool !== null ? pool.lanes[1].id : '').assertEqual('Lane2');
    });

    it('parse_flowNodeRef_associates_nodes_with_lanes', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<laneSet>' +
              '<lane id="Lane1" name="Manager">' +
                '<flowNodeRef>task1</flowNodeRef>' +
                '<flowNodeRef>task2</flowNodeRef>' +
              '</lane>' +
            '</laneSet>' +
            '<userTask id="task1"/>' +
            '<userTask id="task2"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let lane: Lane | null = model.getLaneByNode('task1');
      expect(lane !== null ? lane.id : '').assertEqual('Lane1');
      let lane2: Lane | null = model.getLaneByNode('task2');
      expect(lane2 !== null ? lane2.id : '').assertEqual('Lane1');
    });

    it('parse_nested_lanes', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<laneSet>' +
              '<lane id="Lane1" name="Parent">' +
                '<flowNodeRef>t1</flowNodeRef>' +
                '<childLaneSet>' +
                  '<lane id="Child1" name="Child">' +
                    '<flowNodeRef>t2</flowNodeRef>' +
                  '</lane>' +
                '</childLaneSet>' +
              '</lane>' +
            '</laneSet>' +
            '<userTask id="t1"/>' +
            '<userTask id="t2"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let pool: Pool | null = model.getPool('Pool1');
      expect(pool !== null ? pool.lanes.length : -1).assertEqual(1);
      expect(pool !== null ? pool.lanes[0].childLanes.length : -1).assertEqual(1);
      expect(pool !== null ? pool.lanes[0].childLanes[0].id : '').assertEqual('Child1');
      // 深层节点关联
      let childLane: Lane | null = model.getLaneByNode('t2');
      expect(childLane !== null ? childLane.id : '').assertEqual('Child1');
    });

    it('parse_pool_shape_with_isHorizontal_false', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Vertical" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="Pool1" isHorizontal="false">' +
              '<Bounds x="50" y="50" width="400" height="600"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let p: Pool | null = model.getPool('Pool1');
      expect(p !== null ? p.isHorizontal : true).assertEqual(false);
      expect(p !== null ? p.bounds.x : -1).assertEqual(50);
      expect(p !== null ? p.bounds.height : -1).assertEqual(600);
    });

    it('parse_multiple_pools', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
            '<participant id="Pool2" name="Finance" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      expect(model.getPoolCount()).assertEqual(2);
      expect(model.hasPool('Pool1')).assertEqual(true);
      expect(model.hasPool('Pool2')).assertEqual(true);
    });

    it('parse_pool_shape_sets_bounds', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<startEvent id="s1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="Pool1" isHorizontal="true">' +
              '<Bounds x="100" y="200" width="800" height="500"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let p: Pool | null = model.getPool('Pool1');
      expect(p !== null ? p.bounds.x : -1).assertEqual(100);
      expect(p !== null ? p.bounds.y : -1).assertEqual(200);
      expect(p !== null ? p.bounds.width : -1).assertEqual(800);
      expect(p !== null ? p.bounds.height : -1).assertEqual(500);
    });

    it('parse_lane_shape_sets_bounds', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<laneSet>' +
              '<lane id="Lane1" name="Manager"/>' +
            '</laneSet>' +
            '<startEvent id="s1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="Pool1" isHorizontal="true">' +
              '<Bounds x="0" y="0" width="600" height="400"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="Lane1" isHorizontal="true">' +
              '<Bounds x="0" y="0" width="600" height="200"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let pool: Pool | null = model.getPool('Pool1');
      expect(pool !== null ? pool.lanes.length : -1).assertEqual(1);
      expect(pool !== null ? pool.lanes[0].bounds.y : -1).assertEqual(0);
      expect(pool !== null ? pool.lanes[0].bounds.height : -1).assertEqual(200);
    });

    it('parse_lane_without_shape_has_default_bounds', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<laneSet>' +
              '<lane id="Lane1" name="Manager"/>' +
            '</laneSet>' +
            '<startEvent id="s1"/>' +
          '</process>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      let pool: Pool | null = model.getPool('Pool1');
      expect(pool !== null ? pool.lanes.length : -1).assertEqual(1);
      expect(pool !== null ? pool.lanes[0].bounds.x : -1).assertEqual(0);
      expect(pool !== null ? pool.lanes[0].bounds.y : -1).assertEqual(0);
      expect(pool !== null ? pool.lanes[0].bounds.width : -1).assertEqual(0);
      expect(pool !== null ? pool.lanes[0].bounds.height : -1).assertEqual(0);
    });

    it('parse_full_collaboration_end_to_end', 0, () => {
      // 完整 BPMN：collaboration + 多 pool + laneSet + nodes + edges + shapes
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<collaboration id="c1">' +
            '<participant id="Pool1" name="Sales" processRef="p1"/>' +
            '<participant id="Pool2" name="Finance" processRef="p1"/>' +
          '</collaboration>' +
          '<process id="p1">' +
            '<laneSet>' +
              '<lane id="Lane1" name="Manager">' +
                '<flowNodeRef>task1</flowNodeRef>' +
                '<flowNodeRef>task2</flowNodeRef>' +
              '</lane>' +
              '<lane id="Lane2" name="Staff">' +
                '<flowNodeRef>task3</flowNodeRef>' +
              '</lane>' +
            '</laneSet>' +
            '<startEvent id="start1"/>' +
            '<userTask id="task1" name="Approve"/>' +
            '<userTask id="task2" name="Review"/>' +
            '<userTask id="task3" name="Execute"/>' +
            '<endEvent id="end1"/>' +
            '<sequenceFlow id="f1" sourceRef="start1" targetRef="task1"/>' +
            '<sequenceFlow id="f2" sourceRef="task1" targetRef="task2"/>' +
            '<sequenceFlow id="f3" sourceRef="task2" targetRef="task3"/>' +
            '<sequenceFlow id="f4" sourceRef="task3" targetRef="end1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="Pool1" isHorizontal="true">' +
              '<Bounds x="100" y="100" width="600" height="400"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="Pool2" isHorizontal="true">' +
              '<Bounds x="100" y="520" width="600" height="200"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="Lane1" isHorizontal="true">' +
              '<Bounds x="100" y="100" width="600" height="200"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="Lane2" isHorizontal="true">' +
              '<Bounds x="100" y="300" width="600" height="200"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="start1">' +
              '<Bounds x="120" y="130" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="task1">' +
              '<Bounds x="210" y="130" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="task2">' +
              '<Bounds x="380" y="130" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="task3">' +
              '<Bounds x="210" y="330" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="end1">' +
              '<Bounds x="550" y="130" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      model = BpmnXmlParser.parse(xml);
      // Pools
      expect(model.getPoolCount()).assertEqual(2);
      let p1: Pool | null = model.getPool('Pool1');
      expect(p1 !== null ? p1.name : '').assertEqual('Sales');
      expect(p1 !== null ? p1.lanes.length : -1).assertEqual(2);
      let p2: Pool | null = model.getPool('Pool2');
      expect(p2 !== null ? p2.name : '').assertEqual('Finance');
      // Nodes
      expect(model.getNodeCount()).assertEqual(5);
      // Edges
      expect(model.getEdgeCount()).assertEqual(4);
      // Lane-node association
      let lane: Lane | null = model.getLaneByNode('task1');
      expect(lane !== null ? lane.id : '').assertEqual('Lane1');
      let lane2: Lane | null = model.getLaneByNode('task3');
      expect(lane2 !== null ? lane2.id : '').assertEqual('Lane2');
      // Node coordinates from BPMNShape
      let t1 = model.getNode('task1');
      expect(t1 !== null ? t1.x : -1).assertEqual(210);
      expect(t1 !== null ? t1.y : -1).assertEqual(130);
    });
  });
}
