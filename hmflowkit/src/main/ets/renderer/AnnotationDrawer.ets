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
    let bracketW: number = config.annotationBracketWidth * zoom;
    let fontSize: number = Math.max(config.fontSizeMin, Math.round(config.fontSize * zoom * config.annotationFontScale));

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

    // Multi-line text
    ctx.fillStyle = config.textColor;
    ctx.font = fontSize + 'px ' + config.fontFamily;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    let textX: number = x + bracketW + config.nodePadding / 2 * zoom;
    let textW: number = w - bracketW - config.nodePadding * zoom;

    let text: string = node.label;
    let lineY: number = y + config.nodePadding / 2 * zoom + fontSize / 2;
    while (text.length > 0 && lineY < y + h) {
      let line: string = text;
      let m: TextMetrics = ctx.measureText(text);
      if (m.width > textW && text.length > 1) {
        // Binary search for the right split point
        let lo: number = 1;
        let hi: number = text.length;
        while (lo < hi) {
          let mid: number = Math.floor((lo + hi) / 2);
          if (ctx.measureText(text.substring(0, mid)).width > textW) {
            hi = mid;
          } else {
            lo = mid + 1;
          }
        }
        line = text.substring(0, lo - 1);
        text = text.substring(lo - 1);
      } else {
        text = '';
      }
      ctx.fillText(line, textX, lineY);
      lineY += fontSize + config.nodePadding / 2 * zoom;
    }
  }
}
