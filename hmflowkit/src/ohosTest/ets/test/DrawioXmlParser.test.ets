import { describe, it, expect } from '@ohos/hypium';
import { DrawioXmlParser, DrawioParseResult, DiagramInfo } from '../../../main/ets/parser/DrawioXmlParser';
import { GraphModel, GraphNode, GraphEdge } from '../../../main/ets/model/GraphModel';

// Helper: build a minimal valid drawio XML string
function wrapDrawioXml(cells: string, dx?: string, dy?: string): string {
  let dxVal: string = dx !== undefined ? dx : '1041';
  let dyVal: string = dy !== undefined ? dy : '751';
  return '<?xml version="1.0"?>' +
    '<mxfile host="app.diagrams.net">' +
      '<diagram name="Page-1" id="d1">' +
        '<mxGraphModel dx="' + dxVal + '" dy="' + dyVal + '" grid="1" gridSize="10">' +
          '<root>' +
            '<mxCell id="0"/>' +
            '<mxCell id="1" parent="0"/>' +
            cells +
          '</root>' +
        '</mxGraphModel>' +
      '</diagram>' +
    '</mxfile>';
}

export default function drawioXmlParserTest(): void {
  describe('DrawioXmlParser', () => {

    // ─── Node parsing ─────────────────────────────────────────────────

    it('should parse a single rect vertex', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" style="rounded=1;whiteSpace=wrap;html=1;" value="Hello">' +
          '<mxGeometry x="100" y="200" width="120" height="60" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let model: GraphModel = result.model;
      expect(model.getNodeCount()).assertEqual(1);
      let n: GraphNode | null = model.getNode('n1');
      expect(n !== null ? n.type : '').assertEqual('drawio.rect');
      expect(n !== null ? n.x : -1).assertEqual(100);
      expect(n !== null ? n.y : -1).assertEqual(200);
      expect(n !== null ? n.width : -1).assertEqual(120);
      expect(n !== null ? n.height : -1).assertEqual(60);
      expect(n !== null ? n.label : '').assertEqual('Hello');
    });

    it('should parse an ellipse vertex', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="e1" parent="1" vertex="1" style="ellipse;whiteSpace=wrap;html=1;">' +
          '<mxGeometry x="50" y="60" width="80" height="80" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let n: GraphNode | null = result.model.getNode('e1');
      expect(n !== null ? n.type : '').assertEqual('drawio.ellipse');
    });

    it('should parse a rhombus vertex', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="r1" parent="1" vertex="1" style="rhombus;whiteSpace=wrap;html=1;">' +
          '<mxGeometry x="100" y="100" width="80" height="80" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect((result.model.getNode('r1') as GraphNode).type).assertEqual('drawio.rhombus');
    });

    it('should parse a swimlane vertex', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="s1" parent="1" vertex="1" style="swimlane;horizontal=1;whiteSpace=wrap;html=1;" value="Lane 1">' +
          '<mxGeometry x="50" y="50" width="400" height="200" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let n: GraphNode | null = result.model.getNode('s1');
      expect(n !== null ? n.type : '').assertEqual('drawio.swimlane');
    });

    it('should parse a text vertex', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="t1" parent="1" vertex="1" style="text;html=1;whiteSpace=wrap;" value="Plain text">' +
          '<mxGeometry x="10" y="10" width="100" height="30" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect((result.model.getNode('t1') as GraphNode).type).assertEqual('drawio.text');
    });

    // ─── Edge parsing ──────────────────────────────────────────────────

    it('should parse a simple edge', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" style="rounded=1;">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>' +
        '<mxCell id="n2" parent="1" vertex="1" style="rounded=1;">' +
          '<mxGeometry x="200" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>' +
        '<mxCell id="f1" parent="1" edge="1" source="n1" target="n2" style="endArrow=classic;html=1;">' +
          '<mxGeometry relative="1" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect(result.model.getEdgeCount()).assertEqual(1);
      let e: GraphEdge | null = result.model.getEdge('f1');
      expect(e !== null ? e.sourceId : '').assertEqual('n1');
      expect(e !== null ? e.targetId : '').assertEqual('n2');
    });

    it('should parse edge with waypoints', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>' +
        '<mxCell id="n2" parent="1" vertex="1">' +
          '<mxGeometry x="200" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>' +
        '<mxCell id="f1" parent="1" edge="1" source="n1" target="n2" style="edgeStyle=orthogonalEdgeStyle;">' +
          '<mxGeometry relative="1" as="geometry">' +
            '<Array as="points">' +
              '<mxPoint x="100" y="100"/>' +
              '<mxPoint x="150" y="150"/>' +
            '</Array>' +
          '</mxGeometry>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let e: GraphEdge | null = result.model.getEdge('f1');
      expect(e !== null ? e.waypoints.length : -1).assertEqual(2);
    });

    it('should parse curved edge', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>' +
        '<mxCell id="n2" parent="1" vertex="1">' +
          '<mxGeometry x="200" y="100" width="100" height="60" as="geometry"/>' +
        '</mxCell>' +
        '<mxCell id="f1" parent="1" edge="1" source="n1" target="n2" style="curved=1;endArrow=classic;">' +
          '<mxGeometry relative="1" as="geometry">' +
            '<Array as="points">' +
              '<mxPoint x="80" y="50"/>' +
            '</Array>' +
          '</mxGeometry>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let e: GraphEdge | null = result.model.getEdge('f1');
      expect(e !== null ? e.style : '').assertEqual('curved');
    });

    // ─── Color properties ──────────────────────────────────────────────

    it('should propagate fillColor to node properties', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" style="fillColor=#dae8fc;strokeColor=#6c8ebf;">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let n: GraphNode | null = result.model.getNode('n1');
      expect(n !== null ? n.properties['_fillColor'] : '').assertEqual('#dae8fc');
      expect(n !== null ? n.properties['_strokeColor'] : '').assertEqual('#6c8ebf');
    });

    // ─── HTML stripping ────────────────────────────────────────────────

    it('should strip HTML tags from value', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" value="&lt;h1&gt;Title&lt;/h1&gt;&lt;p&gt;Body text&lt;/p&gt;">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let n: GraphNode | null = result.model.getNode('n1');
      expect(n !== null ? n.label : '').assertEqual('Title\n\nBody text');
    });

    it('should convert br tags to newlines', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" value="Line 1&lt;br&gt;Line 2&lt;br/&gt;Line 3">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect((result.model.getNode('n1') as GraphNode).label).assertEqual('Line 1\nLine 2\nLine 3');
    });

    it('should decode XML character references', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" value="&amp;lt; &amp;gt; &amp;amp; &amp;quot;">' +
          '<mxGeometry x="0" y="0" width="100" height="60" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect((result.model.getNode('n1') as GraphNode).label).assertEqual('< > & "');
    });

    // ─── Multi-page ───────────────────────────────────────────────────

    it('should parse multiple diagrams', 0, () => {
      let xml: string = '<?xml version="1.0"?>' +
        '<mxfile host="app.diagrams.net">' +
          '<diagram name="Page-1" id="d1">' +
            '<mxGraphModel>' +
              '<root><mxCell id="0"/><mxCell id="1" parent="0"/>' +
                '<mxCell id="n1" parent="1" vertex="1">' +
                  '<mxGeometry x="10" y="10" width="50" height="50" as="geometry"/>' +
                '</mxCell>' +
              '</root>' +
            '</mxGraphModel>' +
          '</diagram>' +
          '<diagram name="Page-2" id="d2">' +
            '<mxGraphModel>' +
              '<root><mxCell id="0"/><mxCell id="1" parent="0"/>' +
                '<mxCell id="n2" parent="1" vertex="1">' +
                  '<mxGeometry x="20" y="20" width="50" height="50" as="geometry"/>' +
                '</mxCell>' +
              '</root>' +
            '</mxGraphModel>' +
          '</diagram>' +
        '</mxfile>';
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect(result.pages.length).assertEqual(2);
      expect(result.pages[0].name).assertEqual('Page-1');
      expect(result.pages[1].name).assertEqual('Page-2');
      // First page is the default model
      expect(result.model.getNodeCount()).assertEqual(1);
      expect((result.model.getNode('n1') as GraphNode).x).assertEqual(10);
      // Second page has its own model
      expect(result.pages[1].model.getNodeCount()).assertEqual(1);
    });

    // ─── Unknown shape fallback ───────────────────────────────────────

    it('should fallback unknown shape to rect with colors preserved', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="u1" parent="1" vertex="1" style="shape=umlClass;fillColor=#FFE0B2;strokeColor=#E65100;">' +
          '<mxGeometry x="100" y="100" width="180" height="120" as="geometry"/>' +
        '</mxCell>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let n: GraphNode | null = result.model.getNode('u1');
      expect(n !== null ? n.type : '').assertEqual('drawio.rect');
      expect(n !== null ? n.properties['_fillColor'] : '').assertEqual('#FFE0B2');
    });

    // ─── Empty / edge cases ───────────────────────────────────────────

    it('should handle empty diagram', 0, () => {
      let xml: string = wrapDrawioXml('');
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      expect(result.model.getNodeCount()).assertEqual(0);
      expect(result.model.getEdgeCount()).assertEqual(0);
    });

    it('should handle missing geometry defaults', 0, () => {
      let xml: string = wrapDrawioXml(
        '<mxCell id="n1" parent="1" vertex="1" style="rounded=1;"/>'
      );
      let result: DrawioParseResult = DrawioXmlParser.parse(xml);
      let n: GraphNode | null = result.model.getNode('n1');
      // Should not crash, defaults to 0 position, 120x60 size
      expect(n !== null ? n.width : -1).assertEqual(120);
      expect(n !== null ? n.height : -1).assertEqual(60);
    });
  });
}
