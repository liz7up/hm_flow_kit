import { describe, it, expect } from '@ohos/hypium';
import { DrawioStyleParser, DrawioStyle } from '../../../main/ets/parser/DrawioStyleParser';

export default function drawioStyleParserTest(): void {
  describe('DrawioStyleParser', () => {

    // ─── Shape detection ───────────────────────────────────────────────

    it('should detect ellipse shape', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('ellipse;whiteSpace=wrap;html=1;');
      expect(s.shapeType).assertEqual('drawio.ellipse');
    });

    it('should detect rhombus shape', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rhombus;whiteSpace=wrap;html=1;');
      expect(s.shapeType).assertEqual('drawio.rhombus');
    });

    it('should detect triangle shape', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('triangle;whiteSpace=wrap;html=1;');
      expect(s.shapeType).assertEqual('drawio.triangle');
    });

    it('should detect parallelogram via shape key', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=parallelogram;whiteSpace=wrap;');
      expect(s.shapeType).assertEqual('drawio.parallelogram');
    });

    it('should detect swimlane', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('swimlane;horizontal=1;whiteSpace=wrap;');
      expect(s.shapeType).assertEqual('drawio.swimlane');
    });

    it('should detect text node', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('text;html=1;whiteSpace=wrap;');
      expect(s.shapeType).assertEqual('drawio.text');
    });

    it('should detect rounded rect via rounded=1', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rounded=1;whiteSpace=wrap;html=1;');
      expect(s.shapeType).assertEqual('drawio.rect');
      expect(s.properties['_rounded']).assertEqual('1');
    });

    it('should detect arcSize as rounded rect', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('arcSize=20;whiteSpace=wrap;html=1;');
      expect(s.shapeType).assertEqual('drawio.rect');
      expect(s.properties['_arcSize']).assertEqual('20');
    });

    // ─── mxgraph namespace shapes ──────────────────────────────────────

    it('should detect mxgraph.flowchart.start_2 as ellipse', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=mxgraph.flowchart.start_2;');
      expect(s.shapeType).assertEqual('drawio.ellipse');
    });

    it('should detect mxgraph.flowchart.end_1 as ellipse', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=mxgraph.flowchart.end_1;');
      expect(s.shapeType).assertEqual('drawio.ellipse');
    });

    it('should detect mxgraph.bpmn.shape gateway → reuse BPMN GatewayDrawer', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=mxgraph.bpmn.shape;background=gateway;');
      expect(s.shapeType).assertEqual('gateway');
    });

    it('should map drawio gateway symbol to BPMN bpmnElement', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.shape;background=gateway;symbol=parallelGw;');
      expect(s.shapeType).assertEqual('gateway');
      expect(s.properties['bpmnElement']).assertEqual('parallelGateway');
    });

    it('should detect mxgraph.flowchart.or as rhombus', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=mxgraph.flowchart.or;');
      expect(s.shapeType).assertEqual('drawio.rhombus');
    });

    // ─── BPMN 2.0 events (shape=mxgraph.bpmn.event) ────────────────────

    it('should detect mxgraph.bpmn.event standard outline as startEvent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=standard;symbol=general;');
      expect(s.shapeType).assertEqual('startEvent');
    });

    it('should detect mxgraph.bpmn.event end outline as endEvent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=end;symbol=general;');
      expect(s.shapeType).assertEqual('endEvent');
    });

    it('should detect mxgraph.bpmn.event throwing as intermediateEvent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=throwing;symbol=general;');
      expect(s.shapeType).assertEqual('intermediateEvent');
    });

    it('should detect mxgraph.bpmn.event catching as intermediateEvent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=catching;symbol=message;');
      expect(s.shapeType).assertEqual('intermediateEvent');
    });

    it('should detect mxgraph.bpmn.event boundInt as boundaryEvent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=boundInt;symbol=error;');
      expect(s.shapeType).assertEqual('boundaryEvent');
    });

    it('should detect mxgraph.bpmn.event boundNonint as boundaryEvent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=boundNonint;symbol=timer;');
      expect(s.shapeType).assertEqual('boundaryEvent');
    });

    it('should set eventDefinition from symbol for message event', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=standard;symbol=message;');
      expect(s.properties['eventDefinition']).assertEqual('messageEventDefinition');
    });

    it('should set eventDefinition from symbol for timer event', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=catching;symbol=timer;');
      expect(s.properties['eventDefinition']).assertEqual('timerEventDefinition');
    });

    it('should set bpmnElement for intermediate throw event', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=throwing;symbol=message;');
      expect(s.properties['bpmnElement']).assertEqual('intermediateThrowEvent');
    });

    it('should set bpmnElement for intermediate catch event', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=catching;symbol=timer;');
      expect(s.properties['bpmnElement']).assertEqual('intermediateCatchEvent');
    });

    it('should set isInterrupting false for non-interrupting event', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=eventInt;symbol=timer;');
      expect(s.properties['isInterrupting']).assertEqual('false');
    });

    it('should set cancelActivity false for non-interrupting boundary', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=boundNonint;symbol=timer;');
      expect(s.properties['cancelActivity']).assertEqual('false');
    });

    it('should skip eventDefinition for general symbol', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.event;outline=standard;symbol=general;');
      expect(s.properties['eventDefinition']).assertEqual(undefined);
    });

    // ─── BPMN 2.0 gateways (shape=mxgraph.bpmn.gateway2) ───────────────

    it('should detect mxgraph.bpmn.gateway2 exclusive as gateway', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.gateway2;gwType=exclusive;outline=none;');
      expect(s.shapeType).assertEqual('gateway');
      expect(s.properties['bpmnElement']).assertEqual('exclusiveGateway');
    });

    it('should detect mxgraph.bpmn.gateway2 parallel as gateway', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.gateway2;gwType=parallel;outline=none;');
      expect(s.shapeType).assertEqual('gateway');
      expect(s.properties['bpmnElement']).assertEqual('parallelGateway');
    });

    it('should detect mxgraph.bpmn.gateway2 inclusive as gateway', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.gateway2;gwType=inclusive;outline=none;');
      expect(s.shapeType).assertEqual('gateway');
      expect(s.properties['bpmnElement']).assertEqual('inclusiveGateway');
    });

    it('should detect mxgraph.bpmn.gateway2 complex as gateway', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.gateway2;gwType=complex;outline=none;');
      expect(s.shapeType).assertEqual('gateway');
      expect(s.properties['bpmnElement']).assertEqual('complexGateway');
    });

    it('should detect mxgraph.bpmn.gateway2 without gwType as eventBasedGateway', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.gateway2;outline=standard;symbol=message;');
      expect(s.shapeType).assertEqual('eventBasedGateway');
      expect(s.properties['bpmnElement']).assertEqual('eventBasedGateway');
    });

    it('should set eventDefinition on event-based gateway', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.gateway2;outline=catching;symbol=timer;');
      expect(s.properties['eventDefinition']).assertEqual('timerEventDefinition');
    });

    // ─── BPMN 2.0 tasks (shape=mxgraph.bpmn.task2) ─────────────────────

    it('should detect mxgraph.bpmn.task2 as task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=abstract;');
      expect(s.shapeType).assertEqual('task');
    });

    it('should detect mxgraph.bpmn.task2 user task with bpmnElement', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=user;');
      expect(s.shapeType).assertEqual('task');
      expect(s.properties['bpmnElement']).assertEqual('userTask');
    });

    it('should detect mxgraph.bpmn.task2 service task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=service;');
      expect(s.properties['bpmnElement']).assertEqual('serviceTask');
    });

    it('should detect mxgraph.bpmn.task2 script task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=script;');
      expect(s.properties['bpmnElement']).assertEqual('scriptTask');
    });

    it('should detect mxgraph.bpmn.task2 manual task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=manual;');
      expect(s.properties['bpmnElement']).assertEqual('manualTask');
    });

    it('should detect mxgraph.bpmn.task2 businessRule task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=businessRule;');
      expect(s.properties['bpmnElement']).assertEqual('businessRuleTask');
    });

    it('should detect mxgraph.bpmn.task2 send task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=send;');
      expect(s.properties['bpmnElement']).assertEqual('sendTask');
    });

    it('should detect mxgraph.bpmn.task2 receive task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;taskMarker=receive;');
      expect(s.properties['bpmnElement']).assertEqual('receiveTask');
    });

    it('should detect mxgraph.bpmn.task2 subprocess', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;bpmnShapeType=subprocess;');
      expect(s.shapeType).assertEqual('subProcess');
    });

    it('should detect mxgraph.bpmn.task2 call activity', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task2;bpmnShapeType=call;');
      expect(s.shapeType).assertEqual('callActivity');
    });

    // ─── BPMN old format shapes ──────────────────────────────────────

    it('should detect mxgraph.bpmn.task (old format) as task', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.task;taskMarker=user;');
      expect(s.shapeType).assertEqual('task');
      expect(s.properties['bpmnElement']).assertEqual('userTask');
    });

    it('should detect mxgraph.bpmn.callActivity (old format)', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.callActivity;');
      expect(s.shapeType).assertEqual('callActivity');
    });

    it('should detect mxgraph.bpmn.subProcess (old format)', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.subProcess;');
      expect(s.shapeType).assertEqual('subProcess');
    });

    // ─── Other BPMN shapes ────────────────────────────────────────────

    it('should detect mxgraph.bpmn.swimlane as drawio.swimlane', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.swimlane;');
      expect(s.shapeType).assertEqual('drawio.swimlane');
    });

    it('should detect mxgraph.bpmn.data2 as dataObject', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.bpmn.data2;');
      expect(s.shapeType).assertEqual('dataObject');
    });

    it('should detect datastore as dataStore', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=datastore;');
      expect(s.shapeType).assertEqual('dataStore');
    });

    it('should detect mxgraph.flowchart.annotation_2 as textAnnotation', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse(
        'shape=mxgraph.flowchart.annotation_2;');
      expect(s.shapeType).assertEqual('textAnnotation');
    });

    it('should default to rect for unknown shape', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('whiteSpace=wrap;html=1;');
      expect(s.shapeType).assertEqual('drawio.rect');
    });

    it('should default to rect for unrecognized shape marker', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('customShape=weirdThing;');
      expect(s.shapeType).assertEqual('drawio.rect');
    });

    // ─── Shape priority ────────────────────────────────────────────────

    it('swimlane takes priority over ellipse', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('swimlane;ellipse;');
      expect(s.shapeType).assertEqual('drawio.swimlane');
    });

    it('text takes priority over rounded', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('text;rounded=1;');
      expect(s.shapeType).assertEqual('drawio.text');
    });

    // ─── Color extraction ──────────────────────────────────────────────

    it('should extract fillColor with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('fillColor=#dae8fc;');
      expect(s.properties['_fillColor']).assertEqual('#dae8fc');
    });

    it('should extract strokeColor with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('strokeColor=#6c8ebf;');
      expect(s.properties['_strokeColor']).assertEqual('#6c8ebf');
    });

    it('should extract fontColor with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('fontColor=#FF0000;');
      expect(s.properties['_fontColor']).assertEqual('#FF0000');
    });

    it('should extract fontSize with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('fontSize=18;');
      expect(s.properties['_fontSize']).assertEqual('18');
    });

    it('should extract align with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('align=left;');
      expect(s.properties['_align']).assertEqual('left');
    });

    it('should extract verticalAlign with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('verticalAlign=top;');
      expect(s.properties['_verticalAlign']).assertEqual('top');
    });

    it('should extract dashed and dashPattern', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('dashed=1;dashPattern=8 8;');
      expect(s.properties['_dashed']).assertEqual('1');
      expect(s.properties['_dashPattern']).assertEqual('8 8');
    });

    // ─── Edge properties ───────────────────────────────────────────────

    it('should extract endArrow with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('endArrow=classic;');
      expect(s.properties['_endArrow']).assertEqual('classic');
    });

    it('should extract startArrow with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('startArrow=classic;');
      expect(s.properties['_startArrow']).assertEqual('classic');
    });

    it('should extract edgeStyle with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('edgeStyle=orthogonalEdgeStyle;');
      expect(s.properties['_edgeStyle']).assertEqual('orthogonalEdgeStyle');
    });

    it('should extract curved with _ prefix', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('curved=1;');
      expect(s.properties['_curved']).assertEqual('1');
    });

    // ─── Default values ────────────────────────────────────────────────

    it('should NOT provide _fillColor default — renderer fallback to config', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rounded=1;');
      expect(s.properties['_fillColor']).assertEqual(undefined);
    });

    it('should NOT provide _strokeColor default — renderer fallback to config', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rounded=1;');
      expect(s.properties['_strokeColor']).assertEqual(undefined);
    });

    it('should NOT provide _fontColor default — renderer fallback to config', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rounded=1;');
      expect(s.properties['_fontColor']).assertEqual(undefined);
    });

    it('should provide default _fontSize when absent', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rounded=1;');
      expect(s.properties['_fontSize']).assertEqual('12');
    });

    // ─── Edge cases ────────────────────────────────────────────────────

    it('should handle empty string', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('');
      expect(s.shapeType).assertEqual('drawio.rect');
    });

    it('should handle trailing semicolon', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('rounded=1;');
      expect(s.shapeType).assertEqual('drawio.rect');
      expect(s.properties['_rounded']).assertEqual('1');
    });

    it('should handle value with equals sign', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('labelPosition=center;verticalLabelPosition=middle;');
      // Unknown keys are silently dropped
      expect(s.properties['labelPosition']).assertEqual(undefined);
    });

    it('unknown style keys should be silently dropped', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('html=1;rounded=1;fillColor=#fff;');
      // html is not in keyMap → dropped
      expect(s.properties['html']).assertEqual(undefined);
      expect(s.properties['_rounded']).assertEqual('1');
      expect(s.properties['_fillColor']).assertEqual('#fff');
    });
  });
}
