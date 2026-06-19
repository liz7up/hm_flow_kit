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
    let bracketW: number = 8 * zoom;
    let fontSize: number = Math.max(12, Math.round(config.fontSize * zoom)) * 2;

    // BPMN textAnnotation: bracket "[" on left, opens right
    // Vertical stem at x, with top+mid+bottom arms extending right
    ctx.beginPath();
    ctx.strokeStyle = config.textColor;
    ctx.lineWidth = 1.5 * zoom;
    // Top arm
    ctx.moveTo(x, y);
    ctx.lineTo(x + bracketW, y);
    // Stem (top to bottom)
    ctx.moveTo(x, y);
    ctx.lineTo(x, y + h);
    // Bottom arm
    ctx.moveTo(x, y + h);
    ctx.lineTo(x + bracketW, y + h);
    ctx.stroke();

    // Multi-line text, right-indented from bracket
    ctx.fillStyle = config.textColor;
    ctx.font = fontSize + 'px ' + config.fontFamily;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';
    let textX: number = x + bracketW + 3 * zoom;
    let textW: number = w - bracketW - 6 * zoom;
    let maxChars: number = Math.floor(textW / (fontSize * 0.55));

    let text: string = node.label;
    let lineY: number = y + 2 * zoom;
    while (text.length > 0 && lineY < y + h) {
      let line: string = text;
      if (text.length > maxChars) {
        line = text.substring(0, maxChars);
        text = text.substring(maxChars);
      } else {
        text = '';
      }
      ctx.fillText(line, textX, lineY);
      lineY += fontSize + 2 * zoom;
    }
  }
}
