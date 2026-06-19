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
      // Database cylinder — integrated body + decorative arcs + top ellipse
      let cx: number = x + w / 2;
      let rx: number = w * 0.43;
      let ry: number = rx * 0.31;
      let height: number = h - ry * 2;
      let topY: number = y + ry;
      let step: number = ry * 0.72;

      ctx.lineWidth = config.strokeWidth * zoom;
      ctx.strokeStyle = config.strokeColor;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';

      // 1. Body outline: left side + bottom arc (left→right) + right side
      ctx.beginPath();
      ctx.moveTo(cx - rx, topY);
      ctx.lineTo(cx - rx, topY + height);
      ctx.ellipse(cx, topY + height, rx, ry, 0, 0, Math.PI, false);
      ctx.lineTo(cx + rx, topY);
      ctx.stroke();

      // 2. Two decorative horizontal arcs inside the cylinder
      ctx.beginPath();
      ctx.ellipse(cx, topY + step, rx, ry, 0, 0, Math.PI, false);
      ctx.stroke();
      ctx.beginPath();
      ctx.ellipse(cx, topY + step * 2, rx, ry, 0, 0, Math.PI, false);
      ctx.stroke();

      // 3. Top ellipse (drawn last, on top of everything)
      ctx.beginPath();
      ctx.ellipse(cx, topY, rx, ry, 0, 0, Math.PI * 2, false);
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
