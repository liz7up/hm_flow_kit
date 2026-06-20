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
import { GraphModel, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle, Pool, Lane, PoolBounds } from '../model/GraphModel';

// ===== 公开类型 =====

export class ParseResult {
  model: GraphModel = GraphModel.createEmpty()
  warnings: string[] = []
  isPartial: boolean = false
}

// ===== 内部辅助类 =====

class _NodeSize {
  w: number = 0;
  h: number = 0;
  constructor(w: number, h: number) {
    this.w = w;
    this.h = h;
  }
}

// ===== 工具函数 =====

function defaultNodeSize(type: NodeType): _NodeSize {
  switch (type) {
    case NodeType.GATEWAY:
    case NodeType.EVENT_BASED_GATEWAY:
    case NodeType.COMPLEX_GATEWAY:
      return new _NodeSize(50, 50);
    case NodeType.START_EVENT:
    case NodeType.END_EVENT:
    case NodeType.BOUNDARY_EVENT:
    case NodeType.INTERMEDIATE_EVENT:
      return new _NodeSize(36, 36);
    case NodeType.SUB_PROCESS:
      return new _NodeSize(200, 120);
    case NodeType.DATA_OBJECT:
      return new _NodeSize(36, 50);
    case NodeType.DATA_STORE:
      return new _NodeSize(50, 50);
    case NodeType.TEXT_ANNOTATION:
      return new _NodeSize(100, 30);
    case NodeType.CALL_ACTIVITY:
      return new _NodeSize(120, 60);
    default:
      return new _NodeSize(120, 60);
  }
}

function mapNodeType(tagName: string): NodeType {
  switch (tagName) {
    case 'startEvent':
      return NodeType.START_EVENT;
    case 'endEvent':
      return NodeType.END_EVENT;
    case 'boundaryEvent':
      return NodeType.BOUNDARY_EVENT;
    case 'intermediateThrowEvent':
    case 'intermediateCatchEvent':
      return NodeType.INTERMEDIATE_EVENT;
    case 'callActivity':
      return NodeType.CALL_ACTIVITY;
    case 'subProcess':
      return NodeType.SUB_PROCESS;
    case 'transaction':
      return NodeType.SUB_PROCESS;
    case 'eventBasedGateway':
      return NodeType.EVENT_BASED_GATEWAY;
    case 'complexGateway':
      return NodeType.COMPLEX_GATEWAY;
    case 'dataObject':
    case 'dataObjectReference':
      return NodeType.DATA_OBJECT;
    case 'dataStore':
    case 'dataStoreReference':
      return NodeType.DATA_STORE;
    case 'textAnnotation':
      return NodeType.TEXT_ANNOTATION;
    case 'exclusiveGateway': case 'parallelGateway':
    case 'inclusiveGateway':
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
    case 'callActivity': case 'subProcess': case 'transaction':
    case 'intermediateThrowEvent': case 'intermediateCatchEvent':
    case 'boundaryEvent':
    case 'exclusiveGateway': case 'parallelGateway':
    case 'inclusiveGateway': case 'eventBasedGateway':
    case 'complexGateway':
    case 'sequenceFlow': case 'association':
    case 'dataInputAssociation': case 'dataOutputAssociation':
    case 'dataObjectReference': case 'dataStoreReference':
    case 'textAnnotation':
      return true;
    default:
      return false;
  }
}

function localName(fullName: string): string {
  let colon: number = fullName.lastIndexOf(':');
  return colon !== -1 ? fullName.substring(colon + 1) : fullName;
}

// 解码 XML 数字字符引用（&#NNNN; / &#xHHHH;）
function decodeXmlCharacterRefs(raw: string): string {
  if (raw.length === 0 || raw.indexOf('&') === -1) {
    return raw;
  }
  let result: string = raw;
  // 十进制: &#8222;
  let idx: number = result.indexOf('&#');
  while (idx !== -1) {
    let semi: number = result.indexOf(';', idx);
    if (semi === -1) {
      break;
    }
    let refBody: string = result.substring(idx + 2, semi);
    let codePoint: number = -1;
    if (refBody.length > 0 && (refBody.charAt(0) === 'x' || refBody.charAt(0) === 'X')) {
      let hexStr: string = refBody.substring(1);
      if (hexStr.length > 0 && hexStr.length <= 6) {
        codePoint = parseInt(hexStr, 16);
      }
    } else if (refBody.length > 0 && refBody.length <= 7) {
      codePoint = parseInt(refBody, 10);
    }
    if (codePoint > 0 && codePoint <= 0x10FFFF) {
      let charStr: string = String.fromCharCode(codePoint);
      result = result.substring(0, idx) + charStr + result.substring(semi + 1);
      idx = result.indexOf('&#', idx + 1);
    } else {
      idx = result.indexOf('&#', idx + 1);
    }
  }
  return result;
}

// ===== 内部数据类 =====

class _NodeEntry {
  id: string = '';
  type: NodeType = NodeType.TASK;
  label: string = '';
  tagName: string = '';
  eventDefTag: string = '';
  cancelActivity: string = '';
  loopChar: string = '';
  triggeredByEvent: string = '';
  constructor() {}
}

class _EdgeEntry {
  id: string = '';
  src: string = '';
  tgt: string = '';
  label: string = '';
  bpmnElement: string = '';
  constructor() {}
}

class _ShapeInfo {
  x: number = 0;
  y: number = 0;
  w: number = 0;
  h: number = 0;
  constructor() {}
}

class _PoolShapeInfo {
  x: number = 0;
  y: number = 0;
  w: number = 0;
  h: number = 0;
  isHorizontal: boolean = true;
  constructor() {}
}

class _ParticipantDef {
  name: string = '';
  processRef: string = '';
  constructor() {}
}

class _LaneDefData {
  name: string = '';
  parentId: string = '';
  constructor() {}
}

class _DataAssocEntry {
  id: string = '';
  src: string = '';
  tgt: string = '';
  isAssoc: boolean = false;
  constructor() {}
}

// ===== 解析收集器 =====

class _Collector {
  private _nodes: _NodeEntry[] = [];
  private _edges: _EdgeEntry[] = [];
  private _shapes: Record<string, _ShapeInfo> = {};
  private _waypoints: Record<string, Waypoint[]> = {};

  // Pool/Lane 收集
  private _participants: Record<string, _ParticipantDef> = {};
  private _laneDefs: Record<string, _LaneDefData> = {};
  private _laneFlowRefs: Record<string, string[]> = {};
  private _poolShapes: Record<string, _PoolShapeInfo> = {};
  private _laneShapes: Record<string, _ShapeInfo> = {};
  private _participantIds: Record<string, boolean> = {};
  private _laneIds: Record<string, boolean> = {};
  private _messageFlowIds: Record<string, boolean> = {};

  warnings: string[] = [];

  addNode(id: string, type: NodeType, label: string, tagName: string, eventDefTag?: string,
          cancelActivity?: string, loopChar?: string, triggeredByEvent?: string): void {
    let e: _NodeEntry = new _NodeEntry();
    e.id = id;
    e.type = type;
    e.label = label;
    e.tagName = tagName;
    e.eventDefTag = eventDefTag !== undefined ? eventDefTag : '';
    e.cancelActivity = cancelActivity !== undefined ? cancelActivity : '';
    e.loopChar = loopChar !== undefined ? loopChar : '';
    e.triggeredByEvent = triggeredByEvent !== undefined ? triggeredByEvent : '';
    this._nodes.push(e);
  }

  addEdge(id: string, src: string, tgt: string, label: string, bpmnElement?: string): void {
    let e: _EdgeEntry = new _EdgeEntry();
    e.id = id;
    e.src = src;
    e.tgt = tgt;
    e.label = label;
    e.bpmnElement = bpmnElement !== undefined ? bpmnElement : '';
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

  // ── Pool/Lane 收集方法 ──

  addParticipant(id: string, name: string, processRef: string): void {
    let d: _ParticipantDef = new _ParticipantDef();
    d.name = name;
    d.processRef = processRef;
    this._participants[id] = d;
    this._participantIds[id] = true;
  }

  addLaneDef(id: string, name: string, parentId: string): void {
    let d: _LaneDefData = new _LaneDefData();
    d.name = name;
    d.parentId = parentId;
    this._laneDefs[id] = d;
    this._laneIds[id] = true;
    if (this._laneFlowRefs[id] === undefined) {
      this._laneFlowRefs[id] = [];
    }
  }

  addFlowNodeRef(laneId: string, nodeId: string): void {
    if (this._laneFlowRefs[laneId] === undefined) {
      this._laneFlowRefs[laneId] = [];
    }
    this._laneFlowRefs[laneId].push(nodeId);
  }

  setPoolShape(id: string, x: number, y: number, w: number, h: number, isHorizontal: boolean): void {
    let s: _PoolShapeInfo = new _PoolShapeInfo();
    s.x = x;
    s.y = y;
    s.w = w;
    s.h = h;
    s.isHorizontal = isHorizontal;
    this._poolShapes[id] = s;
  }

  setLaneShape(id: string, x: number, y: number, w: number, h: number): void {
    let s: _ShapeInfo = new _ShapeInfo();
    s.x = x;
    s.y = y;
    s.w = w;
    s.h = h;
    this._laneShapes[id] = s;
  }

  isParticipant(id: string): boolean {
    return this._participantIds[id] === true;
  }

  isLane(id: string): boolean {
    return this._laneIds[id] === true;
  }

  markAsMessageFlow(id: string): void {
    this._messageFlowIds[id] = true;
  }

  build(): GraphModel {
    let model: GraphModel = GraphModel.createEmpty();

    // 1. 构建节点
    for (let i: number = 0; i < this._nodes.length; i++) {
      let nd: _NodeEntry = this._nodes[i];
      let shape: _ShapeInfo | undefined = this._shapes[nd.id];
      let x: number = 0;
      let y: number = 0;
      let sz: _NodeSize = defaultNodeSize(nd.type);
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
        props['bpmnElement'] = nd.tagName;
      }
      if (nd.eventDefTag.length > 0) {
        props['eventDefinition'] = nd.eventDefTag;
      }
      if (nd.cancelActivity.length > 0) {
        props['cancelActivity'] = nd.cancelActivity;
      }
      if (nd.loopChar.length > 0) {
        props['loopCharacteristics'] = nd.loopChar;
      }
      if (nd.triggeredByEvent.length > 0) {
        props['triggeredByEvent'] = nd.triggeredByEvent;
      }
      model = model.addNode(
        new GraphNode(nd.id, nd.type, x, y, w, h, nd.label, props));
    }

    // 2. 构建边
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
      let props: Record<string, string> = {};
      if (this._messageFlowIds[ed.id] === true) {
        props['bpmnElement'] = 'messageFlow';
      } else if (ed.bpmnElement.length > 0) {
        props['bpmnElement'] = ed.bpmnElement;
      }
      model = model.addEdge(
        new GraphEdge(ed.id, ed.src, ed.tgt, wps, EdgeStyle.POLYLINE, ed.label, props));
    }

    // 3. 构建 Pools
    let poolIds: string[] = Object.keys(this._participants);
    for (let i: number = 0; i < poolIds.length; i++) {
      let pid: string = poolIds[i];
      let part: _ParticipantDef = this._participants[pid];
      let pShape: _PoolShapeInfo | undefined = this._poolShapes[pid];
      let x: number = 0;
      let y: number = 0;
      let w: number = 400;
      let h: number = 200;
      let isH: boolean = true;
      if (pShape !== undefined) {
        x = pShape.x;
        y = pShape.y;
        w = pShape.w;
        h = pShape.h;
        isH = pShape.isHorizontal;
      }

      // 构建该 Pool 的 Lane 树（只取顶层 Lane：parentId 为空的）
      let topLanes: Lane[] = this.buildLaneTree('');

      // 为 Lane 应用 shape 坐标
      topLanes = this.applyLaneShapes(topLanes);

      model = model.addPool(new Pool(
        pid, part.name, isH,
        new PoolBounds(x, y, w, h),
        topLanes
      ));
    }

    return model;
  }

  // ── Lane 树构建 ──

  private buildLaneTree(parentId: string): Lane[] {
    let result: Lane[] = [];
    let allLaneIds: string[] = Object.keys(this._laneDefs);
    for (let i: number = 0; i < allLaneIds.length; i++) {
      let lid: string = allLaneIds[i];
      let def: _LaneDefData = this._laneDefs[lid];
      if (def.parentId !== parentId) {
        continue;
      }
      let childLanes: Lane[] = this.buildLaneTree(lid);
      let refs: string[] = this._laneFlowRefs[lid] !== undefined
        ? this._laneFlowRefs[lid]
        : [];
      result.push(new Lane(
        lid, def.name,
        new PoolBounds(0, 0, 0, 0),
        childLanes,
        refs
      ));
    }
    return result;
  }

  private applyLaneShapes(lanes: Lane[]): Lane[] {
    let result: Lane[] = [];
    for (let i: number = 0; i < lanes.length; i++) {
      let lane: Lane = lanes[i];
      let shape: _ShapeInfo | undefined = this._laneShapes[lane.id];
      let b: PoolBounds = lane.bounds;
      if (shape !== undefined) {
        b = new PoolBounds(shape.x, shape.y, shape.w, shape.h);
      }
      let children: Lane[] = this.applyLaneShapes(lane.childLanes);
      result.push(new Lane(lane.id, lane.name, b, children, lane.flowNodeRefs));
    }
    return result;
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
    // 预处理 XML 数字字符引用（&#NNNN; / &#xHHHH;），
    // 避免 attributeValueCallback 因 & 字符而丢失值
    cleaned = decodeXmlCharacterRefs(cleaned);

    let encoder: util.TextEncoder = new util.TextEncoder();
    let bytes: Uint8Array = encoder.encodeInto(cleaned);

    let collector: _Collector = new _Collector();

    // ── 状态变量 ──
    let currentAttrs: Record<string, string> = {};
    let attrStack: Record<string, string>[] = [];
    let inProcess: boolean = false;
    let inDiagram: boolean = false;
    let inShape: boolean = false;
    let inEdge: boolean = false;
    let inLabel: boolean = false;

    // Pool/Lane 状态
    let inCollaboration: boolean = false;
    let inLaneSet: boolean = false;
    let inChildLaneSet: boolean = false;
    let inLane: boolean = false;
    let inFlowNodeRef: boolean = false;
    let flowNodeRefText: string = '';
    let currentLaneId: string = '';
    let currentEventDefTag: string = '';
    let currentLoopChar: string = '';
    let laneStack: string[] = [];
    let inTextAnnotation: boolean = false;
    let annotationText: string = '';
    let inDataAssoc: boolean = false;
    let inDataSrcRef: boolean = false;
    let inDataTgtRef: boolean = false;
    let dataAssocSrc: string = '';
    let dataAssocTgt: string = '';
    let dataAssocId: string = '';

    let shapeX: number = 0;
    let shapeY: number = 0;
    let shapeW: number = 0;
    let shapeH: number = 0;

    let waypointBuf: Waypoint[] = [];

    // ── pending data association edges (text captured after END_TAG) ──
    let pendingMap: Record<number, _DataAssocEntry> = {};
    let pendingSeq: number = 0;

    // ── tag value callback ──
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

      // TEXT event: capture text for textAnnotation + dataAssoc
      if (eventType === xml.EventType.TEXT) {
        let t: string = info.getText();
        let trimmed: string = t.trim();
        if (inTextAnnotation) {
          annotationText = annotationText + t;
        }
        if (pendingSeq > 0 && trimmed.length > 0) {
          if (inDataSrcRef) {
            if (pendingMap[pendingSeq] !== undefined && pendingMap[pendingSeq].src.length === 0) {
              pendingMap[pendingSeq].src = trimmed;
            }
          }
          if (inDataTgtRef) {
            if (pendingMap[pendingSeq] !== undefined && pendingMap[pendingSeq].tgt.length === 0) {
              pendingMap[pendingSeq].tgt = trimmed;
            }
          }
        }
      }

      if (eventType === xml.EventType.START_TAG) {
        // 保存当前 currentAttrs 到栈，重置供新元素使用
        // （不能用 = {}，因为闭包捕获了初始引用）
        let snapshot: Record<string, string> = {};
        let allKeys: string[] = Object.keys(currentAttrs);
        for (let ki: number = 0; ki < allKeys.length; ki++) {
          let k: string = allKeys[ki];
          snapshot[k] = currentAttrs[k];
          currentAttrs[k] = '';
        }
        attrStack.push(snapshot);

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
        // EventDefinition 子元素（只捕获标签名）
        else if (tag === 'timerEventDefinition' || tag === 'messageEventDefinition' ||
                 tag === 'errorEventDefinition' || tag === 'signalEventDefinition' ||
                 tag === 'terminateEventDefinition' || tag === 'cancelEventDefinition' ||
                 tag === 'compensateEventDefinition' || tag === 'escalationEventDefinition' ||
                 tag === 'conditionalEventDefinition' || tag === 'linkEventDefinition') {
          currentEventDefTag = tag;
        }
        // textAnnotation + data assoc text capture
        else if (tag === 'textAnnotation') {
          inTextAnnotation = true;
          annotationText = '';
        } else if (tag === 'dataInputAssociation' || tag === 'dataOutputAssociation') {
          // Allocate entry immediately so TEXT can fill src/tgt
          inDataAssoc = (tag === 'dataInputAssociation');
          dataAssocSrc = '';
          dataAssocTgt = '';
          dataAssocId = '';
          pendingSeq++;
          pendingMap[pendingSeq] = new _DataAssocEntry();
          pendingMap[pendingSeq].id = '';  // filled in END_TAG
          pendingMap[pendingSeq].isAssoc = inDataAssoc;
        } else if (tag === 'sourceRef') {
          inDataSrcRef = true;
        } else if (tag === 'targetRef') {
          inDataTgtRef = true;
        }
        else if (tag === 'multiInstanceLoopCharacteristics') {
          currentLoopChar = 'multiInstance';
        } else if (tag === 'standardLoopCharacteristics') {
          currentLoopChar = 'standard';
        }
        // Pool/Lane — START_TAG 仅设状态标记
        else if (tag === 'collaboration') {
          inCollaboration = true;
        } else if (tag === 'laneSet') {
          inLaneSet = true;
        } else if (tag === 'childLaneSet' && inLane) {
          inChildLaneSet = true;
          // 此时 currentAttrs 已有父 lane 属性（attrCb 在 tokenCb START_TAG 之后触发）
          let pid: string = currentAttrs['id'] || '';
          if (pid.length > 0) {
            laneStack.push(pid);
          }
        } else if (tag === 'lane' && inLaneSet) {
          inLane = true;
        } else if (tag === 'flowNodeRef' && inLane) {
          inFlowNodeRef = true;
          flowNodeRefText = '';
          // 当前 currentAttrs['id'] 是包含此 flowNodeRef 的 lane ID
          currentLaneId = currentAttrs['id'] || '';
        }
        return true;
      }

      if (eventType === xml.EventType.TEXT) {
        if (inFlowNodeRef) {
          let t: string = info.getText() || '';
          flowNodeRefText = flowNodeRefText + t;
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
            let isH: boolean = currentAttrs['isHorizontal'] !== 'false';
            if (collector.isParticipant(elId)) {
              collector.setPoolShape(elId, shapeX, shapeY, shapeW, shapeH, isH);
            } else if (collector.isLane(elId)) {
              collector.setLaneShape(elId, shapeX, shapeY, shapeW, shapeH);
            } else {
              collector.setShape(elId, shapeX, shapeY, shapeW, shapeH);
            }
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
        // Pool/Lane end tags — 业务逻辑全部在 END_TAG
        else if (tag === 'collaboration') {
          inCollaboration = false;
        } else if (tag === 'laneSet') {
          inLaneSet = false;
        } else if (tag === 'childLaneSet') {
          inChildLaneSet = false;
          if (laneStack.length > 0) {
            laneStack.pop();
          }
        } else if (tag === 'lane' && inLane) {
          inLane = false;
          let lid: string = currentAttrs['id'] || '';
          if (lid.length > 0) {
            let parentId: string = laneStack.length > 0
              ? laneStack[laneStack.length - 1]
              : '';
            collector.addLaneDef(lid, decodeXmlCharacterRefs(currentAttrs['name'] || ''), parentId);
          }
        } else if (tag === 'flowNodeRef' && inLane) {
          inFlowNodeRef = false;
          let nodeId: string = flowNodeRefText.trim();
          if (nodeId.length > 0 && currentLaneId.length > 0) {
            collector.addFlowNodeRef(currentLaneId, nodeId);
          }
        }

        if (tag === 'process') {
          inProcess = false;
        } else if (tag === 'BPMNDiagram') {
          inDiagram = false;
        }

        if (inCollaboration && !inDiagram) {
          if (tag === 'participant') {
            let pid: string = currentAttrs['id'] || '';
            let pname: string = decodeXmlCharacterRefs(currentAttrs['name'] || '');
            let pref: string = currentAttrs['processRef'] || '';
            if (pid.length > 0) {
              collector.addParticipant(pid, pname, pref);
            }
          } else if (tag === 'messageFlow') {
            let mid: string = currentAttrs['id'] || '';
            let msrc: string = currentAttrs['sourceRef'] || '';
            let mtgt: string = currentAttrs['targetRef'] || '';
            if (mid.length > 0 && msrc.length > 0 && mtgt.length > 0) {
              collector.addEdge(mid, msrc, mtgt, decodeXmlCharacterRefs(currentAttrs['name'] || ''));
              collector.markAsMessageFlow(mid);
            }
          }
        }

        if (inProcess && !inDiagram) {
          if (tag === 'sequenceFlow' || tag === 'association') {
            let fid: string = currentAttrs['id'] || '';
            let fsrc: string = currentAttrs['sourceRef'] || '';
            let ftgt: string = currentAttrs['targetRef'] || '';
            if (fid.length > 0 && fsrc.length > 0 && ftgt.length > 0) {
              let be: string = (tag === 'sequenceFlow') ? '' : tag;
              collector.addEdge(fid, fsrc, ftgt,
                decodeXmlCharacterRefs(currentAttrs['name'] || ''), be);
            }
          } else if (tag === 'dataInputAssociation' || tag === 'dataOutputAssociation') {
            // Fill real ID now that attrCb has fired
            let realId: string = currentAttrs['id'] || '';
            if (realId.length > 0 && pendingSeq > 0) {
              pendingMap[pendingSeq].id = realId;
            }
            inDataAssoc = false;
            dataAssocSrc = '';
            dataAssocTgt = '';
            dataAssocId = '';
          } else if (tag === 'sourceRef') {
            inDataSrcRef = false;
          } else if (tag === 'targetRef') {
            inDataTgtRef = false;
          } else if (isProcessElement(tag)) {
            if (tag === 'textAnnotation') {
              inTextAnnotation = false;
            }
            let nid: string = currentAttrs['id'] || '';
            if (nid.length > 0) {
              let nodeLabel: string = decodeXmlCharacterRefs(currentAttrs['name'] || '');
              if (tag === 'textAnnotation' && annotationText.length > 0) {
                nodeLabel = annotationText.trim();
              }
              collector.addNode(nid, mapNodeType(tag), nodeLabel, tag,
                currentEventDefTag.length > 0 ? currentEventDefTag : undefined,
                currentAttrs['cancelActivity'],
                currentLoopChar.length > 0 ? currentLoopChar : undefined,
                currentAttrs['triggeredByEvent']);
            }
            currentEventDefTag = '';
            currentLoopChar = '';
          }
        }
        // 弹出栈顶，恢复父级 currentAttrs
        if (attrStack.length > 0) {
          let prev: Record<string, string> = attrStack.pop()!;
          let pk: string[] = Object.keys(prev);
          for (let pi: number = 0; pi < pk.length; pi++) {
            currentAttrs[pk[pi]] = prev[pk[pi]];
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

    // 处理 pending dataAssoc edges (文本在 END_TAG 之后捕获)
    let daKeys: string[] = Object.keys(pendingMap);
    for (let i: number = 0; i < daKeys.length; i++) {
      let k: number = Number(daKeys[i]);
      let de: _DataAssocEntry = pendingMap[k];
      if (de.id.length > 0 && de.src.length > 0 && de.tgt.length > 0) {
        let edgeTag: string = de.isAssoc ? 'dataInputAssociation' : 'dataOutputAssociation';
        collector.addEdge(de.id, de.src, de.tgt, '', edgeTag);
      }
    }
    // 转发 Collector 中的警告
    for (let i: number = 0; i < collector.warnings.length; i++) {
      result.warnings.push(collector.warnings[i]);
    }
    result.model = collector.build();
    console.info('[parser] BUILD: nodes=' + result.model.getNodeCount() + ' edges=' + result.model.getEdgeCount());
    return result;
  }
}