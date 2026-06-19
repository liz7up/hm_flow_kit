import { GraphNode, NodeType } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';

function sanitizeLabel(text: string): string {
  if (text.length === 0) {
    return text;
  }
  let result: string = '';
  for (let i: number = 0; i < text.length; i++) {
    let code: number = text.charCodeAt(i);
    if (code === 0x201C || code === 0x201D || code === 0x201E || code === 0x201F) {
      result += '"';
    } else if (code === 0x2018 || code === 0x2019 || code === 0x201A || code === 0x201B) {
      result += "'";
    } else if (code === 0x2013 || code === 0x2014) {
      result += '-';
    } else if (code >= 32 && code <= 126) {
      result += text.charAt(i);
    }
  }
  return result;
}

export class DataDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    ctx.strokeStyle = config.strokeColor;
    ctx.fillStyle = config.fillColor;
    ctx.lineWidth = config.strokeWidth * zoom;

    if (node.type === NodeType.DATA_OBJECT) {
      // Document shape: rectangle with folded top-right corner
      let fold: number = 12 * zoom;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + w - fold, y);
      ctx.lineTo(x + w, y + fold);
      ctx.lineTo(x + w, y + h);
      ctx.lineTo(x, y + h);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Fold crease lines
      ctx.beginPath();
      ctx.moveTo(x + w - fold, y);
      ctx.lineTo(x + w - fold, y + fold);
      ctx.lineTo(x + w, y + fold);
      ctx.stroke();
    } else if (node.type === NodeType.DATA_STORE) {
      // Database cylinder — use ellipse() for smooth rendering
      let cx: number = x + w / 2;
      let jw: number = w * 0.75;          // jar body width
      let eh: number = jw * 0.2;          // ellipse height
      let bodyTop: number = y + h * 0.1 + eh;
      let bodyBot: number = y + h - eh;
      let lidH: number = h * 0.12;        // lid ring height
      let lidW: number = jw + 10 * zoom;  // lid slightly wider
      let lidTop: number = y + h * 0.05;  // lid top position
      let lidBot: number = bodyTop;       // lid sits on top of body

      let hw: number = jw / 2;
      let lw: number = lidW / 2;
      let heh: number = eh / 2;

      ctx.lineWidth = config.strokeWidth * zoom;
      ctx.strokeStyle = config.strokeColor;

      // 1. Body top ellipse (jar mouth)
      ctx.beginPath();
      ctx.ellipse(cx, bodyTop, hw, heh, 0, 0, Math.PI * 2);
      ctx.stroke();

      // 2. Body side lines
      ctx.beginPath();
      ctx.moveTo(cx - hw, bodyTop);
      ctx.lineTo(cx - hw, bodyBot);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx + hw, bodyTop);
      ctx.lineTo(cx + hw, bodyBot);
      ctx.stroke();

      // 3. Body bottom arc (lower half only, for perspective)
      ctx.beginPath();
      ctx.ellipse(cx, bodyBot, hw, heh, 0, 0, Math.PI);
      ctx.stroke();

      // 4. Lid top ellipse (slightly wider than jar)
      let lheh: number = (eh + 4 * zoom) / 2;
      ctx.beginPath();
      ctx.ellipse(cx, lidTop, lw, lheh, 0, 0, Math.PI * 2);
      ctx.stroke();

      // 5. Lid side lines
      ctx.beginPath();
      ctx.moveTo(cx - lw, lidTop);
      ctx.lineTo(cx - lw, lidBot);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx + lw, lidTop);
      ctx.lineTo(cx + lw, lidBot);
      ctx.stroke();

      // 6. Lid bottom arc (upper half, connects to jar mouth)
      ctx.beginPath();
      ctx.ellipse(cx, lidBot, lw, lheh, 0, Math.PI, Math.PI * 2);
      ctx.stroke();
    }

    // Label
    let text: string = sanitizeLabel(node.label);
    if (text.length > 0) {
      ctx.fillStyle = config.textColor;
      ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(text, x + w / 2, y + h / 2);
    }
  }
}
