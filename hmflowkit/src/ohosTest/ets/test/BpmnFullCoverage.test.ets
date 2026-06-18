/**
 * BpmnFullCoverage — comprehensive BPMN parser + NodeType coverage tests.
 *
 * Tests:
 *  1. cancelActivity capture on boundaryEvent
 *  2. All 5 remaining eventDef tags (cancel, compensate, escalation, conditional, link)
 *  3. loopCharacteristics (multiInstance / standard)
 *  4. association parsed as edge (not as TASK node)
 *  5-9. node type mapping: complexGateway, dataObject, dataStore, textAnnotation, transaction
 *  10-15. NodeType enum values for all non-trivial types
 */

import { describe, it, expect } from '@ohos/hypium';
import { BpmnXmlParser } from '../../../main/ets/parser/BpmnXmlParser';
import { GraphModel, GraphNode, NodeType } from '../../../main/ets/model/GraphModel';

export default function bpmnFullCoverageTest(): void {
  describe('BpmnFullCoverage', () => {
    let model: GraphModel;

    // ── 1. cancelActivity on boundaryEvent ──────────────────────────────────

    it('parse_boundaryEvent_cancelActivity', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<task id="T1"/>' +
            '<boundaryEvent id="BE1" cancelActivity="false">' +
              '<timerEventDefinition/>' +
            '</boundaryEvent>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="T1">' +
              '<Bounds x="100" y="100" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="BE1">' +
              '<Bounds x="210" y="112" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let be: GraphNode | null = m.getNode('BE1');
      expect(be).assertNotNull();
      if (be !== null) {
        expect(be.properties['cancelActivity']).assertEqual('false');
        expect(be.type).assertEqual(NodeType.BOUNDARY_EVENT);
      }
    });

    // ── 2. All 5 remaining eventDefinition tags ─────────────────────────────

    it('parse_new_event_def_tags', 0, () => {
      let tags: string[] = ['cancel', 'compensate', 'escalation', 'conditional', 'link'];
      for (let i: number = 0; i < tags.length; i++) {
        let tag: string = tags[i];
        let xml: string = '<?xml version="1.0"?>' +
          '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL">' +
            '<process id="P1">' +
              '<endEvent id="EV1">' +
                '<' + tag + 'EventDefinition/>' +
              '</endEvent>' +
            '</process>' +
          '</definitions>';
        let m: GraphModel = BpmnXmlParser.parse(xml);
        let ev: GraphNode | null = m.getNode('EV1');
        expect(ev).assertNotNull();
        if (ev !== null) {
          expect(ev.properties['eventDefinition']).assertEqual(tag + 'EventDefinition');
        }
      }
    });

    // ── 3. loopCharacteristics (2 tests) ────────────────────────────────────

    it('parse_loopCharacteristics_multiInstance', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<task id="T1">' +
              '<multiInstanceLoopCharacteristics/>' +
            '</task>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="T1">' +
              '<Bounds x="100" y="100" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let t: GraphNode | null = m.getNode('T1');
      expect(t).assertNotNull();
      if (t !== null) {
        expect(t.properties['loopCharacteristics']).assertEqual('multiInstance');
      }
    });

    it('parse_loopCharacteristics_standard', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<task id="T1">' +
              '<standardLoopCharacteristics/>' +
            '</task>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="T1">' +
              '<Bounds x="100" y="100" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let t: GraphNode | null = m.getNode('T1');
      expect(t).assertNotNull();
      if (t !== null) {
        expect(t.properties['loopCharacteristics']).assertEqual('standard');
      }
    });

    // ── 4. association parsed as edge ───────────────────────────────────────

    it('parse_association_edge', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<task id="T1"/>' +
            '<task id="T2"/>' +
            '<association id="A1" sourceRef="T1" targetRef="T2"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="T1">' +
              '<Bounds x="100" y="100" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNShape bpmnElement="T2">' +
              '<Bounds x="300" y="100" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
            '<bpmndi:BPMNEdge bpmnElement="A1">' +
              '<waypoint x="220" y="130"/>' +
              '<waypoint x="300" y="130"/>' +
            '</bpmndi:BPMNEdge>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      expect(m.getEdgeCount()).assertEqual(1);
      let e = m.getEdge('A1');
      expect(e).assertNotNull();
      if (e !== null) {
        expect(e.properties['bpmnElement']).assertEqual('association');
        expect(e.sourceId).assertEqual('T1');
        expect(e.targetId).assertEqual('T2');
      }
    });

    // ── 5. complexGateway ───────────────────────────────────────────────────

    it('parse_complexGateway_node', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<complexGateway id="CG1" name="Complex"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="CG1">' +
              '<Bounds x="100" y="100" width="50" height="50"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let cg: GraphNode | null = m.getNode('CG1');
      expect(cg).assertNotNull();
      if (cg !== null) {
        expect(cg.type).assertEqual(NodeType.COMPLEX_GATEWAY);
        expect(cg.properties['bpmnElement']).assertEqual('complexGateway');
      }
    });

    // ── 6. dataObject (via dataObjectReference) ─────────────────────────────

    it('parse_dataObject_node', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<dataObjectReference id="DO1" name="Order"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="DO1">' +
              '<Bounds x="100" y="100" width="36" height="50"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let d: GraphNode | null = m.getNode('DO1');
      expect(d).assertNotNull();
      if (d !== null) {
        expect(d.type).assertEqual(NodeType.DATA_OBJECT);
        expect(d.properties['bpmnElement']).assertEqual('dataObjectReference');
      }
    });

    // ── 7. dataStore (via dataStoreReference) ───────────────────────────────

    it('parse_dataStore_node', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<dataStoreReference id="DS1" name="DB"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="DS1">' +
              '<Bounds x="200" y="200" width="50" height="50"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let d: GraphNode | null = m.getNode('DS1');
      expect(d).assertNotNull();
      if (d !== null) {
        expect(d.type).assertEqual(NodeType.DATA_STORE);
        expect(d.properties['bpmnElement']).assertEqual('dataStoreReference');
      }
    });

    // ── 8. textAnnotation ───────────────────────────────────────────────────

    it('parse_textAnnotation_node', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<textAnnotation id="TA1" name="Note"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="TA1">' +
              '<Bounds x="50" y="50" width="100" height="30"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let ta: GraphNode | null = m.getNode('TA1');
      expect(ta).assertNotNull();
      if (ta !== null) {
        expect(ta.type).assertEqual(NodeType.TEXT_ANNOTATION);
        expect(ta.properties['bpmnElement']).assertEqual('textAnnotation');
      }
    });

    // ── 9. transaction (maps to SUB_PROCESS) ────────────────────────────────

    it('parse_transaction_node', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<transaction id="TX1" name="Tx"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="TX1">' +
              '<Bounds x="100" y="100" width="200" height="120"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let tx: GraphNode | null = m.getNode('TX1');
      expect(tx).assertNotNull();
      if (tx !== null) {
        expect(tx.type).assertEqual(NodeType.SUB_PROCESS);
        expect(tx.properties['bpmnElement']).assertEqual('transaction');
      }
    });

    // ── 10. NodeType: boundaryEvent ─────────────────────────────────────────

    it('nodeType_boundaryEvent', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<boundaryEvent id="BE1" attachedToRef="T1">' +
              '<timerEventDefinition/>' +
            '</boundaryEvent>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="BE1">' +
              '<Bounds x="100" y="100" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let be: GraphNode | null = m.getNode('BE1');
      expect(be).assertNotNull();
      if (be !== null) {
        expect(be.type).assertEqual(NodeType.BOUNDARY_EVENT);
      }
    });

    // ── 11. NodeType: intermediateEvent (throw) ─────────────────────────────

    it('nodeType_intermediateEvent', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<intermediateThrowEvent id="IE1"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="IE1">' +
              '<Bounds x="100" y="100" width="36" height="36"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let ie: GraphNode | null = m.getNode('IE1');
      expect(ie).assertNotNull();
      if (ie !== null) {
        expect(ie.type).assertEqual(NodeType.INTERMEDIATE_EVENT);
      }
    });

    // ── 12. NodeType: callActivity ──────────────────────────────────────────

    it('nodeType_callActivity', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<callActivity id="CA1" name="CallSub"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="CA1">' +
              '<Bounds x="100" y="100" width="120" height="60"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let ca: GraphNode | null = m.getNode('CA1');
      expect(ca).assertNotNull();
      if (ca !== null) {
        expect(ca.type).assertEqual(NodeType.CALL_ACTIVITY);
        expect(ca.properties['bpmnElement']).assertEqual('callActivity');
      }
    });

    // ── 13. NodeType: subProcess ────────────────────────────────────────────

    it('nodeType_subProcess', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<subProcess id="SP1" name="Sub"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="SP1">' +
              '<Bounds x="100" y="100" width="200" height="120"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let sp: GraphNode | null = m.getNode('SP1');
      expect(sp).assertNotNull();
      if (sp !== null) {
        expect(sp.type).assertEqual(NodeType.SUB_PROCESS);
      }
    });

    // ── 14. NodeType: eventBasedGateway ─────────────────────────────────────

    it('nodeType_eventBasedGateway', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<eventBasedGateway id="EG1" name="EventGW"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="EG1">' +
              '<Bounds x="100" y="100" width="50" height="50"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let eg: GraphNode | null = m.getNode('EG1');
      expect(eg).assertNotNull();
      if (eg !== null) {
        expect(eg.type).assertEqual(NodeType.EVENT_BASED_GATEWAY);
      }
    });

    // ── 15. NodeType: complexGateway ────────────────────────────────────────

    it('nodeType_complexGateway', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"' +
        '             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI">' +
          '<process id="P1">' +
            '<complexGateway id="CG1" name="ComplexGW"/>' +
          '</process>' +
          '<bpmndi:BPMNDiagram>' +
            '<bpmndi:BPMNShape bpmnElement="CG1">' +
              '<Bounds x="100" y="100" width="50" height="50"/>' +
            '</bpmndi:BPMNShape>' +
          '</bpmndi:BPMNDiagram>' +
        '</definitions>';
      let m: GraphModel = BpmnXmlParser.parse(xml);
      let cg: GraphNode | null = m.getNode('CG1');
      expect(cg).assertNotNull();
      if (cg !== null) {
        expect(cg.type).assertEqual(NodeType.COMPLEX_GATEWAY);
      }
    });
  });
}
