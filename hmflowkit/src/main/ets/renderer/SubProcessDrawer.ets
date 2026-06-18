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
    let r: number = config.cornerRadius * zoom;

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
    ctx.lineWidth = config.strokeWidth * zoom;
    ctx.stroke();

    // [+] expand marker (bottom-center)
    let markerSize: number = 12 * zoom;
    let mx: number = x + w / 2;
    let my: number = y + h + markerSize / 2;
    ctx.strokeStyle = config.textColor;
    ctx.lineWidth = 1.5 * zoom;
    ctx.strokeRect(mx - markerSize / 2, my - markerSize / 2, markerSize, markerSize);
    ctx.beginPath();
    ctx.moveTo(mx - markerSize * 0.35, my);
    ctx.lineTo(mx + markerSize * 0.35, my);
    ctx.moveTo(mx, my - markerSize * 0.35);
    ctx.lineTo(mx, my + markerSize * 0.35);
    ctx.stroke();

    // Label
    let text: string = sanitizeLabel(node.label);
    if (text.length > 0) {
      ctx.fillStyle = config.taskTextColor;
      ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(text, x + w / 2, y + h / 2);
    }
  }
}
