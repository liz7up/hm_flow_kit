/**
 * DrawioXmlParser — mxGraph/drawio XML → GraphModel
 *
 * Uses @kit.ArkTS xml.XmlPullParser with the two-callback API
 * (attributeValueCallbackFunction + tokenValueCallbackFunction).
 *
 * Known timing issue (same as BpmnXmlParser):
 * attributeValueCallback fires BEFORE tokenValueCallback(START_TAG).
 * Therefore START_TAG only sets state markers; all business logic
 * finalizes on END_TAG.
 *
 * ignoreNameSpace: true does NOT strip namespace prefixes from getName().
 * Must use lastIndexOf(':') to extract local name manually.
 */

import { xml, util } from '@kit.ArkTS';
import { GraphModel, GraphNode, GraphEdge, Waypoint, EdgeStyle } from '../model/GraphModel';
import { DrawioStyleParser, DrawioStyle } from './DrawioStyleParser';

// ─── Public Types ───────────────────────────────────────────────────────────────

export class DiagramInfo {
  name: string;
  id: string;
  model: GraphModel;

  constructor(name: string, id: string, model: GraphModel) {
    this.name = name;
    this.id = id;
    this.model = model;
  }
}

export class DrawioParseResult {
  model: GraphModel;
  pages: DiagramInfo[];
  warnings: string[];

  constructor(model: GraphModel, pages: DiagramInfo[], warnings: string[]) {
    this.model = model;
    this.pages = pages;
    this.warnings = warnings;
  }
}

// ─── Internal State Classes ─────────────────────────────────────────────────────

class _ParseState {
  cells: _CellData[] = [];
  diagrams: _DiagramData[] = [];
  currentDiagram: _DiagramData = new _DiagramData('Page-1', 'd1');
  warnings: string[] = [];
  currentCell: _CellData = new _CellData();
  inCell: boolean = false;
  inGeometry: boolean = false;
  inArray: boolean = false;
  geometryPoints: Waypoint[] = [];
  pendingX: number = 0;
  pendingY: number = 0;
}

class _Point {
  x: number;
  y: number;
  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

class _DiagramData {
  name: string = '';
  id: string = '';
  cells: _CellData[] = [];

  constructor(name: string, id: string) {
    this.name = name;
    this.id = id;
  }
}

class _CellData {
  id: string = '';
  parent: string = '';
  vertex: boolean = false;
  edge: boolean = false;
  style: string = '';
  value: string = '';
  source: string = '';
  target: string = '';
  x: number = 0;
  y: number = 0;
  width: number = 120;
  height: number = 60;
  relative: boolean = false;
  points: Waypoint[] = [];
  sourcePoint: Waypoint | null = null;
  targetPoint: Waypoint | null = null;
}

// ─── DrawioXmlParser ────────────────────────────────────────────────────────────

export class DrawioXmlParser {
  /**
   * Parse a drawio/mxGraph XML string into a DrawioParseResult.
   * Supports multi-page diagrams (multiple <diagram> blocks).
   */
  static parse(xmlStr: string): DrawioParseResult {
    let state: _ParseState = new _ParseState();
    let cleaned: string = DrawioXmlParser.decodeXmlCharacterRefs(xmlStr);

    // Remove BOM if present
    if (cleaned.length > 0 && cleaned.charCodeAt(0) === 0xFEFF) {
      cleaned = cleaned.substring(1);
    }

    // ── Attribute callback ──
    // Captures attributes on the current element. Fire BEFORE tokenValueCallback(START_TAG).
    let attrCb: (name: string, value: string) => boolean;
    attrCb = (name: string, value: string): boolean => {
      let local: string = name;
      let colonIdx: number = name.lastIndexOf(':');
      if (colonIdx !== -1) {
        local = name.substring(colonIdx + 1);
      }

      // Collect cell attributes
      if (state.inCell && !state.inGeometry) {
        if (local === 'id') {
          state.currentCell.id = value;
        } else if (local === 'parent') {
          state.currentCell.parent = value;
        } else if (local === 'vertex') {
          state.currentCell.vertex = value === '1';
        } else if (local === 'edge') {
          state.currentCell.edge = value === '1';
        } else if (local === 'style') {
          state.currentCell.style = value;
        } else if (local === 'value') {
          state.currentCell.value = value;
        } else if (local === 'source') {
          state.currentCell.source = value;
        } else if (local === 'target') {
          state.currentCell.target = value;
        }
      } else if (state.inGeometry && !state.inArray) {
        // mxGeometry attributes
        if (local === 'x') {
          state.currentCell.x = parseInt(value) || 0;
        } else if (local === 'y') {
          state.currentCell.y = parseInt(value) || 0;
        } else if (local === 'width') {
          state.currentCell.width = parseInt(value) || 120;
        } else if (local === 'height') {
          state.currentCell.height = parseInt(value) || 60;
        } else if (local === 'relative') {
          state.currentCell.relative = value === '1';
        }
      } else if (state.inArray) {
        // mxPoint attributes within Array
        if (local === 'x') {
          state.pendingX = parseInt(value) || 0;
        } else if (local === 'y') {
          state.pendingY = parseInt(value) || 0;
        }
      }

      // Diagram-level attributes (name, id) — only when not inside a cell
      if (!state.inCell) {
        if (local === 'name') {
          state.currentDiagram.name = value;
        } else if (local === 'id') {
          state.currentDiagram.id = value;
        }
      }

      return true;
    };

    // ── Token callback ──
    // NOTE: attributeValueCallback fires BEFORE tokenValueCallback(START_TAG).
    // So START_TAG only sets state markers; all business logic is in END_TAG.
    let tokenCb: (eventType: xml.EventType, info: xml.ParseInfo) => boolean;
    tokenCb = (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
      let tag: string = info.getName();
      let colonIdx: number = tag.lastIndexOf(':');
      if (colonIdx !== -1) {
        tag = tag.substring(colonIdx + 1);
      }

      if (eventType === xml.EventType.START_TAG) {
        if (tag === 'diagram') {
          state.currentDiagram = new _DiagramData('', '');
          state.inCell = false;
        } else if (tag === 'mxCell') {
          state.currentCell = new _CellData();
          state.inCell = true;
        } else if (tag === 'mxGeometry') {
          state.inGeometry = true;
          state.geometryPoints = [];
        } else if (tag === 'Array') {
          state.inArray = true;
          state.geometryPoints = [];
        } else if (tag === 'mxPoint') {
          state.pendingX = 0;
          state.pendingY = 0;
        }
      }

      if (eventType === xml.EventType.END_TAG) {
        if (tag === 'mxCell') {
          state.inCell = false;
          state.currentDiagram.cells.push(state.currentCell);
          state.currentCell = new _CellData();
        } else if (tag === 'mxGeometry') {
          state.inGeometry = false;
        } else if (tag === 'Array') {
          state.inArray = false;
          state.currentCell.points = state.geometryPoints;
        } else if (tag === 'mxPoint') {
          if (state.inArray) {
            state.geometryPoints.push(new Waypoint(state.pendingX, state.pendingY));
          }
        } else if (tag === 'diagram') {
          state.diagrams.push(state.currentDiagram);
          state.currentDiagram = new _DiagramData('', '');
        }
      }

      return true;
    };

    // ── Create parser and parse ──
    try {
      let encoder: util.TextEncoder = new util.TextEncoder();
      let bytes: Uint8Array = encoder.encodeInto(cleaned);
      let parser: xml.XmlPullParser =
        new xml.XmlPullParser(bytes.buffer as object as ArrayBuffer, 'UTF-8');
      let options: xml.ParseOptions = {
        supportDoctype: false,
        ignoreNameSpace: true,
        attributeValueCallbackFunction: attrCb,
        tokenValueCallbackFunction: tokenCb
      };
      parser.parseXml(options);
    } catch (e) {
      state.warnings.push('XML parse error: ' + e);
    }

    // ── Build GraphModels from parsed diagram data ──
    let pages: DiagramInfo[] = [];
    for (let i: number = 0; i < state.diagrams.length; i++) {
      let d: _DiagramData = state.diagrams[i];
      let model: GraphModel = DrawioXmlParser._buildModel(d);
      pages.push(new DiagramInfo(d.name, d.id, model));
    }

    // If no diagrams were parsed, create an empty default page
    if (pages.length === 0) {
      let empty: GraphModel = GraphModel.createEmpty();
      pages.push(new DiagramInfo('Page-1', 'd1', empty));
    }

    return new DrawioParseResult(pages[0].model, pages, state.warnings);
  }

  // ── Model building ──────────────────────────────────────────────────────────

  private static _buildModel(diagram: _DiagramData): GraphModel {
    let model: GraphModel = GraphModel.createEmpty();
    let nodeMap: Record<string, GraphNode> = {};

    // Assumes mxCell order: vertices before edges. drawio tooling guarantees this.
    for (let i: number = 0; i < diagram.cells.length; i++) {
      let cell: _CellData = diagram.cells[i];

      if (cell.vertex) {
        // Parse style to get shape type and properties
        let s: DrawioStyle = DrawioStyleParser.parse(cell.style);
        let label: string = DrawioXmlParser.stripHtml(cell.value);

        // Resolve relative position: if relative AND parent is a real node (not root), offset
        let absX: number = cell.x;
        let absY: number = cell.y;
        if (cell.relative && cell.parent !== '1' && cell.parent !== '0') {
          let parentNode: GraphNode | undefined = nodeMap[cell.parent];
          if (parentNode !== undefined) {
            absX = parentNode.x + cell.x;
            absY = parentNode.y + cell.y;
          }
        }

        // Merge drawio style properties into node properties (with _ prefix)
        let props: Record<string, string> = {};
        let propKeys: string[] = Object.keys(s.properties);
        for (let k: number = 0; k < propKeys.length; k++) {
          let pk: string = propKeys[k];
          props[pk] = s.properties[pk];
        }

        let node: GraphNode = new GraphNode(
          cell.id,
          s.shapeType,
          absX,
          absY,
          cell.width > 0 ? cell.width : 120,
          cell.height > 0 ? cell.height : 60,
          label,
          props
        );
        model = model.addNode(node);
        nodeMap[cell.id] = node;

      } else if (cell.edge) {
        let s: DrawioStyle = DrawioStyleParser.parse(cell.style);
        let label: string = DrawioXmlParser.stripHtml(cell.value);

        // Determine edge style
        let edgeStyle: EdgeStyle = EdgeStyle.STRAIGHT;
        if (s.properties['_curved'] === '1') {
          edgeStyle = EdgeStyle.CURVED;
        } else if (s.properties['_edgeStyle'] === 'orthogonalEdgeStyle' || cell.points.length > 0) {
          edgeStyle = EdgeStyle.POLYLINE;
        }

        // Build waypoints from parsed Array points
        let waypoints: Waypoint[] = [];
        for (let p: number = 0; p < cell.points.length; p++) {
          waypoints.push(new Waypoint(cell.points[p].x, cell.points[p].y));
        }

        // If no explicit waypoints but source/target exist, compute perimeter-to-perimeter path
        if (waypoints.length === 0 && cell.source.length > 0 && cell.target.length > 0) {
          let srcNode: GraphNode | undefined = nodeMap[cell.source];
          let tgtNode: GraphNode | undefined = nodeMap[cell.target];
          if (srcNode !== undefined && tgtNode !== undefined) {
            try {
              let srcCx: number = srcNode.x + srcNode.width / 2;
              let srcCy: number = srcNode.y + srcNode.height / 2;
              let tgtCx: number = tgtNode.x + tgtNode.width / 2;
              let tgtCy: number = tgtNode.y + tgtNode.height / 2;

              if (edgeStyle === EdgeStyle.STRAIGHT || edgeStyle === EdgeStyle.CURVED) {
                let srcP = DrawioXmlParser._perimeterPoint(srcNode, tgtCx, tgtCy);
                let tgtP = DrawioXmlParser._perimeterPoint(tgtNode, srcCx, srcCy);
                waypoints.push(new Waypoint(srcP.x, srcP.y));
                waypoints.push(new Waypoint(tgtP.x, tgtP.y));
              } else {
                let isOrtho: boolean = s.properties['_edgeStyle'] === 'orthogonalEdgeStyle';
                let srcP = DrawioXmlParser._perimeterPoint(srcNode, tgtCx, tgtCy);
                let tgtP = DrawioXmlParser._perimeterPoint(tgtNode, srcCx, srcCy);
                if (isOrtho) {
                  let route: Waypoint[] = DrawioXmlParser._orthogonalRoute(srcP, tgtP, srcNode, tgtNode);
                  for (let r: number = 0; r < route.length; r++) {
                    waypoints.push(route[r]);
                  }
                } else {
                  waypoints.push(new Waypoint(srcP.x, srcP.y));
                  waypoints.push(new Waypoint(tgtP.x, tgtP.y));
                }
              }
            } catch (e) {
              // Fallback to center-to-center if perimeter computation fails
              let srcCx: number = srcNode.x + srcNode.width / 2;
              let srcCy: number = srcNode.y + srcNode.height / 2;
              let tgtCx: number = tgtNode.x + tgtNode.width / 2;
              let tgtCy: number = tgtNode.y + tgtNode.height / 2;
              waypoints.push(new Waypoint(srcCx, srcCy));
              waypoints.push(new Waypoint(tgtCx, tgtCy));
            }
          }
        }

        // Merge style properties into edge properties
        let edgeProps: Record<string, string> = {};
        let eKeys: string[] = Object.keys(s.properties);
        for (let k: number = 0; k < eKeys.length; k++) {
          let ek: string = eKeys[k];
          edgeProps[ek] = s.properties[ek];
        }

        let edge: GraphEdge = new GraphEdge(
          cell.id, cell.source, cell.target,
          waypoints, edgeStyle, label, edgeProps
        );
        model = model.addEdge(edge);
      }
    }

    return model;
  }

  // ── Perimeter / routing helpers ──────────────────────────────────────────

  /**
   * Compute the point on a node's perimeter in the direction toward (targetX, targetY).
   */
  private static _perimeterPoint(node: GraphNode, targetX: number, targetY: number): _Point {
    let cx: number = node.x + node.width / 2;
    let cy: number = node.y + node.height / 2;
    let dx: number = targetX - cx;
    let dy: number = targetY - cy;

    if (dx === 0 && dy === 0) {
      return new _Point(cx, cy);
    }

    if (node.type === 'drawio.ellipse') {
      return DrawioXmlParser._perimeterEllipse(cx, cy, node.width / 2, node.height / 2, dx, dy);
    } else if (node.type === 'drawio.rhombus') {
      return DrawioXmlParser._perimeterRhombus(cx, cy, node.width / 2, node.height / 2, dx, dy);
    } else {
      // Rectangle (default) — also used for triangle, parallelogram, swimlane, text
      return DrawioXmlParser._perimeterRect(cx, cy, node.width / 2, node.height / 2, dx, dy);
    }
  }

  private static _perimeterRect(cx: number, cy: number, hw: number, hh: number,
                                 dx: number, dy: number): _Point {
    if (dx === 0) {
      return new _Point(cx, cy + (dy > 0 ? hh : -hh));
    }
    if (dy === 0) {
      return new _Point(cx + (dx > 0 ? hw : -hw), cy);
    }
    let scaleX: number = hw / Math.abs(dx);
    let scaleY: number = hh / Math.abs(dy);
    let scale: number = scaleX < scaleY ? scaleX : scaleY;
    return new _Point(cx + dx * scale, cy + dy * scale);
  }

  private static _perimeterEllipse(cx: number, cy: number, rx: number, ry: number,
                                    dx: number, dy: number): _Point {
    let angle: number = Math.atan2(dy, dx);
    return new _Point(cx + rx * Math.cos(angle), cy + ry * Math.sin(angle));
  }

  private static _perimeterRhombus(cx: number, cy: number, hw: number, hh: number,
                                    dx: number, dy: number): _Point {
    // Diamond equation: |x-cx|/hw + |y-cy|/hh = 1
    // Ray from center: t = 1 / (|dx|/hw + |dy|/hh)
    if (dx === 0 && dy === 0) {
      return new _Point(cx, cy);
    }
    let t: number = 1 / (Math.abs(dx) / hw + Math.abs(dy) / hh);
    return new _Point(cx + dx * t, cy + dy * t);
  }

  /**
   * Build a simple orthogonal route from src point on source perimeter
   * to tgt point on target perimeter.
   * Strategy: route out the nearest side of each shape, through 1-3 segments.
   */
  private static _orthogonalRoute(src: _Point, tgt: _Point,
                                   srcNode: GraphNode, tgtNode: GraphNode): Waypoint[] {
    let result: Waypoint[] = [];
    result.push(new Waypoint(src.x, src.y));

    // Determine preferred routing axis based on relative position
    let srcCx: number = srcNode.x + srcNode.width / 2;
    let srcCy: number = srcNode.y + srcNode.height / 2;
    let tgtCx: number = tgtNode.x + tgtNode.width / 2;
    let tgtCy: number = tgtNode.y + tgtNode.height / 2;

    let dx: number = tgtCx - srcCx;
    let dy: number = tgtCy - srcCy;

    // 3-segment orthogonal: route along the dominant axis first, then cross
    // Use 60/40 split: first go 60% along dominant axis, then cross, then finish
    if (Math.abs(dx) > Math.abs(dy)) {
      // Horizontal dominant: exit right/left, then vertical, then enter
      let midX: number = src.x + dx * 0.5;
      result.push(new Waypoint(midX, src.y));
      result.push(new Waypoint(midX, tgt.y));
    } else {
      // Vertical dominant: exit top/bottom, then horizontal, then enter
      let midY: number = src.y + dy * 0.5;
      result.push(new Waypoint(src.x, midY));
      result.push(new Waypoint(tgt.x, midY));
    }

    result.push(new Waypoint(tgt.x, tgt.y));
    return result;
  }

  // ── HTML stripping ──────────────────────────────────────────────────────────

  /**
   * Strip HTML tags from drawio's HTML-formatted value strings.
   * Converts <br> to newlines, <p> separators to double newlines,
   * decodes common HTML entities, and removes all remaining tags.
   */
  static stripHtml(html: string): string {
    if (html.length === 0) {
      return '';
    }

    // Decode XML character references first (&#...;)
    let result: string = DrawioXmlParser.decodeXmlCharacterRefs(html);

    // Replace <br> variants with newline
    result = result.replace(/<br\s*\/?>/gi, '\n');

    // Replace </p><p> sequences with double newline
    result = result.replace(/<\/p>\s*<p[^>]*>/gi, '\n\n');

    // Replace <hr> with a separator
    result = result.replace(/<hr\s*\/?>/gi, '────────');

    // Strip all remaining HTML tags
    result = result.replace(/<[^>]+>/g, '');

    // Decode common HTML entities
    // &amp; must be decoded BEFORE lt/gt to handle double-encoded entities (&amp;lt;)
    result = result.replace(/&amp;/g, '&');
    result = result.replace(/&lt;/g, '<');
    result = result.replace(/&gt;/g, '>');
    result = result.replace(/&nbsp;/g, ' ');
    result = result.replace(/&quot;/g, '"');

    // Collapse 3+ consecutive newlines to 2
    result = result.replace(/\n{3,}/g, '\n\n');

    // Trim whitespace
    result = result.trim();

    return result;
  }

  /**
   * Decode XML/HTML hexadecimal and decimal character references.
   * Handles &#xHHHH; and &#DDDD; formats.
   */
  static decodeXmlCharacterRefs(xmlStr: string): string {
    let result: string = xmlStr;

    // Hex references: &#xHHHH;
    result = result.replace(/&#x([0-9a-fA-F]+);/g, (_match: string, hex: string): string => {
      let code: number = parseInt(hex, 16);
      return String.fromCharCode(code);
    });

    // Decimal references: &#DDDD;
    result = result.replace(/&#([0-9]+);/g, (_match: string, dec: string): string => {
      let code: number = parseInt(dec, 10);
      return String.fromCharCode(code);
    });

    return result;
  }
}
