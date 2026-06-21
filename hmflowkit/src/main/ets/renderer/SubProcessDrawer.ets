import { GraphNode } from '../model/GraphModel';
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

export class SubProcessDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    let r: number = Math.min(w, h) * config.cornerRadiusRatio * zoom;

    // Rounded rect path
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.arcTo(x + w, y, x + w, y + r, r);
    ctx.lineTo(x + w, y + h - r);
    ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
    ctx.lineTo(x + r, y + h);
    ctx.arcTo(x, y + h, x, y + h - r, r);
    ctx.lineTo(x, y + r);
    ctx.arcTo(x, y, x + r, y, r);
    ctx.closePath();

    ctx.fillStyle = config.taskFillColor;
    ctx.fill();
    ctx.strokeStyle = config.taskStrokeColor;
    let isTx: boolean = node.properties['bpmnElement'] === 'transaction';
    // Event subProcess → dashed; Transaction → double-line
    if (node.properties['triggeredByEvent'] === 'true') {
      ctx.lineWidth = config.strokeWidth * zoom;
      ctx.setLineDash([config.subProcessDashPattern[0] * zoom, config.subProcessDashPattern[1] * zoom]);
      ctx.stroke();
      ctx.setLineDash([]);
    } else if (isTx) {
      // Double border: outer + inner
      ctx.lineWidth = config.strokeWidth * zoom * 1.5;
      ctx.stroke();
      let inset: number = config.subProcessInset * zoom;
      ctx.beginPath();
      ctx.moveTo(x + r + inset, y + inset);
      ctx.lineTo(x + w - r - inset, y + inset);
      ctx.arcTo(x + w - inset, y + inset, x + w - inset, y + r + inset, r - inset);
      ctx.lineTo(x + w - inset, y + h - r - inset);
      ctx.arcTo(x + w - inset, y + h - inset, x + w - r - inset, y + h - inset, r - inset);
      ctx.lineTo(x + r + inset, y + h - inset);
      ctx.arcTo(x + inset, y + h - inset, x + inset, y + h - r - inset, r - inset);
      ctx.lineTo(x + inset, y + r + inset);
      ctx.arcTo(x + inset, y + inset, x + r + inset, y + inset, r - inset);
      ctx.closePath();
      ctx.lineWidth = config.strokeWidth * zoom;
      ctx.stroke();
    } else {
      ctx.lineWidth = config.strokeWidth * zoom;
      ctx.stroke();
    }

    // [+] expand marker — only collapsed <subProcess>, not <transaction>
    let isExpanded: boolean = node.properties['isExpanded'] !== 'false';
    if (!isTx && !isExpanded) {
      let markerSize: number = config.subProcessExpandMarkerSize * zoom;
      let mx: number = x + w / 2;
      let my: number = y + h + markerSize / 2;
      ctx.fillStyle = '#1890FF';
      ctx.fillRect(mx - markerSize / 2, my - markerSize / 2, markerSize, markerSize);
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1.5 * zoom;
      ctx.beginPath();
      ctx.moveTo(mx - markerSize * 0.35, my);
      ctx.lineTo(mx + markerSize * 0.35, my);
      ctx.moveTo(mx, my - markerSize * 0.35);
      ctx.lineTo(mx, my + markerSize * 0.35);
      ctx.stroke();
    }

    // Label — expanded: top-left, collapsed: center
    let text: string = sanitizeLabel(node.label);
    if (text.length > 0) {
      ctx.fillStyle = config.taskTextColor;
      ctx.font = Math.max(config.fontSizeMin, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
      if (isExpanded) {
        // expanded subProcess: label centered near top (avoids rounded corners + internal elements)
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(text, x + w / 2, y + 14 * zoom);
      } else {
        // collapsed subProcess: label centered
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(text, x + w / 2, y + h / 2);
      }
    }
  }
}
