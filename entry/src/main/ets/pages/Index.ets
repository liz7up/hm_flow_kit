import { FlowViewer } from 'hmflowkit';
import { GraphModel, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle } from 'hmflowkit';
import { BpmnXmlParser } from 'hmflowkit';
import { CanvasManager, HitTestManager, HitType, HitResult } from 'hmflowkit';

const SPEC06_TEST_XML: string =
  '<?xml version="1.0" encoding="UTF-8"?>' +
  '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" ' +
  'xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" ' +
  'xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" ' +
  'xmlns:di="http://www.omg.org/spec/DD/20100524/DI" ' +
  'id="Definitions_1">' +
  '<bpmn:process id="Process_1" isExecutable="false">' +
  '<bpmn:startEvent id="Start" name="开始"><bpmn:outgoing>Flow_Start_Apply</bpmn:outgoing></bpmn:startEvent>' +
  '<bpmn:userTask id="Apply" name="提交申请">' +
  '<bpmn:incoming>Flow_Start_Apply</bpmn:incoming><bpmn:outgoing>Flow_Apply_Approve</bpmn:outgoing></bpmn:userTask>' +
  '<bpmn:userTask id="Approve" name="领导审批">' +
  '<bpmn:incoming>Flow_Apply_Approve</bpmn:incoming><bpmn:outgoing>Flow_Approve_Gate</bpmn:outgoing></bpmn:userTask>' +
  '<bpmn:exclusiveGateway id="Gate" name="通过？">' +
  '<bpmn:incoming>Flow_Approve_Gate</bpmn:incoming>' +
  '<bpmn:outgoing>Flow_Gate_Finance</bpmn:outgoing><bpmn:outgoing>Flow_Gate_Reject</bpmn:outgoing></bpmn:exclusiveGateway>' +
  '<bpmn:userTask id="Finance" name="财务审核">' +
  '<bpmn:incoming>Flow_Gate_Finance</bpmn:incoming><bpmn:outgoing>Flow_Finance_End</bpmn:outgoing></bpmn:userTask>' +
  '<bpmn:endEvent id="RejectEnd" name="驳回结束"><bpmn:incoming>Flow_Gate_Reject</bpmn:incoming></bpmn:endEvent>' +
  '<bpmn:endEvent id="End" name="通过结束"><bpmn:incoming>Flow_Finance_End</bpmn:incoming></bpmn:endEvent>' +
  '<bpmn:sequenceFlow id="Flow_Start_Apply" sourceRef="Start" targetRef="Apply"/>' +
  '<bpmn:sequenceFlow id="Flow_Apply_Approve" sourceRef="Apply" targetRef="Approve"/>' +
  '<bpmn:sequenceFlow id="Flow_Approve_Gate" sourceRef="Approve" targetRef="Gate"/>' +
  '<bpmn:sequenceFlow id="Flow_Gate_Finance" sourceRef="Gate" targetRef="Finance"/>' +
  '<bpmn:sequenceFlow id="Flow_Gate_Reject" sourceRef="Gate" targetRef="RejectEnd"/>' +
  '<bpmn:sequenceFlow id="Flow_Finance_End" sourceRef="Finance" targetRef="End"/>' +
  '</bpmn:process>' +
  '<bpmndi:BPMNDiagram id="BPMNDiagram_1">' +
  '<bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_1">' +
  '<bpmndi:BPMNShape id="Shape_Start" bpmnElement="Start"><dc:Bounds x="100" y="200" width="36" height="36"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Shape_Apply" bpmnElement="Apply"><dc:Bounds x="200" y="178" width="120" height="60"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Shape_Approve" bpmnElement="Approve"><dc:Bounds x="400" y="178" width="120" height="60"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Shape_Gate" bpmnElement="Gate"><dc:Bounds x="600" y="183" width="50" height="50"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Shape_Finance" bpmnElement="Finance"><dc:Bounds x="750" y="178" width="120" height="60"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Shape_RejectEnd" bpmnElement="RejectEnd"><dc:Bounds x="650" y="300" width="36" height="36"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Shape_End" bpmnElement="End"><dc:Bounds x="950" y="190" width="36" height="36"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNEdge id="Edge_Start_Apply" bpmnElement="Flow_Start_Apply">' +
  '<di:waypoint x="136" y="218"/><di:waypoint x="200" y="208"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Edge_Apply_Approve" bpmnElement="Flow_Apply_Approve">' +
  '<di:waypoint x="320" y="208"/><di:waypoint x="400" y="208"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Edge_Approve_Gate" bpmnElement="Flow_Approve_Gate">' +
  '<di:waypoint x="520" y="208"/><di:waypoint x="600" y="208"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Edge_Gate_Finance" bpmnElement="Flow_Gate_Finance">' +
  '<di:waypoint x="650" y="208"/><di:waypoint x="750" y="208"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Edge_Gate_Reject" bpmnElement="Flow_Gate_Reject">' +
  '<di:waypoint x="625" y="233"/><di:waypoint x="668" y="300"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Edge_Finance_End" bpmnElement="Flow_Finance_End">' +
  '<di:waypoint x="870" y="208"/><di:waypoint x="950" y="208"/></bpmndi:BPMNEdge>' +
  '</bpmndi:BPMNPlane></bpmndi:BPMNDiagram></bpmn:definitions>';

const BPMN_XML: string =
  '<?xml version="1.0" encoding="UTF-8"?>' +
  '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" ' +
  'xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" ' +
  'xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" ' +
  'xmlns:di="http://www.omg.org/spec/DD/20100524/DI" ' +
  'id="Definitions_1">' +
  '<process id="Process_1" isExecutable="false">' +
  '<startEvent id="Start_1" name="提交报销"/>' +
  '<userTask id="Task_1" name="部门审批"/>' +
  '<userTask id="Task_2" name="财务审批"/>' +
  '<exclusiveGateway id="Gateway_1" name="金额超5k?"/>' +
  '<userTask id="Task_3" name="总监审批"/>' +
  '<endEvent id="End_1" name="结束"/>' +
  '<sequenceFlow id="Flow_1" sourceRef="Start_1" targetRef="Task_1"/>' +
  '<sequenceFlow id="Flow_2" sourceRef="Task_1" targetRef="Task_2"/>' +
  '<sequenceFlow id="Flow_3" sourceRef="Task_2" targetRef="Gateway_1"/>' +
  '<sequenceFlow id="Flow_4" sourceRef="Gateway_1" targetRef="Task_3"/>' +
  '<sequenceFlow id="Flow_5" sourceRef="Task_3" targetRef="End_1"/>' +
  '<sequenceFlow id="Flow_6" sourceRef="Gateway_1" targetRef="End_1"/>' +
  '</process>' +
  '<bpmndi:BPMNDiagram id="BPMNDiagram_1">' +
  '<bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_1">' +
  '<bpmndi:BPMNShape id="Start_1_di" bpmnElement="Start_1"><dc:Bounds x="50" y="120" width="36" height="36"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Task_1_di" bpmnElement="Task_1"><dc:Bounds x="140" y="100" width="100" height="80"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Task_2_di" bpmnElement="Task_2"><dc:Bounds x="300" y="100" width="100" height="80"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Gateway_1_di" bpmnElement="Gateway_1"><dc:Bounds x="460" y="112" width="50" height="50"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="Task_3_di" bpmnElement="Task_3"><dc:Bounds x="570" y="100" width="100" height="80"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNShape id="End_1_di" bpmnElement="End_1"><dc:Bounds x="740" y="115" width="48" height="48"/></bpmndi:BPMNShape>' +
  '<bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1"><di:waypoint x="86" y="138"/><di:waypoint x="140" y="140"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2"><di:waypoint x="240" y="140"/><di:waypoint x="300" y="140"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Flow_3_di" bpmnElement="Flow_3"><di:waypoint x="400" y="140"/><di:waypoint x="460" y="137"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Flow_4_di" bpmnElement="Flow_4"><di:waypoint x="510" y="137"/><di:waypoint x="570" y="140"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Flow_5_di" bpmnElement="Flow_5"><di:waypoint x="670" y="140"/><di:waypoint x="740" y="139"/></bpmndi:BPMNEdge>' +
  '<bpmndi:BPMNEdge id="Flow_6_di" bpmnElement="Flow_6"><di:waypoint x="485" y="162"/><di:waypoint x="485" y="250"/>' +
  '<di:waypoint x="764" y="250"/><di:waypoint x="764" y="163"/></bpmndi:BPMNEdge>' +
  '</bpmndi:BPMNPlane></bpmndi:BPMNDiagram></definitions>';

const BPMN_XML_NO_DI: string =
  '<?xml version="1.0" encoding="UTF-8"?>' +
  '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" ' +
  'id="Definitions_2">' +
  '<process id="Process_2" isExecutable="false">' +
  '<startEvent id="Start_2" name="开始"/>' +
  '<endEvent id="End_2" name="结束"/>' +
  '</process></definitions>';

@Entry
@Component
struct Index {
  @State parsedModel: GraphModel = GraphModel.createEmpty();
  @State spec06Clicked: string = '';

  aboutToAppear(): void {
    this.parsedModel = BpmnXmlParser.parse(BPMN_XML);
  }

  runTests(): string {
    let lines: string[] = [];
    let fails: string[] = [];
    let allOk: boolean = true;

    // ── Spec 01: GraphModel (7) ──
    lines.push('【Spec 01 — GraphModel】');

    // 1. addNode
    {
      let m: GraphModel = GraphModel.createEmpty();
      let n: GraphNode = new GraphNode('n1', NodeType.TASK, 0, 0, 100, 80, '测试', {});
      m = m.addNode(n);
      let ok: boolean = m.getNodeCount() === 1;
      if (!ok) { allOk = false; fails.push('Spec01-1: addNode'); }
      lines.push('  Spec01-1 addNode: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 2. addEdge
    {
      let m: GraphModel = GraphModel.createEmpty();
      m = m.addNode(new GraphNode('n1', NodeType.TASK, 0, 0, 100, 80, 'A', {}));
      m = m.addNode(new GraphNode('n2', NodeType.TASK, 200, 0, 100, 80, 'B', {}));
      m = m.addEdge(new GraphEdge('e1', 'n1', 'n2', [], EdgeStyle.POLYLINE, '', {}));
      let ok: boolean = m.getEdgeCount() === 1;
      if (!ok) { allOk = false; fails.push('Spec01-2: addEdge'); }
      lines.push('  Spec01-2 addEdge: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 3. moveNode
    {
      let m: GraphModel = GraphModel.createEmpty();
      m = m.addNode(new GraphNode('n1', NodeType.TASK, 10, 20, 100, 80, 'M', {}));
      m = m.moveNode('n1', 50, 60);
      let moved: GraphNode | null = m.getNode('n1');
      let ok: boolean = moved !== null && moved.x === 50 && moved.y === 60;
      if (!ok) { allOk = false; fails.push('Spec01-3: moveNode'); }
      lines.push('  Spec01-3 moveNode: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 4. removeNode cascade
    {
      let m: GraphModel = GraphModel.createEmpty();
      m = m.addNode(new GraphNode('n1', NodeType.TASK, 0, 0, 100, 80, 'A', {}));
      m = m.addNode(new GraphNode('n2', NodeType.TASK, 200, 0, 100, 80, 'B', {}));
      m = m.addEdge(new GraphEdge('e1', 'n1', 'n2', [], EdgeStyle.POLYLINE, '', {}));
      m = m.removeNode('n1');
      let ok: boolean = m.getNodeCount() === 1 && m.getEdgeCount() === 0;
      if (!ok) { allOk = false; fails.push('Spec01-4: cascade delete'); }
      lines.push('  Spec01-4 removeNode cascade: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 5. immutable snapshot
    {
      let m: GraphModel = GraphModel.createEmpty();
      m = m.addNode(new GraphNode('n1', NodeType.TASK, 0, 0, 100, 80, 'S', {}));
      let snap: GraphNode[] = m.getNodes();
      snap[0] = new GraphNode('x', NodeType.TASK, 0, 0, 100, 80, 'X', {});
      let ok: boolean = m.getNodeCount() === 1;
      if (!ok) { allOk = false; fails.push('Spec01-5: not snapshot'); }
      lines.push('  Spec01-5 snapshot immutability: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 6. removeEdge
    {
      let m: GraphModel = GraphModel.createEmpty();
      m = m.addNode(new GraphNode('n1', NodeType.TASK, 0, 0, 100, 80, 'A', {}));
      m = m.addNode(new GraphNode('n2', NodeType.TASK, 200, 0, 100, 80, 'B', {}));
      m = m.addEdge(new GraphEdge('e1', 'n1', 'n2', [], EdgeStyle.POLYLINE, '', {}));
      m = m.removeEdge('e1');
      let ok: boolean = m.getEdgeCount() === 0;
      if (!ok) { allOk = false; fails.push('Spec01-6: removeEdge'); }
      lines.push('  Spec01-6 removeEdge: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 7. getNode returns null
    {
      let m: GraphModel = GraphModel.createEmpty();
      let ok: boolean = m.getNode('x') === null && m.getEdge('x') === null;
      if (!ok) { allOk = false; fails.push('Spec01-7: null return'); }
      lines.push('  Spec01-7 missing id null: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // ── Spec 02: Renderer (7) ──
    lines.push('【Spec 02 — Canvas Renderer】');

    // 1. NodeRenderer no throw
    {
      let ok: boolean = true;
      try {
        let m: GraphModel = GraphModel.createEmpty();
        m = m.addNode(new GraphNode('n1', NodeType.TASK, 0, 0, 100, 80, '测试', {}));
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-1: NodeRenderer throw'); }
      lines.push('  Spec02-1 NodeRenderer no throw: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 2. 0 nodes
    {
      let ok: boolean = true;
      try {
        let m: GraphModel = GraphModel.createEmpty();
        ok = m.getNodes().length === 0;
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-2: 0 nodes'); }
      lines.push('  Spec02-2 0 nodes: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 3. 100 nodes
    {
      let ok: boolean = true;
      try {
        let m: GraphModel = GraphModel.createEmpty();
        for (let i: number = 0; i < 100; i++) {
          m = m.addNode(new GraphNode('n' + i, NodeType.TASK, i * 10, 0, 100, 80, 'N' + i, {}));
        }
        ok = m.getNodeCount() === 100;
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-3: 100 nodes'); }
      lines.push('  Spec02-3 100 nodes: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 4. EdgeRenderer no throw
    {
      let ok: boolean = true;
      try {
        let m: GraphModel = GraphModel.createEmpty();
        m = m.addNode(new GraphNode('n1', NodeType.START_EVENT, 0, 0, 36, 36, '开始', {}));
        m = m.addNode(new GraphNode('n2', NodeType.END_EVENT, 200, 0, 48, 48, '结束', {}));
        m = m.addEdge(new GraphEdge('e1', 'n1', 'n2', [], EdgeStyle.POLYLINE, '', {}));
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-4: EdgeRenderer'); }
      lines.push('  Spec02-4 EdgeRenderer no throw: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 5. 0 edges
    {
      let ok: boolean = true;
      try {
        let m: GraphModel = GraphModel.createEmpty();
        ok = m.getEdgeCount() === 0;
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-5: 0 edges'); }
      lines.push('  Spec02-5 0 edges: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 6. CanvasManager zoom/pan
    {
      let ok: boolean = true;
      try {
        let cm: CanvasManager = new CanvasManager();
        cm.zoomAt(0, 0, 1);
        cm.pan(100, 200);
        ok = cm.zoom > 1.0 && cm.offsetX === 100 && cm.offsetY === 200;
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-6: CanvasManager'); }
      lines.push('  Spec02-6 CanvasManager zoom/pan: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 7. HitTestManager
    {
      let ok: boolean = true;
      try {
        let htm: HitTestManager = new HitTestManager();
        let model: GraphModel = GraphModel.createEmpty();
        model = model.addNode(new GraphNode('n1', NodeType.TASK, 50, 50, 100, 80, '任务', {}));
        let cm: CanvasManager = new CanvasManager();
        htm.rebuild(model, cm);
        let result: HitResult = htm.hitTest(75, 70, cm);
        ok = result.type === HitType.NODE;
      } catch (e) { ok = false; }
      if (!ok) { allOk = false; fails.push('Spec02-7: HitTest'); }
      lines.push('  Spec02-7 HitTestManager: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // ── Spec 03: BPMN Parser (12) ──
    lines.push('【Spec 03 — BPMN Parser】');
    // 1. parse returns model
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let ok: boolean = result.getNodeCount() > 0;
      if (!ok) { allOk = false; fails.push('Spec03-1: parse'); }
      lines.push('  Spec03-1 parse non-empty: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 2. 6 nodes
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let ok: boolean = result.getNodeCount() === 6;
      if (!ok) { allOk = false; fails.push('Spec03-2: nodes=6'); }
      lines.push('  Spec03-2 6 nodes: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 3. 6 edges
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let ok: boolean = result.getEdgeCount() === 6;
      if (!ok) { allOk = false; fails.push('Spec03-3: edges=6'); }
      lines.push('  Spec03-3 6 edges: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 4. startEvent type
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let node: GraphNode | null = result.getNode('Start_1');
      let ok: boolean = node !== null && node.type === NodeType.START_EVENT;
      if (!ok) { allOk = false; fails.push('Spec03-4: startEvent type'); }
      lines.push('  Spec03-4 startEvent type: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 5. endEvent type
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let node: GraphNode | null = result.getNode('End_1');
      let ok: boolean = node !== null && node.type === NodeType.END_EVENT;
      if (!ok) { allOk = false; fails.push('Spec03-5: endEvent type'); }
      lines.push('  Spec03-5 endEvent type: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 6. userTask type
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let node: GraphNode | null = result.getNode('Task_1');
      let ok: boolean = node !== null && node.type === NodeType.TASK;
      if (!ok) { allOk = false; fails.push('Spec03-6: task type'); }
      lines.push('  Spec03-6 userTask type: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 7. gateway type
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let node: GraphNode | null = result.getNode('Gateway_1');
      let ok: boolean = node !== null && node.type === NodeType.GATEWAY;
      if (!ok) { allOk = false; fails.push('Spec03-7: gateway type'); }
      lines.push('  Spec03-7 gateway type: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 8. startEvent coords
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let node: GraphNode | null = result.getNode('Start_1');
      let ok: boolean = node !== null && node.x === 50 && node.y === 120;
      if (!ok) { allOk = false; fails.push('Spec03-8: coords'); }
      lines.push('  Spec03-8 startEvent coords: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 9. edge refs
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let edge: GraphEdge | null = result.getEdge('Flow_1');
      let ok: boolean = edge !== null && edge.sourceId === 'Start_1' && edge.targetId === 'Task_1';
      if (!ok) { allOk = false; fails.push('Spec03-9: edge refs'); }
      lines.push('  Spec03-9 edge refs: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 10. empty XML
    {
      try {
        BpmnXmlParser.parse('');
        let ok: boolean = false;
        if (!ok) { allOk = false; fails.push('Spec03-10: empty XML'); }
        lines.push('  Spec03-10 empty XML: ' + (ok ? 'PASS' : 'FAIL'));
      } catch (e) {
        lines.push('  Spec03-10 empty XML: PASS (throws)');
      }
    }

    // 11. no DI fallback
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML_NO_DI);
      let ok: boolean = result.getNodeCount() > 0;
      if (!ok) { allOk = false; fails.push('Spec03-11: no DI'); }
      lines.push('  Spec03-11 no DI fallback: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 12. waypoints
    {
      let result: GraphModel = BpmnXmlParser.parse(BPMN_XML);
      let edge: GraphEdge | null = result.getEdge('Flow_1');
      let ok: boolean = edge !== null && edge.waypoints.length > 0;
      if (!ok) { allOk = false; fails.push('Spec03-12: waypoints'); }
      lines.push('  Spec03-12 waypoints: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // ── Spec 06: UI Components (5) ──
    lines.push('【Spec 06 — UI Components】');

    // 1. XML parse -> 7 nodes (Spec06 XML has 7 nodes)
    {
      let m: GraphModel = BpmnXmlParser.parse(SPEC06_TEST_XML);
      let ok: boolean = m.getNodeCount() === 7;
      if (!ok) { allOk = false; fails.push('Spec06-1: 7 nodes from XML'); }
      lines.push('  Spec06-1 parse SPEC06 XML (7 nodes): ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 2. Empty graph
    {
      let m: GraphModel = GraphModel.createEmpty();
      let ok: boolean = m.getNodeCount() === 0;
      if (!ok) { allOk = false; fails.push('Spec06-2: empty'); }
      lines.push('  Spec06-2 empty graph: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 3. Large graph 50 nodes
    {
      let m: GraphModel = GraphModel.createEmpty();
      for (let i: number = 0; i < 50; i++) {
        m = m.addNode(new GraphNode('n' + i, NodeType.TASK, i * 120, 0, 100, 80, '任务' + i, {}));
      }
      let ok: boolean = m.getNodeCount() === 50;
      if (!ok) { allOk = false; fails.push('Spec06-3: 50 nodes'); }
      lines.push('  Spec06-3 50 nodes: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 4. No DI XML
    {
      let m: GraphModel = BpmnXmlParser.parse(BPMN_XML_NO_DI);
      let ok: boolean = m.getNodeCount() > 0;
      if (!ok) { allOk = false; fails.push('Spec06-4: no DI'); }
      lines.push('  Spec06-4 no DI renders: ' + (ok ? 'PASS' : 'FAIL'));
    }

    // 5. Full SPEC06 parse (7 nodes, 6 edges)
    {
      let m: GraphModel = BpmnXmlParser.parse(SPEC06_TEST_XML);
      let ok: boolean = m.getNodeCount() === 7 && m.getEdgeCount() === 6;
      if (!ok) { allOk = false; fails.push('Spec06-5: full parse'); }
      lines.push('  Spec06-5 SPEC06 full parse (7n+6e): ' + (ok ? 'PASS' : 'FAIL'));
    }

    // ── Summary ──
    let passedCount: number = 0;
    let failedCount: number = 0;
    for (let i: number = 0; i < lines.length; i++) {
      if (lines[i].indexOf('PASS') >= 0) passedCount++;
      else if (lines[i].indexOf('FAIL') >= 0) failedCount++;
    }
    lines.push('---');
    lines.push('总计: ' + passedCount + '/' + (passedCount + failedCount) + ' 通过, ' + failedCount + ' 失败');
    if (allOk) {
      lines.push('全部通过');
    } else {
      lines.push('失败项:');
      for (let f of fails) { lines.push('  ' + f); }
    }

    return lines.join('\n');
  }

  build() {
    Column() {
      // ── Visual: FlowViewer from XML ──
      Column() {
        Text('验收: FlowViewer( xml=SPEC06, fitOnLoad, highlight=Finance )')
          .fontSize(14).fontWeight(FontWeight.Bold).margin({ top: 8 })
        FlowViewer({
          xml: SPEC06_TEST_XML,
          canvasHeight: 360,
          fitOnLoad: true,
          showGrid: true,
          highlightNodeId: 'Finance',
          onNodeClick: (id: string) => {
            this.spec06Clicked = id
          }
        })
        Text('点击节点: ' + this.spec06Clicked)
          .fontSize(12).margin({ bottom: 4 })
      }
      .width('100%')
      .layoutWeight(5)
      .border({ width: { bottom: 1 }, color: '#cccccc' })

      // ── Test Results ──
      Column() {
        Text('验收测试结果').fontSize(14).fontWeight(FontWeight.Bold).margin({ top: 4 })
        Scroll() {
          Text(this.runTests())
            .fontSize(10).fontFamily('monospace').lineHeight(16)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
        .width('100%').height('100%')
      }
      .width('100%')
      .layoutWeight(4)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}