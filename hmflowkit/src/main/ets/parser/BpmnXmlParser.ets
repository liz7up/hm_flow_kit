/**
 * BPMN 2.0 XML Parser — 基于 @kit.ArkTS xml.XmlPullParser
 *
 * 使用 parseXml() 回调 API，attributeValueCallback 收集属性，
 * tokenValueCallback 驱动状态机。不使用栈，用简单变量追踪状态。
 *
 * ignoreNameSpace: true 不影响 info.getName() 的返回值——
 * 仍需手动剥离命名空间前缀（lastIndexOf(':')）。
 */

import { xml, util } from '@kit.ArkTS';
import { GraphModel, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle } from '../model/GraphModel';

// ===== 公开类型 =====

export class ParseResult {
  model: GraphModel = GraphModel.createEmpty()
  warnings: string[] = []
  isPartial: boolean = false
}

// ===== 工具函数 =====

function defaultNodeSize(type: NodeType): { w: number, h: number } {
  switch (type) {
    case NodeType.GATEWAY:
      return { w: 50, h: 50 };
    case NodeType.START_EVENT:
    case NodeType.END_EVENT:
      return { w: 36, h: 36 };
    default:
      return { w: 120, h: 60 };
  }
}

function mapNodeType(tagName: string): NodeType {
  switch (tagName) {
    case 'startEvent': case 'intermediateThrowEvent':
    case 'intermediateCatchEvent': case 'boundaryEvent':
      return NodeType.START_EVENT;
    case 'endEvent':
      return NodeType.END_EVENT;
    case 'exclusiveGateway': case 'parallelGateway':
    case 'inclusiveGateway': case 'eventBasedGateway':
      return NodeType.GATEWAY;
    default:
      return NodeType.TASK;
  }
}

function isProcessElement(tagName: string): boolean {
  switch (tagName) {
    case 'startEvent': case 'endEvent':
    case 'userTask': case 'serviceTask': case 'manualTask':
    case 'sendTask': case 'receiveTask': case 'scriptTask':
    case 'businessRuleTask': case 'task':
    case 'callActivity': case 'subProcess':
    case 'intermediateThrowEvent': case 'intermediateCatchEvent':
    case 'boundaryEvent':
    case 'exclusiveGateway': case 'parallelGateway':
    case 'inclusiveGateway': case 'eventBasedGateway':
    case 'sequenceFlow':
      return true;
    default:
      return false;
  }
}

function localName(fullName: string): string {
  let colon: number = fullName.lastIndexOf(':');
  return colon !== -1 ? fullName.substring(colon + 1) : fullName;
}

// ===== 内部数据类 =====

class _NodeEntry {
  id: string = '';
  type: NodeType = NodeType.TASK;
  label: string = '';
  tagName: string = '';
  constructor() {}
}

class _EdgeEntry {
  id: string = '';
  src: string = '';
  tgt: string = '';
  label: string = '';
  constructor() {}
}

class _ShapeInfo {
  x: number = 0;
  y: number = 0;
  w: number = 0;
  h: number = 0;
  constructor() {}
}

// ===== 解析收集器 =====

class _Collector {
  private _nodes: _NodeEntry[] = [];
  private _edges: _EdgeEntry[] = [];
  private _shapes: Record<string, _ShapeInfo> = {};
  private _waypoints: Record<string, Waypoint[]> = {};
  warnings: string[] = [];

  addNode(id: string, type: NodeType, label: string, tagName: string): void {
    let e: _NodeEntry = new _NodeEntry();
    e.id = id;
    e.type = type;
    e.label = label;
    e.tagName = tagName;
    this._nodes.push(e);
  }

  addEdge(id: string, src: string, tgt: string, label: string): void {
    let e: _EdgeEntry = new _EdgeEntry();
    e.id = id;
    e.src = src;
    e.tgt = tgt;
    e.label = label;
    this._edges.push(e);
  }

  setShape(elementId: string, x: number, y: number, w: number, h: number): void {
    let s: _ShapeInfo = new _ShapeInfo();
    s.x = x;
    s.y = y;
    s.w = w;
    s.h = h;
    this._shapes[elementId] = s;
  }

  setWaypoints(edgeId: string, wps: Waypoint[]): void {
    this._waypoints[edgeId] = wps;
  }

  build(): GraphModel {
    let model: GraphModel = GraphModel.createEmpty();
    for (let i: number = 0; i < this._nodes.length; i++) {
      let nd: _NodeEntry = this._nodes[i];
      let shape: _ShapeInfo | undefined = this._shapes[nd.id];
      let x: number = 0;
      let y: number = 0;
      let sz: { w: number, h: number } = defaultNodeSize(nd.type);
      let w: number = sz.w;
      let h: number = sz.h;
      if (shape !== undefined) {
        x = shape.x;
        y = shape.y;
        w = shape.w;
        h = shape.h;
      }
      let props: Record<string, string> = {};
      if (nd.tagName.length > 0) {
        // key 'bpmnElement' 由 NodeRenderer 读取用于子类型配色，保持同步
        props['bpmnElement'] = nd.tagName;
      }
      model = model.addNode(
        new GraphNode(nd.id, nd.type, x, y, w, h, nd.label, props));
    }
    for (let i: number = 0; i < this._edges.length; i++) {
      let ed: _EdgeEntry = this._edges[i];
      let wps: Waypoint[] | undefined = this._waypoints[ed.id];
      if (wps === undefined) {
        wps = [];
        let sn: GraphNode | null = model.getNode(ed.src);
        let tn: GraphNode | null = model.getNode(ed.tgt);
        if (sn !== null && tn !== null) {
          wps.push(new Waypoint(sn.x + sn.width / 2, sn.y + sn.height / 2));
          wps.push(new Waypoint(tn.x + tn.width / 2, tn.y + tn.height / 2));
        }
      }
      model = model.addEdge(
        new GraphEdge(ed.id, ed.src, ed.tgt, wps, EdgeStyle.POLYLINE, ed.label, {}));
    }
    return model;
  }
}

// ===== BPMN 解析器 =====

export class BpmnXmlParser {
  // 严格模式：遇错即抛（保持向后兼容）
  static parse(xmlStr: string): GraphModel {
    let result: ParseResult = BpmnXmlParser._doParse(xmlStr);
    if (result.isPartial) {
      let msg: string = result.warnings.length > 0
        ? result.warnings[result.warnings.length - 1]
        : 'Unknown parse error';
      throw new Error('BPMN parse failed: ' + msg);
    }
    return result.model;
  }

  // 宽松模式：遇错返回部分结果 + 警告，不抛异常
  static parseBestEffort(xmlStr: string): ParseResult {
    return BpmnXmlParser._doParse(xmlStr);
  }

  private static _doParse(xmlStr: string): ParseResult {
    let result: ParseResult = new ParseResult();
    let cleaned: string = xmlStr;
    if (cleaned.length > 0 && cleaned.charCodeAt(0) === 0xFEFF) {
      cleaned = cleaned.substring(1);
    }

    let encoder: util.TextEncoder = new util.TextEncoder();
    let bytes: Uint8Array = encoder.encodeInto(cleaned);

    let collector: _Collector = new _Collector();

    // ── 状态变量 ──
    let currentAttrs: Record<string, string> = {};
    let inProcess: boolean = false;
    let inDiagram: boolean = false;
    let inShape: boolean = false;
    let inEdge: boolean = false;
    let inLabel: boolean = false;

    let shapeX: number = 0;
    let shapeY: number = 0;
    let shapeW: number = 0;
    let shapeH: number = 0;

    let waypointBuf: Waypoint[] = [];

    // ── attribute callback ──
    let attrCb: (name: string, value: string) => boolean;
    attrCb = (name: string, value: string): boolean => {
      currentAttrs[name] = value;
      return true;
    };

    // ── token callback ──
    let tokenCb: (eventType: xml.EventType, info: xml.ParseInfo) => boolean;
    tokenCb = (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
      let tag: string = localName(info.getName());

      if (eventType === xml.EventType.START_TAG) {
        if (tag === 'process') {
          inProcess = true;
        } else if (tag === 'BPMNDiagram') {
          inDiagram = true;
        } else if (tag === 'BPMNShape') {
          inShape = true;
          shapeX = 0; shapeY = 0; shapeW = 0; shapeH = 0;
        } else if (tag === 'BPMNEdge') {
          inEdge = true;
          waypointBuf = [];
        } else if (tag === 'BPMNLabel') {
          inLabel = true;
        }
        return true;
      }

      if (eventType === xml.EventType.END_TAG) {
        if (tag === 'Bounds' && inShape && !inLabel) {
          shapeX = Number(currentAttrs['x']) || 0;
          shapeY = Number(currentAttrs['y']) || 0;
          shapeW = Number(currentAttrs['width']) || 0;
          shapeH = Number(currentAttrs['height']) || 0;
        }
        else if (tag === 'waypoint' && inEdge) {
          waypointBuf.push(new Waypoint(
            Number(currentAttrs['x']) || 0,
            Number(currentAttrs['y']) || 0));
        }
        else if (tag === 'BPMNShape') {
          inShape = false;
          let elId: string = currentAttrs['bpmnElement'] || '';
          if (elId.length > 0) {
            collector.setShape(elId, shapeX, shapeY, shapeW, shapeH);
          }
        }
        else if (tag === 'BPMNEdge') {
          inEdge = false;
          let elId: string = currentAttrs['bpmnElement'] || '';
          if (elId.length > 0 && waypointBuf.length > 0) {
            collector.setWaypoints(elId, waypointBuf);
          }
        }
        else if (tag === 'BPMNLabel') {
          inLabel = false;
        }

        if (tag === 'process') {
          inProcess = false;
        } else if (tag === 'BPMNDiagram') {
          inDiagram = false;
        }

        if (inProcess && !inDiagram) {
          if (tag === 'sequenceFlow') {
            let fid: string = currentAttrs['id'] || '';
            let fsrc: string = currentAttrs['sourceRef'] || '';
            let ftgt: string = currentAttrs['targetRef'] || '';
            if (fid.length > 0 && fsrc.length > 0 && ftgt.length > 0) {
              collector.addEdge(fid, fsrc, ftgt,
                currentAttrs['name'] || '');
            }
          } else if (isProcessElement(tag)) {
            let nid: string = currentAttrs['id'] || '';
            if (nid.length > 0) {
              collector.addNode(nid, mapNodeType(tag),
                currentAttrs['name'] || '', tag);
            }
          }
        }
        return true;
      }

      return true;
    };

    try {
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
      result.isPartial = true;
      result.warnings.push('XML parse error: ' + e);
    }

    // 转发 Collector 中的警告
    for (let i: number = 0; i < collector.warnings.length; i++) {
      result.warnings.push(collector.warnings[i]);
    }
    result.model = collector.build();
    return result;
  }
}