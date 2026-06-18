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

export class TaskDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    // Rounded rect path
    let r: number = config.cornerRadius * zoom;
    let left: number = x;
    let top: number = y;
    let right: number = x + w;
    let bottom: number = y + h;
    ctx.beginPath();
    ctx.moveTo(left + r, top);
    ctx.lineTo(right - r, top);
    ctx.arcTo(right, top, right, top + r, r);
    ctx.lineTo(right, bottom - r);
    ctx.arcTo(right, bottom, right - r, bottom, r);
    ctx.lineTo(left + r, bottom);
    ctx.arcTo(left, bottom, left, bottom - r, r);
    ctx.lineTo(left, top + r);
    ctx.arcTo(left, top, left + r, top, r);

    // Color selection by subtype
    let subtype: string | undefined = node.properties['bpmnElement'];
    let fill: string = config.taskFillColor;
    let stroke: string = config.taskStrokeColor;
    let textColor: string = config.taskTextColor;
    let lineW: number = config.strokeWidth;

    if (subtype !== undefined) {
      let c: string | undefined = config.taskSubtypeStroke[subtype];
      if (c !== undefined) {
        stroke = c;
      }
    }

    // callActivity thick border
    if (node.type === NodeType.CALL_ACTIVITY) {
      lineW = config.strokeWidth * 2.5;
    }

    ctx.fillStyle = fill;
    ctx.fill();
    ctx.strokeStyle = stroke;
    ctx.lineWidth = lineW * zoom;
    ctx.stroke();

    // loopCharacteristics marker
    let loopChar: string | undefined = node.properties['loopCharacteristics'];
    if (loopChar !== undefined && loopChar.length > 0) {
      TaskDrawer.drawLoopMarker(ctx, loopChar, config, x, y, w, h, zoom);
    }

    // businessRuleTask icon
    if (subtype === 'businessRuleTask') {
      TaskDrawer.drawRuleTaskIcon(ctx, x, y, w, h, config, zoom);
    }

    // Label
    let text: string = sanitizeLabel(node.label);
    if (text.length > 0) {
      ctx.fillStyle = textColor;
      ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(text, x + w / 2, y + h / 2);
    }
  }

  private static drawLoopMarker(
    ctx: CanvasRenderingContext2D,
    loopChar: string,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    let cx: number = x + w / 2;
    let by: number = y + h + 2 * zoom;
    ctx.fillStyle = config.textColor;
    ctx.strokeStyle = config.textColor;
    ctx.lineWidth = 1.5 * zoom;
    ctx.font = Math.max(10, Math.round(10 * zoom)) + 'px ' + config.fontFamily;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    if (loopChar === 'multiInstance') {
      ctx.fillText('|||', cx, by);
    } else if (loopChar === 'standard') {
      ctx.fillText('\u21BB', cx, by);
    }
  }

  private static drawRuleTaskIcon(
    ctx: CanvasRenderingContext2D,
    x: number, y: number, w: number, h: number,
    config: RenderConfig, zoom: number
  ): void {
    let ix: number = x + 6 * zoom;
    let iy: number = y + 6 * zoom;
    let iw: number = 16 * zoom;
    let ih: number = 12 * zoom;
    ctx.strokeStyle = config.taskTextColor;
    ctx.lineWidth = 1.5 * zoom;
    ctx.strokeRect(ix, iy, iw, ih);
    ctx.beginPath();
    ctx.moveTo(ix, iy + ih * 0.4);
    ctx.lineTo(ix + iw, iy + ih * 0.4);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(ix + iw * 0.5, iy + ih * 0.4);
    ctx.lineTo(ix + iw * 0.5, iy + ih);
    ctx.stroke();
  }
}
