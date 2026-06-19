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
    let bracketW: number = 6 * zoom;
    // BPMN textAnnotation: left-side bracket "[" opening right
    // Vertical stem + two short horizontal arms extending right
    ctx.beginPath();
    // top arm
    ctx.moveTo(x, y);
    ctx.lineTo(x + bracketW, y);
    // vertical stem (top to bottom)
    ctx.lineTo(x + bracketW, y + h);
    // bottom arm
    ctx.lineTo(x, y + h);
    ctx.strokeStyle = config.textColor;
    ctx.lineWidth = 1 * zoom;
    ctx.stroke();

    // Multi-line text
    let fontSize: number = Math.max(12, Math.round(config.fontSize * zoom));
    ctx.fillStyle = config.textColor;
    ctx.font = fontSize + 'px ' + config.fontFamily;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';
    let textX: number = x + bracketW + 3 * zoom;

    let maxCharsPerLine: number = Math.floor((w - bracketW - 3 * zoom) / (fontSize * 0.6));
    let text: string = node.label;
    let lineY: number = y + 2 * zoom;
    while (text.length > 0 && lineY < y + h) {
      let line: string = text;
      if (text.length > maxCharsPerLine) {
        line = text.substring(0, maxCharsPerLine);
        text = text.substring(maxCharsPerLine);
      } else {
        text = '';
      }
      ctx.fillText(line, textX, lineY);
      lineY += fontSize + 2 * zoom;
    }
  }
}
