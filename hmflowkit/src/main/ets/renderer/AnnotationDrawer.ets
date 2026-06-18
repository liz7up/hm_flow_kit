import { GraphNode } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';

export class AnnotationDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    // Open-left text annotation: three sides of a rectangle (no right border)
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x, y + h);
    ctx.lineTo(x + w, y + h);
    ctx.lineTo(x + w, y);
    ctx.strokeStyle = config.textColor;
    ctx.lineWidth = 1 * zoom;
    ctx.stroke();
    // Small bracket on left
    ctx.beginPath();
    ctx.moveTo(x, y + h);
    ctx.lineTo(x - 6 * zoom, y + h);
    ctx.stroke();

    // Multi-line text word wrap
    let fontSize: number = Math.max(12, Math.round(config.fontSize * zoom));
    ctx.fillStyle = config.textColor;
    ctx.font = fontSize + 'px ' + config.fontFamily;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';

    let maxCharsPerLine: number = Math.floor(w / (fontSize * 0.6));
    let text: string = node.label;
    let lineY: number = y + 4 * zoom;
    while (text.length > 0 && lineY < y + h) {
      let line: string = text;
      if (text.length > maxCharsPerLine) {
        line = text.substring(0, maxCharsPerLine);
        text = text.substring(maxCharsPerLine);
      } else {
        text = '';
      }
      ctx.fillText(line, x + 4 * zoom, lineY);
      lineY += fontSize + 2 * zoom;
    }
  }
}
