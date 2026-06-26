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
import { ShapeConfig, PerimeterKind } from '../adapter/ShapeConfig';
import { ShapeDefinition, ShapeRenderKind, TASK_PERIMETER, EVENT_PERIMETER, GATEWAY_PERIMETER } from '../adapter/ShapeDefinition';
import { PerimeterRouter } from '../adapter/PerimeterRouter';
import { NodeRect } from '../renderer/EdgeRenderer';

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

export class DrawioParseMeta {
  cellCount: number = 0;
  shapeTypes: Record<string, number> = {};
  unknownStyles: number = 0;
}

export class DrawioParseResult {
  model: GraphModel;
  pages: DiagramInfo[];
  warnings: string[];
  meta: DrawioParseMeta;

  constructor(model: GraphModel, pages: DiagramInfo[], warnings: string[],
              meta: DrawioParseMeta) {
    this.model = model;
    this.pages = pages;
    this.warnings = warnings;
    this.meta = meta;
  }
}

// ─── Internal State Classes ─────────────────────────────────────────────────────

class _ParseState {
  cells: _CellData[] = [];
  diagrams: _DiagramData[] = [];
  currentDiagram: _DiagramData = new _DiagramData('Page-1', 'd1');
  warnings: string[] = [];
  // DrawioParseMeta tracking
  metaCellCount: number = 0;
  metaShapeTypes: Record<string, number> = {};
  metaUnknownStyles: number = 0;
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

    // Ensure BPMN shapes are registered in the perimeter router registry
    DrawioXmlParser._initShapeRegistry();

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
      let model: GraphModel = DrawioXmlParser._buildModel(d, state);
      pages.push(new DiagramInfo(d.name, d.id, model));
    }

    // If no diagrams were parsed, create an empty default page
    if (pages.length === 0) {
      let empty: GraphModel = GraphModel.createEmpty();
      pages.push(new DiagramInfo('Page-1', 'd1', empty));
    }

    let meta: DrawioParseMeta = new DrawioParseMeta();
    meta.cellCount = state.metaCellCount;
    meta.shapeTypes = state.metaShapeTypes;
    meta.unknownStyles = state.metaUnknownStyles;
    return new DrawioParseResult(pages[0].model, pages, state.warnings, meta);
  }

  // ── Model building ──────────────────────────────────────────────────────────

  private static _buildModel(diagram: _DiagramData, state: _ParseState): GraphModel {
    let model: GraphModel = GraphModel.createEmpty();
    let nodeMap: Record<string, GraphNode> = {};

    // Pass 1: build all vertices first (edges may appear before their source/target in XML)
    for (let i: number = 0; i < diagram.cells.length; i++) {
      let cell: _CellData = diagram.cells[i];
      state.metaCellCount++;
      if (!cell.vertex) continue;

      let s: DrawioStyle = DrawioStyleParser.parse(cell.style);
      // Track shape type distribution
      if (s.shapeType === 'drawio.unknown') {
        state.metaUnknownStyles++;
      } else {
        let curr: number = state.metaShapeTypes[s.shapeType] || 0;
        state.metaShapeTypes[s.shapeType] = curr + 1;
      }
      let label: string = DrawioXmlParser.stripHtml(cell.value);

      let absX: number = cell.x;
      let absY: number = cell.y;
      if (cell.parent !== '1' && cell.parent !== '0') {
        let parentNode: GraphNode | undefined = nodeMap[cell.parent];
        if (parentNode !== undefined) {
          absX = parentNode.x + cell.x;
          absY = parentNode.y + cell.y;
        }
      }

      let props: Record<string, string> = {};
      let propKeys: string[] = Object.keys(s.properties);
      for (let k: number = 0; k < propKeys.length; k++) {
        let pk: string = propKeys[k];
        props[pk] = s.properties[pk];
      }

      let node: GraphNode = new GraphNode(
        cell.id, s.shapeType,
        absX, absY,
        cell.width > 0 ? cell.width : 120,
        cell.height > 0 ? cell.height : 60,
        label, props
      );
      model = model.addNode(node);
      nodeMap[cell.id] = node;
    }

    // Pass 2: build edges (all vertices now in nodeMap)
    for (let i: number = 0; i < diagram.cells.length; i++) {
      let cell: _CellData = diagram.cells[i];
      if (!cell.edge) continue;

      let s: DrawioStyle = DrawioStyleParser.parse(cell.style);
      let label: string = DrawioXmlParser.stripHtml(cell.value);

      let edgeStyle: EdgeStyle = EdgeStyle.STRAIGHT;
      if (s.properties['_curved'] === '1') {
        edgeStyle = EdgeStyle.CURVED;
      } else if (s.properties['_edgeStyle'] === 'orthogonalEdgeStyle' || cell.points.length > 0) {
        edgeStyle = EdgeStyle.POLYLINE;
      }

      let waypoints: Waypoint[] = [];
      for (let p: number = 0; p < cell.points.length; p++) {
        waypoints.push(new Waypoint(cell.points[p].x, cell.points[p].y));
      }

      // Edge waypoints are relative to edge's parent container. Adjust by parent
      // absolute position so they align with source/target node absolute coords.
      if (cell.parent !== '1' && cell.parent !== '0') {
        let edgeParent: GraphNode | undefined = nodeMap[cell.parent];
        if (edgeParent !== undefined) {
          for (let p: number = 0; p < waypoints.length; p++) {
            waypoints[p] = new Waypoint(
              waypoints[p].x + edgeParent.x,
              waypoints[p].y + edgeParent.y
            );
          }
        }
      }

      // If explicit waypoints exist, prepend source perimeter and append target
      // perimeter so the edge connects to shape borders (drawio waypoints are
      // intermediate routing points only).
      if (waypoints.length > 0 && cell.source.length > 0 && cell.target.length > 0) {
        let srcNode: GraphNode | undefined = nodeMap[cell.source];
        let tgtNode: GraphNode | undefined = nodeMap[cell.target];
        if (srcNode !== undefined && tgtNode !== undefined) {
          let wp0: Waypoint = waypoints[0];
          let wpN: Waypoint = waypoints[waypoints.length - 1];
          let srcP = DrawioXmlParser._perimeterPoint(srcNode, wp0.x, wp0.y);
          let tgtP = DrawioXmlParser._perimeterPoint(tgtNode, wpN.x, wpN.y);
          let full: Waypoint[] = [];
          full.push(new Waypoint(srcP.x, srcP.y));
          for (let p: number = 0; p < waypoints.length; p++) {
            full.push(waypoints[p]);
          }
          full.push(new Waypoint(tgtP.x, tgtP.y));
          waypoints = full;
        }
      }

      if (waypoints.length === 0 && cell.source.length > 0 && cell.target.length > 0) {
        let srcNode: GraphNode | undefined = nodeMap[cell.source];
        let tgtNode: GraphNode | undefined = nodeMap[cell.target];
        if (srcNode !== undefined && tgtNode !== undefined) {
          let srcCx: number = srcNode.x + srcNode.width / 2;
          let srcCy: number = srcNode.y + srcNode.height / 2;
          let tgtCx: number = tgtNode.x + tgtNode.width / 2;
          let tgtCy: number = tgtNode.y + tgtNode.height / 2;

          let srcP = DrawioXmlParser._perimeterPoint(srcNode, tgtCx, tgtCy);
          let tgtP = DrawioXmlParser._perimeterPoint(tgtNode, srcCx, srcCy);

          if (edgeStyle === EdgeStyle.POLYLINE &&
              s.properties['_edgeStyle'] === 'orthogonalEdgeStyle') {
            // Source: snap to cardinal side for clean right-angle exit
            let oSrc = DrawioXmlParser._cardinalPerimeter(srcNode, tgtCx, tgtCy);
            // Target: use exact perimeter point for accurate border connection
            let route: Waypoint[] = DrawioXmlParser._orthogonalRoute(oSrc, tgtP, srcNode, tgtNode);
            for (let r: number = 0; r < route.length; r++) {
              waypoints.push(route[r]);
            }
          } else {
            waypoints.push(new Waypoint(srcP.x, srcP.y));
            waypoints.push(new Waypoint(tgtP.x, tgtP.y));
          }
        }
      }

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

    return model;
  }

  // ── Perimeter / routing helpers ──────────────────────────────────────────

  /**
   * Compute the point on a node's perimeter in the direction toward (targetX, targetY).
   * Now delegates to PerimeterRouter for exact continuous-math intersection.
   */
  private static _perimeterPoint(node: GraphNode, targetX: number, targetY: number): _Point {
    let cx: number = node.x + node.width / 2;
    let cy: number = node.y + node.height / 2;
    let dx: number = targetX - cx;
    let dy: number = targetY - cy;

    if (dx === 0 && dy === 0) {
      return new _Point(cx, cy);
    }

    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition(node.type);
    let nodeRect: NodeRect = new NodeRect(node.x, node.y, node.width, node.height);
    let r = PerimeterRouter.intersect(shapeDef, nodeRect, targetX, targetY, cx, cy);
    if (r !== null) {
      return new _Point(r.x, r.y);
    }
    return new _Point(cx, cy);
  }

  /**
   * Compute a perimeter point snapped to a cardinal side (left/right/top/bottom),
   * based on which direction the target center lies from the node center.
   * Used for orthogonal routing to get clean right-angle exits.
   */
  private static _cardinalPerimeter(node: GraphNode, targetCx: number,
                                     targetCy: number): _Point {
    let cx: number = node.x + node.width / 2;
    let cy: number = node.y + node.height / 2;
    let dx: number = targetCx - cx;
    let dy: number = targetCy - cy;

    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition(node.type);
    let kind: PerimeterKind = shapeDef.perimeterKind;
    let hw: number = node.width / 2;
    let hh: number = node.height / 2;

    if (kind === PerimeterKind.RHOMBUS || kind === PerimeterKind.ELLIPSE) {
      if (Math.abs(dx) > Math.abs(dy)) {
        return new _Point(cx + (dx > 0 ? hw : -hw), cy);
      } else {
        return new _Point(cx, cy + (dy > 0 ? hh : -hh));
      }
    }

    // Rectangle: snap to nearest side center
    if (Math.abs(dx) > Math.abs(dy)) {
      // Exit left or right side, at the y-level of the target
      let sideX: number = dx > 0 ? node.x + node.width : node.x;
      let clampedY: number = cy + dy * Math.min(1, hh / Math.abs(dy));
      if (Math.abs(dy) < 0.01) clampedY = cy;
      // Clamp Y to stay on the side
      if (clampedY < node.y) clampedY = node.y;
      if (clampedY > node.y + node.height) clampedY = node.y + node.height;
      return new _Point(sideX, clampedY);
    } else {
      // Exit top or bottom side, at the x-level of the target
      let sideY: number = dy > 0 ? node.y + node.height : node.y;
      let clampedX: number = cx + dx * Math.min(1, hw / Math.abs(dx));
      if (Math.abs(dx) < 0.01) clampedX = cx;
      if (clampedX < node.x) clampedX = node.x;
      if (clampedX > node.x + node.width) clampedX = node.x + node.width;
      return new _Point(clampedX, sideY);
    }
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

    // Use midpoint between actual perimeter points (not center-distance offset),
    // so the last segment always points toward the target entry point.
    let midX: number = (src.x + tgt.x) / 2;
    let midY: number = (src.y + tgt.y) / 2;

    // Route along dominant axis first
    let srcCx: number = srcNode.x + srcNode.width / 2;
    let srcCy: number = srcNode.y + srcNode.height / 2;
    let tgtCx: number = tgtNode.x + tgtNode.width / 2;
    let tgtCy: number = tgtNode.y + tgtNode.height / 2;
    let dx: number = tgtCx - srcCx;
    let dy: number = tgtCy - srcCy;

    if (Math.abs(dx) > Math.abs(dy)) {
      result.push(new Waypoint(midX, src.y));
      result.push(new Waypoint(midX, tgt.y));
    } else {
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

  /**
   * One-time initialization: register BPMN shapes in the perimeter registry
   * so PerimeterRouter can compute accurate edge-perimeter intersections.
   */
  private static _initShapeRegistry(): void {
    if (ShapeConfig.shapeCount() > 0) {
      return; // already initialized
    }
    // Register all BPMN/drawio node types with their perimeter paths.
    // Keys match node.type values (parsed BPMN names and drawio.* prefixes).

    // RECT — tasks, subProcess, callActivity, data, annotation, swimlane, generic drawio
    let rectTypes: string[] = ['task', 'bpmn.task2', 'callActivity', 'subProcess',
      'dataObject', 'dataStore', 'textAnnotation',
      'drawio.rect', 'drawio.roundedRect', 'drawio.triangle',
      'drawio.parallelogram', 'drawio.text', 'drawio.swimlane', 'drawio.unknown'];
    for (let i: number = 0; i < rectTypes.length; i++) {
      ShapeConfig.registerShape(rectTypes[i], ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, TASK_PERIMETER, 0);
    }

    // ELLIPSE — BPMN events, drawio ellipse
    let ellipseTypes: string[] = ['startEvent', 'bpmn.event', 'endEvent', 'intermediateEvent',
      'boundaryEvent', 'drawio.ellipse'];
    for (let i: number = 0; i < ellipseTypes.length; i++) {
      ShapeConfig.registerShape(ellipseTypes[i], ShapeRenderKind.NATIVE_ELLIPSE,
        PerimeterKind.ELLIPSE, EVENT_PERIMETER);
    }

    // RHOMBUS — gateways
    let rhombusTypes: string[] = ['gateway', 'bpmn.gateway2', 'eventBasedGateway', 'complexGateway',
      'drawio.rhombus'];
    for (let i: number = 0; i < rhombusTypes.length; i++) {
      ShapeConfig.registerShape(rhombusTypes[i], ShapeRenderKind.NATIVE_RHOMBUS,
        PerimeterKind.RHOMBUS, GATEWAY_PERIMETER);
    }
  }
}
