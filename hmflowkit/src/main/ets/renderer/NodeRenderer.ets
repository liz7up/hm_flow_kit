import { GraphNode, NodeType } from '../model/GraphModel';
import { RenderConfig, NodeShape } from './RenderConfig';

// 净化 label 中的非 ASCII 字符，替换为 ASCII 对应字符，确保 canvas 可渲染
function sanitizeLabel(text: string): string {
  if (text.length === 0) {
    return text;
  }
  let result: string = '';
  for (let i: number = 0; i < text.length; i++) {
    let code: number = text.charCodeAt(i);
    if (code === 0x201C || code === 0x201D || code === 0x201E || code === 0x201F) {
      result += '"';       // smart double quotes → "
    } else if (code === 0x2018 || code === 0x2019 || code === 0x201A || code === 0x201B) {
      result += "'";       // smart single quotes → '
    } else if (code === 0x2013 || code === 0x2014) {
      result += '-';       // en/em dash → -
    } else if (code >= 32 && code <= 126) {
      result += text.charAt(i);  // ASCII printable → keep
    }
    // else: skip (strip unrenderable chars)
  }
  return result;
}

export class NodeRenderer {
  public static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    const x: number = node.x * zoom + offsetX;
    const y: number = node.y * zoom + offsetY;
    const w: number = node.width * zoom;
    const h: number = node.height * zoom;

    ctx.save();
    ctx.beginPath();

    const shape: NodeShape = NodeRenderer.getShape(node.type);

    switch (shape) {
      case NodeShape.ROUNDED_RECT: {
        const r: number = config.cornerRadius * zoom;
        const left: number = x;
        const top: number = y;
        const right: number = x + w;
        const bottom: number = y + h;
        ctx.moveTo(left + r, top);
        ctx.lineTo(right - r, top);
        ctx.arcTo(right, top, right, top + r, r);
        ctx.lineTo(right, bottom - r);
        ctx.arcTo(right, bottom, right - r, bottom, r);
        ctx.lineTo(left + r, bottom);
        ctx.arcTo(left, bottom, left, bottom - r, r);
        ctx.lineTo(left, top + r);
        ctx.arcTo(left, top, left + r, top, r);
        break;
      }
      case NodeShape.DIAMOND: {
        const cx: number = x + w / 2;
        const cy: number = y + h / 2;
        ctx.moveTo(cx, y);
        ctx.lineTo(x + w, cy);
        ctx.lineTo(cx, y + h);
        ctx.lineTo(x, cy);
        ctx.closePath();
        break;
      }
      case NodeShape.CIRCLE: {
        const cx: number = x + w / 2;
        const cy: number = y + h / 2;
        const r: number = Math.min(w, h) / 2;
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        break;
      }
      case NodeShape.RECTANGLE:
      default: {
        ctx.rect(x, y, w, h);
        break;
      }
    }

    // 按节点类型选取颜色
    let fill: string;
    let stroke: string;
    let textColor: string;
    let lineW: number;
    if (node.type === NodeType.TASK) {
      fill = config.taskFillColor;
      textColor = config.taskTextColor;
      lineW = config.strokeWidth;
      let subtype: string | undefined = node.properties['bpmnElement'];
      stroke = config.taskStrokeColor;
      if (subtype !== undefined) {
        let c: string | undefined = config.taskSubtypeStroke[subtype];
        if (c !== undefined) {
          stroke = c;
        }
      }
    } else if (node.type === NodeType.GATEWAY) {
      fill = config.gatewayFillColor;
      stroke = config.gatewayStrokeColor;
      textColor = config.gatewayTextColor;
      lineW = config.strokeWidth;
    } else if (node.type === NodeType.START_EVENT) {
      fill = config.eventStartFillColor;
      stroke = config.eventStartStrokeColor;
      textColor = config.textColor;
      lineW = config.eventStartStrokeWidth;
    } else if (node.type === NodeType.END_EVENT) {
      fill = config.eventEndFillColor;
      stroke = config.eventEndStrokeColor;
      textColor = config.textColor;
      lineW = config.eventEndStrokeWidth;
    } else {
      fill = config.fillColor;
      stroke = config.strokeColor;
      textColor = config.textColor;
      lineW = config.strokeWidth;
    }

    ctx.fillStyle = fill;
    ctx.fill();
    ctx.strokeStyle = stroke;
    ctx.lineWidth = lineW * zoom;
    ctx.stroke();

    // 绘制网关内部标记
    if (node.type === NodeType.GATEWAY) {
      let gwTag: string | undefined = node.properties['bpmnElement'];
      if (gwTag !== undefined && gwTag.length > 0) {
        let cx: number = x + w / 2;
        let cy: number = y + h / 2;
        let s: number = Math.min(w, h) * 0.35 * zoom;
        ctx.fillStyle = config.gatewayMarkerColor;
        ctx.strokeStyle = config.gatewayMarkerColor;
        ctx.lineWidth = Math.max(1.5, 2 * zoom);
        NodeRenderer.drawGatewayMarker(ctx, gwTag, cx, cy, s);
      }
    }

    // 绘制事件定义图标
    if (node.type === NodeType.START_EVENT || node.type === NodeType.END_EVENT) {
      let evDef: string | undefined = node.properties['eventDefinition'];
      if (evDef !== undefined && evDef.length > 0) {
        let cx: number = x + w / 2;
        let cy: number = y + h / 2;
        let r: number = Math.min(w, h) / 2;
        ctx.fillStyle = config.eventIconColor;
        ctx.strokeStyle = config.eventIconColor;
        ctx.lineWidth = Math.max(1.5, 2 * zoom);
        NodeRenderer.drawEventIcon(ctx, evDef, cx, cy, r * 0.55);
      }
    }

    // 事件文字始终绘制在圆圈下方（对标 bpmn.io）
    if (node.type === NodeType.START_EVENT || node.type === NodeType.END_EVENT) {
      const text: string = sanitizeLabel(node.label);
      if (text.length > 0) {
        ctx.fillStyle = textColor;
        ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        let r: number = Math.min(w, h) / 2;
        ctx.fillText(text, x + w / 2, y + h / 2 + r + 4 * zoom);
      }
    } else {
      // 网关有内部标记时跳过居中文字，避免重叠
      let hasMarker: boolean = (node.type === NodeType.GATEWAY &&
        node.properties['bpmnElement'] !== undefined && node.properties['bpmnElement'].length > 0);
      if (!hasMarker) {
        const text: string = sanitizeLabel(node.label);
        ctx.fillStyle = textColor;
        ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(text, x + w / 2, y + h / 2);
      }
    }

    ctx.restore();
  }

  // ── 网关内部标记 ──

  private static drawGatewayMarker(
    ctx: CanvasRenderingContext2D,
    tagName: string,
    cx: number,
    cy: number,
    s: number
  ): void {
    ctx.beginPath();
    if (tagName === 'exclusiveGateway') {
      ctx.moveTo(cx - s, cy - s);
      ctx.lineTo(cx + s, cy + s);
      ctx.moveTo(cx + s, cy - s);
      ctx.lineTo(cx - s, cy + s);
    } else if (tagName === 'parallelGateway') {
      ctx.moveTo(cx - s, cy);
      ctx.lineTo(cx + s, cy);
      ctx.moveTo(cx, cy - s);
      ctx.lineTo(cx, cy + s);
    } else if (tagName === 'inclusiveGateway') {
      ctx.arc(cx, cy, s * 0.7, 0, Math.PI * 2);
    } else if (tagName === 'eventBasedGateway') {
      let pentR: number = s * 0.8;
      for (let i: number = 0; i < 5; i++) {
        let angle: number = (Math.PI / 2) + (i * 2 * Math.PI / 5);
        let px: number = cx + pentR * Math.cos(angle);
        let py: number = cy - pentR * Math.sin(angle);
        if (i === 0) { ctx.moveTo(px, py); }
        else { ctx.lineTo(px, py); }
      }
      ctx.closePath();
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(cx, cy, s * 0.35, 0, Math.PI * 2);
    }
    ctx.stroke();
  }

  // ── 事件定义图标 ──

  private static drawEventIcon(
    ctx: CanvasRenderingContext2D,
    eventDef: string,
    cx: number,
    cy: number,
    iconR: number
  ): void {
    ctx.beginPath();
    if (eventDef === 'timerEventDefinition') {
      ctx.arc(cx, cy, iconR, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx - iconR * 0.45, cy - iconR * 0.3);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + iconR * 0.55, cy - iconR * 0.2);
      ctx.stroke();
    } else if (eventDef === 'messageEventDefinition') {
      let hw: number = iconR * 1.1;
      let hh: number = iconR * 0.7;
      ctx.moveTo(cx - hw, cy - hh);
      ctx.lineTo(cx + hw, cy - hh);
      ctx.lineTo(cx + hw, cy + hh);
      ctx.lineTo(cx - hw, cy + hh);
      ctx.closePath();
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx - hw, cy - hh);
      ctx.lineTo(cx, cy);
      ctx.lineTo(cx + hw, cy - hh);
      ctx.stroke();
    } else if (eventDef === 'errorEventDefinition') {
      let hs: number = iconR;
      ctx.moveTo(cx + hs * 0.15, cy - hs);
      ctx.lineTo(cx - hs * 0.4, cy - hs * 0.1);
      ctx.lineTo(cx - hs * 0.15, cy);
      ctx.lineTo(cx - hs * 0.15, cy + hs);
      ctx.lineTo(cx + hs * 0.4, cy + hs * 0.1);
      ctx.lineTo(cx + hs * 0.15, cy);
      ctx.closePath();
      ctx.fill();
    } else if (eventDef === 'signalEventDefinition') {
      let ts: number = iconR * 1.1;
      ctx.moveTo(cx, cy - ts);
      ctx.lineTo(cx + ts * 0.85, cy + ts * 0.5);
      ctx.lineTo(cx - ts * 0.85, cy + ts * 0.5);
      ctx.closePath();
      ctx.fill();
    } else if (eventDef === 'terminateEventDefinition') {
      ctx.arc(cx, cy, iconR * 0.65, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  private static getShape(nodeType: NodeType): NodeShape {
    switch (nodeType) {
      case NodeType.START_EVENT:
      case NodeType.END_EVENT:
        return NodeShape.CIRCLE;
      case NodeType.GATEWAY:
        return NodeShape.DIAMOND;
      case NodeType.TASK:
      default:
        return NodeShape.ROUNDED_RECT;
    }
  }
}