/**
 * BPMN 2.0 XML 解析器
 *
 * 将 BPMN 2.0 XML 字符串解析为 GraphModel 实例。
 * 纯字符串解析实现，无第三方依赖。
 *
 * 支持的 BPMN 元素类型：
 *   - startEvent         → NodeType.START_EVENT
 *   - endEvent           → NodeType.END_EVENT
 *   - task               → NodeType.TASK
 *   - userTask           → NodeType.TASK
 *   - serviceTask        → NodeType.TASK
 *   - exclusiveGateway   → NodeType.GATEWAY
 *   - parallelGateway    → NodeType.GATEWAY
 *   - inclusiveGateway   → NodeType.GATEWAY
 *   - sequenceFlow       → GraphEdge
 *
 * DI 信息从 bpmndi:BPMNShape 和 bpmndi:BPMNEdge 中提取。
 * 缺失 DI 信息时使用默认值，不会崩溃。
 */

import { GraphModel } from '../model/GraphModel';
import { GraphNode } from '../model/GraphModel';
import { GraphEdge } from '../model/GraphModel';
import { Waypoint } from '../model/GraphModel';
import { Viewport } from '../model/GraphModel';
import { NodeType } from '../model/GraphModel';
import { EdgeStyle } from '../model/GraphModel';

/**
 * BPMN 解析错误
 */
export class BpmnParseError extends Error {
  constructor(message: string) {
    super(message);
  }
}

export class BpmnXmlParser {
  /**
   * 解析 BPMN 2.0 XML 字符串，返回 GraphModel 实例。
   *
   * @param xml - 完整的 BPMN 2.0 XML 字符串
   * @returns GraphModel 实例
   */
  private static _NODE_TYPES: string[][] = [
    ['startEvent', 'startEvent'],
    ['endEvent', 'endEvent'],
    ['task', 'task'],
    ['userTask', 'task'],
    ['serviceTask', 'task'],
    ['exclusiveGateway', 'gateway'],
    ['parallelGateway', 'gateway'],
    ['inclusiveGateway', 'gateway']
  ];

  public static parse(xml: string): GraphModel {
    // 提取 <definitions> 内容
    let defsContent: string = BpmnXmlParser._extractTagContent(xml, 'definitions');
    if (defsContent === '') {
      defsContent = xml;
    }

    // 提取 <process> 内容（必须存在）
    let processContent: string = BpmnXmlParser._extractTagContent(defsContent, 'process');
    if (processContent === '') {
      throw new BpmnParseError('未找到 <process> 元素');
    }

    // --- 1. 解析所有 BPMN 节点元素 ---
    let nodes: GraphNode[] = [];
    for (let t: number = 0; t < BpmnXmlParser._NODE_TYPES.length; t++) {
      let tagName: string = BpmnXmlParser._NODE_TYPES[t][0];
      let mappedType: string = BpmnXmlParser._NODE_TYPES[t][1];
      let tags: string[] = BpmnXmlParser._extractAllTags(processContent, tagName);
      for (let i: number = 0; i < tags.length; i++) {
        let node: GraphNode | null = BpmnXmlParser._parseBpmnElement(tags[i], mappedType);
        if (node !== null) {
          nodes.push(node);
        }
      }
    }

    // --- 2. 解析 sequenceFlow ---
    let edges: GraphEdge[] = [];
    let flowTags: string[] = BpmnXmlParser._extractAllTags(processContent, 'sequenceFlow');
    for (let i: number = 0; i < flowTags.length; i++) {
      let edge: GraphEdge | null = BpmnXmlParser._parseSequenceFlow(flowTags[i]);
      if (edge !== null) {
        edges.push(edge);
      }
    }

    // --- 3. 从 BPMNDiagram 提取 DI 信息 ---
    // 直接在 defsContent 中搜索，不单独提取 BPMNDiagram（嵌套命名空间提取容易失败）
    let shapes: string[] = BpmnXmlParser._extractAllTags(defsContent, 'BPMNShape');
    let shapeMap: Map<string, BpmnShapeData> = new Map();
    for (let i: number = 0; i < shapes.length; i++) {
      let sd: BpmnShapeData | null = BpmnXmlParser._parseBpmnShape(shapes[i]);
      if (sd !== null) {
        shapeMap.set(sd.bpmnElement, sd);
      }
    }

    // 将 DI 坐标应用到节点
    for (let i: number = 0; i < nodes.length; i++) {
      let sd: BpmnShapeData | undefined = shapeMap.get(nodes[i].id);
      if (sd !== undefined) {
        nodes[i].x = sd.x;
        nodes[i].y = sd.y;
        nodes[i].width = sd.width;
        nodes[i].height = sd.height;
      }
    }

    // BPMNEdge → waypoints
    let bpmnEdges: string[] = BpmnXmlParser._extractAllTags(defsContent, 'BPMNEdge');
    for (let i: number = 0; i < bpmnEdges.length; i++) {
      let ed: BpmnEdgeData | null = BpmnXmlParser._parseBpmnEdge(bpmnEdges[i]);
      if (ed !== null) {
        for (let j: number = 0; j < edges.length; j++) {
          if (edges[j].id === ed.bpmnElement) {
            edges[j].waypoints = ed.waypoints;
            break;
          }
        }
      }
    }

    // --- 4. 构造并返回 GraphModel ---
    return new GraphModel(nodes, edges, new Viewport(0, 0, 1));
  }

  /**
   * 从 XML 中提取指定标签的内容（不含外层标签）
   * 同时支持 <tagName> 和 <ns:tagName>
   */
  private static _extractTagContent(xml: string, tagName: string): string {
    // 尝试带命名空间前缀的匹配
    let patterns: string[] = [
      '<' + tagName + ' ',
      '<' + tagName + '>',
      '<' + tagName + '/'
    ];
    // 也尝试命名空间版（如 <bpmn:tagName）
    let nsPatterns: string[] = [
      ':' + tagName + ' ',
      ':' + tagName + '>',
      ':' + tagName + '/'
    ];

    let bestPos: number = -1;
    // 先试无命名空间
    for (let i: number = 0; i < patterns.length; i++) {
      let pos: number = xml.indexOf(patterns[i]);
      if (pos !== -1 && (bestPos === -1 || pos < bestPos)) {
        bestPos = pos;
      }
    }
    // 再试命名空间版本（需要向前找 '<'）
    for (let i: number = 0; i < nsPatterns.length; i++) {
      let pos: number = xml.indexOf(nsPatterns[i]);
      if (pos !== -1) {
        let ltPos: number = xml.lastIndexOf('<', pos);
        if (ltPos !== -1 && ltPos < pos) {
          if (bestPos === -1 || ltPos < bestPos) {
            bestPos = ltPos;
          }
        }
      }
    }

    if (bestPos === -1) {
      return '';
    }

    // 找到开放标签的 '>'
    let gtIdx: number = xml.indexOf('>', bestPos);
    if (gtIdx === -1) {
      return '';
    }
    // 检查自闭合
    if (gtIdx > 0 && xml[gtIdx - 1] === '/') {
      return '';
    }

    // 提取开放标签中的完整标签名（含前缀）
    let openTag: string = xml.substring(bestPos, gtIdx + 1);
    let nameEnd: number = openTag.indexOf(' ');
    if (nameEnd === -1) {
      nameEnd = openTag.indexOf('>');
    }
    let fullTagName: string = openTag.substring(1, nameEnd);

    // 找闭合标签：先试 </fullTagName>
    let endTag: string = '</' + fullTagName + '>';
    let endIdx: number = xml.indexOf(endTag, gtIdx + 1);
    if (endIdx !== -1) {
      return xml.substring(gtIdx + 1, endIdx);
    }

    // 再试无命名空间 </tagName>
    endTag = '</' + tagName + '>';
    endIdx = xml.indexOf(endTag, gtIdx + 1);
    if (endIdx !== -1) {
      return xml.substring(gtIdx + 1, endIdx);
    }

    return '';
  }

  /**
   * 提取所有指定标签的完整 XML 片段（含标签本身）
   * 同时支持 <tagName> 和 <ns:tagName>
   */
  private static _extractAllTags(xml: string, tagName: string): string[] {
    let result: string[] = []

    // 直接匹配 <tagName 或 <ns:tagName
    let searchPatterns: string[] = [
      '<' + tagName + ' ',
      '<' + tagName + '>',
      '<' + tagName + '/'
    ];

    let searchFrom: number = 0;

    while (searchFrom < xml.length) {
      // 查找匹配的开放标签
      let bestPos: number = -1;
      for (let p: number = 0; p < searchPatterns.length; p++) {
        let pos: number = xml.indexOf(searchPatterns[p], searchFrom);
        if (pos !== -1 && (bestPos === -1 || pos < bestPos)) {
          bestPos = pos;
        }
      }

      if (bestPos === -1) {
        // 尝试命名空间版本：查找 <prefix:tagName
        let nsPos: number = xml.indexOf(':' + tagName, searchFrom);
        if (nsPos === -1) {
          break;
        }
        // 向前搜索 '<' 找到真正的标签起始位置
        let tagStart: number = nsPos - 1;
        while (tagStart >= searchFrom && xml[tagStart] !== '<') {
          tagStart = tagStart - 1;
        }
        if (tagStart < searchFrom || xml[tagStart] !== '<') {
          searchFrom = nsPos + 1;
          continue;
        }
        bestPos = tagStart;
      }

      // 找到开放标签的 '>'
      let gtIdx: number = xml.indexOf('>', bestPos);
      if (gtIdx === -1) {
        break;
      }

      // 提取完整标签名
      let openTag: string = xml.substring(bestPos, gtIdx + 1);
      let nameEnd: number = openTag.indexOf(' ');
      if (nameEnd === -1) {
        nameEnd = openTag.indexOf('>');
      }
      let fullTagName: string = openTag.substring(1, nameEnd);

      // 自闭合检测
      if (gtIdx > 0 && xml[gtIdx - 1] === '/') {
        result.push(openTag);
        searchFrom = gtIdx + 1;
        continue;
      }

      // 非自闭合：找对应的闭合标签
      let closeTag: string = '</' + fullTagName + '>';
      let closeIdx: number = xml.indexOf(closeTag, gtIdx + 1);
      if (closeIdx === -1) {
        // 尝试无 namespace 闭合
        closeTag = '</' + tagName + '>';
        closeIdx = xml.indexOf(closeTag, gtIdx + 1);
        if (closeIdx === -1) {
          searchFrom = gtIdx + 1;
          continue;
        }
      }

      let tagContent: string = xml.substring(bestPos, closeIdx + closeTag.length);
      result.push(tagContent);
      searchFrom = closeIdx + closeTag.length;
    }

    return result
  }

  /**
   * 提取 BPMNDiagram 部分内容
   */
  private static _extractBpmnDiagram(xml: string): string {
    // 查找 <BPMNDiagram 或 <ns:BPMNDiagram
    let startIdx: number = xml.indexOf('<BPMNDiagram');
    if (startIdx === -1) {
      // 尝试命名空间版本：<prefix:BPMNDiagram
      let nsPos: number = xml.indexOf(':BPMNDiagram');
      if (nsPos !== -1) {
        let tagStart: number = nsPos - 1;
        while (tagStart >= 0 && xml[tagStart] !== '<') {
          tagStart = tagStart - 1;
        }
        if (tagStart >= 0 && xml[tagStart] === '<') {
          startIdx = tagStart;
        }
      }
    }
    if (startIdx === -1) {
      return '';
    }

    let endTag: string = '</BPMNDiagram>';
    let endIdx: number = xml.indexOf(endTag, startIdx);
    if (endIdx === -1) {
      // 尝试命名空间版本
      let nsEnd: string = ''
      let nsPos2: number = xml.indexOf(':', startIdx + 1)
      if (nsPos2 !== -1) {
        let prefix: string = xml.substring(startIdx + 1, nsPos2);
        nsEnd = '</' + prefix + ':BPMNDiagram>';
        endIdx = xml.indexOf(nsEnd, startIdx);
      }
      if (endIdx === -1) {
        return '';
      }
      return xml.substring(startIdx, endIdx + nsEnd.length);
    }

    return xml.substring(startIdx, endIdx + endTag.length);
  }

  /**
   * 解析 BPMN 元素（startEvent/endEvent/task/gateway 等）
   */
  private static _parseBpmnElement(tagXml: string, nodeType: string): GraphNode | null {
    let id: string = BpmnXmlParser._getAttribute(tagXml, 'id');
    if (id === '') {
      return null;
    }
    let name: string = BpmnXmlParser._getAttribute(tagXml, 'name');
    let graphNodeType: NodeType = BpmnXmlParser._mapNodeType(nodeType);
    let defaultW: number = 120;
    let defaultH: number = 60;
    if (graphNodeType === NodeType.START_EVENT || graphNodeType === NodeType.END_EVENT) {
      defaultW = 36;
      defaultH = 36;
    } else if (graphNodeType === NodeType.GATEWAY) {
      defaultW = 50;
      defaultH = 50;
    }
    return new GraphNode(id, graphNodeType, 0, 0, defaultW, defaultH, name, {});
  }

  /**
   * 将 BPMN 标签名映射到 GraphNodeType 字符串
   */
  private static _mapNodeType(bpmnType: string): NodeType {
    if (bpmnType === 'startEvent') {
      return NodeType.START_EVENT;
    }
    if (bpmnType === 'endEvent') {
      return NodeType.END_EVENT;
    }
    if (bpmnType === 'gateway') {
      return NodeType.GATEWAY;
    }
    return NodeType.TASK;
  }

  private static _parseSequenceFlow(tagXml: string): GraphEdge | null {
    let id: string = BpmnXmlParser._getAttribute(tagXml, 'id');
    if (id === '') {
      return null;
    }
    let sourceRef: string = BpmnXmlParser._getAttribute(tagXml, 'sourceRef');
    let targetRef: string = BpmnXmlParser._getAttribute(tagXml, 'targetRef');
    if (sourceRef === '' || targetRef === '') {
      return null;
    }
    let name: string = BpmnXmlParser._getAttribute(tagXml, 'name');
    return new GraphEdge(id, sourceRef, targetRef, [], EdgeStyle.POLYLINE, name, {});
  }

  /**
   * 解析 BPMNShape 元素
   */
  private static _parseBpmnShape(shapeXml: string): BpmnShapeData | null {
    let bpmnElement: string = BpmnXmlParser._getAttribute(shapeXml, 'bpmnElement')
    if (bpmnElement === '') {
      return null
    }

    // dc:Bounds 是自闭合标签，不能从内容提取，直接从标签字符串取属性
    let x: number = 0
    let y: number = 0
    let w: number = 120
    let h: number = 60
    let boundsTag: string = BpmnXmlParser._extractSelfClosingTag(shapeXml, 'dc:Bounds')
    if (boundsTag === '') {
      boundsTag = BpmnXmlParser._extractSelfClosingTag(shapeXml, 'Bounds')
    }
    if (boundsTag !== '') {
      let xStr: string = BpmnXmlParser._getAttribute(boundsTag, 'x')
      let yStr: string = BpmnXmlParser._getAttribute(boundsTag, 'y')
      let wStr: string = BpmnXmlParser._getAttribute(boundsTag, 'width')
      let hStr: string = BpmnXmlParser._getAttribute(boundsTag, 'height')
      if (xStr !== '') { x = parseFloat(xStr) }
      if (yStr !== '') { y = parseFloat(yStr) }
      if (wStr !== '') { w = parseFloat(wStr) }
      if (hStr !== '') { h = parseFloat(hStr) }
    }

    let data: BpmnShapeData = {
      bpmnElement: bpmnElement,
      x: x, y: y, width: w, height: h
    }
    return data
  }

  /**
   * 提取自闭合标签（如 <dc:Bounds x="1" y="2"/>）
   */
  private static _extractSelfClosingTag(xml: string, tagName: string): string {
    let pos: number = xml.indexOf('<' + tagName + ' ')
    if (pos === -1) {
      pos = xml.indexOf('<' + tagName + '/>')
    }
    if (pos === -1) {
      // 命名空间版
      let sp: number = xml.indexOf(':' + tagName + ' ')
      if (sp === -1) {
        sp = xml.indexOf(':' + tagName + '/>')
      }
      if (sp !== -1) {
        // 向前找 '<'
        let lt: number = sp - 1
        while (lt >= 0 && xml[lt] !== '<') { lt = lt - 1 }
        if (lt >= 0 && xml[lt] === '<') { pos = lt }
      }
    }
    if (pos === -1) { return '' }
    let end: number = xml.indexOf('/>', pos)
    if (end === -1) { return '' }
    return xml.substring(pos, end + 2)
  }

  /**
   * 解析 BPMNEdge 元素
   */
  private static _parseBpmnEdge(edgeXml: string): BpmnEdgeData | null {
    let bpmnElement: string = BpmnXmlParser._getAttribute(edgeXml, 'bpmnElement')
    if (bpmnElement === '') {
      return null
    }

    let waypoints: Waypoint[] = []

    // 提取 di:waypoint
    let waypointXmls: string[] = BpmnXmlParser._extractAllTags(edgeXml, 'di:waypoint')
    if (waypointXmls.length === 0) {
      // 尝试无命名空间版本
      waypointXmls = BpmnXmlParser._extractAllTags(edgeXml, 'waypoint')
    }

    for (let i: number = 0; i < waypointXmls.length; i++) {
      let wpXml: string = waypointXmls[i]
      let xStr: string = BpmnXmlParser._getAttribute(wpXml, 'x')
      let yStr: string = BpmnXmlParser._getAttribute(wpXml, 'y')

      if (xStr !== '' && yStr !== '') {
        let wx: number = parseFloat(xStr)
        let wy: number = parseFloat(yStr)
        let wp: Waypoint = new Waypoint(wx, wy)
        waypoints.push(wp)
      }
    }

    let data: BpmnEdgeData = {
      bpmnElement: bpmnElement,
      waypoints: waypoints
    }

    return data
  }

  /**
   * 从 XML 标签中提取指定属性的值
   */
  private static _getAttribute(xml: string, attrName: string): string {
    let searchStr: string = attrName + '="'
    let startIdx: number = xml.indexOf(searchStr)
    if (startIdx === -1) {
      // 尝试单引号
      searchStr = attrName + "='"
      startIdx = xml.indexOf(searchStr)
      if (startIdx === -1) {
        return ''
      }
    }

    let valueStart: number = startIdx + searchStr.length
    let quoteChar: string = xml.substring(valueStart - 1, valueStart)
    let endIdx: number = xml.indexOf(quoteChar, valueStart)
    if (endIdx === -1) {
      return ''
    }

    return xml.substring(valueStart, endIdx)
  }

}

interface BpmnShapeData {
  bpmnElement: string
  x: number
  y: number
  width: number
  height: number
}

interface BpmnEdgeData {
  bpmnElement: string
  waypoints: Waypoint[]
}