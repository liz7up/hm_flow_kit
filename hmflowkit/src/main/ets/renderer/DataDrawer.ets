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
      // Database cylinder: standing body, bottom arc, top ellipse with inner arc
      let halfW: number = w / 2;
      let archH: number = Math.max(6 * zoom, h * 0.15);
      // Bottom arc
      ctx.beginPath();
      ctx.moveTo(x, y + h - archH);
      ctx.quadraticCurveTo(x + halfW, y + h + archH, x + w, y + h - archH);
      ctx.stroke();
      // Sides
      ctx.beginPath();
      ctx.moveTo(x, y + archH);
      ctx.lineTo(x, y + h - archH);
      ctx.moveTo(x + w, y + archH);
      ctx.lineTo(x + w, y + h - archH);
      ctx.stroke();
      // Top ellipse (full outline)
      ctx.beginPath();
      ctx.moveTo(x, y + archH);
      ctx.quadraticCurveTo(x + halfW, y - archH, x + w, y + archH);
      ctx.quadraticCurveTo(x + halfW, y + archH * 3, x, y + archH);
      ctx.stroke();
      // Inner bottom arc (visible inside of cylinder)
      ctx.beginPath();
      ctx.moveTo(x, y + archH);
      ctx.quadraticCurveTo(x + halfW, y + archH * 3, x + w, y + archH);
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
