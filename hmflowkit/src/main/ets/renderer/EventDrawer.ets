import { GraphNode, NodeType } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';

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

export class EventDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    let cx: number = x + w / 2;
    let cy: number = y + h / 2;
    let r: number = Math.min(w, h) / 2;

    // Determine event style
    let fill: string;
    let stroke: string;
    let lineW: number;
    let isDashed: boolean = false;

    if (node.type === NodeType.END_EVENT) {
      fill = config.eventEndFillColor;
      stroke = config.eventEndStrokeColor;
      lineW = config.eventEndStrokeWidth;
    } else {
      fill = config.eventStartFillColor;
      stroke = config.eventStartStrokeColor;
      lineW = config.eventStartStrokeWidth;
      // Non-interrupting boundary event: dashed border
      if (node.type === NodeType.BOUNDARY_EVENT) {
        let cancelActivity: string | undefined = node.properties['cancelActivity'];
        if (cancelActivity === 'false') {
          isDashed = true;
        }
      }
    }

    // Outer circle
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fillStyle = fill;
    ctx.fill();
    ctx.strokeStyle = stroke;
    ctx.lineWidth = lineW * zoom;
    if (isDashed) {
      ctx.setLineDash([4 * zoom, 3 * zoom]);
    }
    ctx.stroke();
    ctx.setLineDash([]);

    // Intermediate event: double ring (inner circle)
    if (node.type === NodeType.INTERMEDIATE_EVENT) {
      ctx.beginPath();
      ctx.arc(cx, cy, r * 0.82, 0, Math.PI * 2);
      ctx.lineWidth = 1.5 * zoom;
      ctx.stroke();
    }

    // Event definition icon
    let evDef: string | undefined = node.properties['eventDefinition'];
    if (evDef !== undefined && evDef.length > 0) {
      ctx.fillStyle = config.eventIconColor;
      ctx.strokeStyle = config.eventIconColor;
      ctx.lineWidth = Math.max(1.5, 2 * zoom);
      EventDrawer.drawEventIcon(ctx, evDef, cx, cy, r * 0.55);
    }

    // Label below circle (对标 bpmn.io)
    let text: string = sanitizeLabel(node.label);
    if (text.length > 0) {
      ctx.fillStyle = config.textColor;
      ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(text, cx, y + h / 2 + r + 4 * zoom);
    }
  }

  // ── 事件定义图标 ──

  private static drawEventIcon(
    ctx: CanvasRenderingContext2D, evDef: string,
    cx: number, cy: number, s: number
  ): void {
    switch (evDef) {
      case 'timerEventDefinition': {
        // Clock face
        ctx.beginPath(); ctx.arc(cx, cy, s * 0.8, 0, Math.PI * 2); ctx.stroke();
        // Hands
        ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx, cy - s * 0.5); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + s * 0.3, cy); ctx.stroke();
        break;
      }
      case 'messageEventDefinition': {
        // Envelope
        ctx.beginPath(); ctx.moveTo(cx - s, cy - s * 0.5);
        ctx.lineTo(cx + s, cy - s * 0.5);
        ctx.lineTo(cx + s, cy + s * 0.5);
        ctx.lineTo(cx - s, cy + s * 0.5);
        ctx.closePath(); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(cx - s, cy - s * 0.5);
        ctx.lineTo(cx, cy); ctx.lineTo(cx + s, cy - s * 0.5); ctx.stroke();
        break;
      }
      case 'errorEventDefinition': {
        // Lightning bolt
        ctx.beginPath(); ctx.moveTo(cx + s * 0.2, cy - s * 0.7);
        ctx.lineTo(cx - s * 0.4, cy - s * 0.1);
        ctx.lineTo(cx + s * 0.1, cy - s * 0.1);
        ctx.lineTo(cx - s * 0.2, cy + s * 0.7);
        ctx.lineTo(cx + s * 0.3, cy + s * 0.1);
        ctx.lineTo(cx - s * 0.1, cy + s * 0.1);
        ctx.closePath(); ctx.fill(); ctx.stroke();
        break;
      }
      case 'signalEventDefinition': {
        // Triangle
        ctx.beginPath(); ctx.moveTo(cx, cy - s * 0.7);
        ctx.lineTo(cx - s * 0.7, cy + s * 0.7);
        ctx.lineTo(cx + s * 0.7, cy + s * 0.7);
        ctx.closePath(); ctx.fill(); ctx.stroke();
        break;
      }
      case 'terminateEventDefinition': {
        // Filled black circle
        ctx.beginPath(); ctx.arc(cx, cy, s * 0.6, 0, Math.PI * 2);
        ctx.fill();
        break;
      }
      case 'cancelEventDefinition': {
        // X in circle — similar to exclusive gateway but smaller
        ctx.beginPath(); ctx.arc(cx, cy, s * 0.7, 0, Math.PI * 2); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(cx - s * 0.4, cy - s * 0.4);
        ctx.lineTo(cx + s * 0.4, cy + s * 0.4);
        ctx.moveTo(cx + s * 0.4, cy - s * 0.4);
        ctx.lineTo(cx - s * 0.4, cy + s * 0.4); ctx.stroke();
        break;
      }
      case 'compensateEventDefinition': {
        // Rewind / double left arrows
        ctx.beginPath(); ctx.moveTo(cx, cy - s * 0.5);
        ctx.lineTo(cx - s * 0.5, cy); ctx.lineTo(cx, cy + s * 0.5);
        ctx.moveTo(cx + s * 0.3, cy - s * 0.5);
        ctx.lineTo(cx - s * 0.2, cy); ctx.lineTo(cx + s * 0.3, cy + s * 0.5);
        ctx.stroke();
        break;
      }
      case 'escalationEventDefinition': {
        // Up arrow
        ctx.beginPath(); ctx.moveTo(cx, cy - s * 0.7);
        ctx.lineTo(cx - s * 0.5, cy); ctx.lineTo(cx - s * 0.15, cy);
        ctx.lineTo(cx - s * 0.15, cy + s * 0.5);
        ctx.lineTo(cx + s * 0.15, cy + s * 0.5);
        ctx.lineTo(cx + s * 0.15, cy);
        ctx.lineTo(cx + s * 0.5, cy);
        ctx.closePath(); ctx.fill(); ctx.stroke();
        break;
      }
      case 'conditionalEventDefinition': {
        // Rectangle with ruled lines (like a document/page)
        ctx.beginPath(); ctx.rect(cx - s * 0.6, cy - s * 0.7, s * 1.2, s * 1.4);
        ctx.stroke();
        for (let i: number = 0; i < 3; i++) {
          let ly: number = cy - s * 0.3 + i * s * 0.25;
          ctx.beginPath(); ctx.moveTo(cx - s * 0.4, ly);
          ctx.lineTo(cx + s * 0.4, ly); ctx.stroke();
        }
        break;
      }
      case 'linkEventDefinition': {
        // Two connected circles (like a chain link)
        ctx.beginPath(); ctx.arc(cx - s * 0.3, cy, s * 0.35, 0, Math.PI * 2); ctx.stroke();
        ctx.beginPath(); ctx.arc(cx + s * 0.3, cy, s * 0.35, 0, Math.PI * 2); ctx.stroke();
        break;
      }
      default: break;
    }
  }
}
