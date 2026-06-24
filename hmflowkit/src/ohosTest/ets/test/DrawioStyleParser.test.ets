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

    it('should detect mxgraph.bpmn.shape gateway as rhombus', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=mxgraph.bpmn.shape;background=gateway;');
      expect(s.shapeType).assertEqual('drawio.rhombus');
    });

    it('should detect mxgraph.flowchart.or as rhombus', 0, () => {
      let s: DrawioStyle = DrawioStyleParser.parse('shape=mxgraph.flowchart.or;');
      expect(s.shapeType).assertEqual('drawio.rhombus');
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
