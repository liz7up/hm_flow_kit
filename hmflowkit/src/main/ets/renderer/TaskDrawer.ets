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

    // Task subtype icon (top-left)
    if (subtype !== undefined && subtype.length > 0) {
      let iconColor: string = stroke !== config.taskStrokeColor ? stroke : config.taskTextColor;
      TaskDrawer.drawSubtypeIcon(ctx, subtype, x, y, w, h, iconColor, zoom);
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

  private static drawSubtypeIcon(
    ctx: CanvasRenderingContext2D,
    subtype: string,
    x: number, y: number, _w: number, _h: number,
    iconColor: string, zoom: number
  ): void {
    let ix: number = x + 4 * zoom;
    let iy: number = y + 4 * zoom;
    let s: number = 12 * zoom;
    ctx.strokeStyle = iconColor;
    ctx.fillStyle = iconColor;
    ctx.lineWidth = 1.5 * zoom;

    if (subtype === 'userTask') {
      // Person icon: circle head + body lines
      ctx.beginPath();
      ctx.arc(ix + s / 2, iy + s * 0.3, s * 0.22, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(ix + s * 0.15, iy + s * 0.85);
      ctx.lineTo(ix + s / 2, iy + s * 0.5);
      ctx.lineTo(ix + s * 0.85, iy + s * 0.85);
      ctx.stroke();
    } else if (subtype === 'sendTask') {
      // Filled envelope (dark)
      ctx.fillRect(ix, iy + s * 0.15, s, s * 0.7);
      ctx.beginPath();
      ctx.moveTo(ix, iy + s * 0.15);
      ctx.lineTo(ix + s / 2, iy + s * 0.55);
      ctx.lineTo(ix + s, iy + s * 0.15);
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1 * zoom;
      ctx.stroke();
      ctx.strokeStyle = iconColor;
      ctx.lineWidth = 1.5 * zoom;
    } else if (subtype === 'receiveTask') {
      // Empty envelope
      ctx.strokeRect(ix, iy + s * 0.15, s, s * 0.7);
      ctx.beginPath();
      ctx.moveTo(ix, iy + s * 0.15);
      ctx.lineTo(ix + s / 2, iy + s * 0.55);
      ctx.lineTo(ix + s, iy + s * 0.15);
      ctx.stroke();
    } else if (subtype === 'serviceTask') {
      // Gear icon: circle + notches
      ctx.beginPath();
      ctx.arc(ix + s / 2, iy + s / 2, s * 0.35, 0, Math.PI * 2);
      ctx.stroke();
      let gearR: number = s * 0.45;
      for (let i: number = 0; i < 6; i++) {
        let a: number = (i * Math.PI) / 3;
        let gx: number = ix + s / 2 + gearR * Math.cos(a);
        let gy: number = iy + s / 2 + gearR * Math.sin(a);
        ctx.fillRect(gx - s * 0.08, gy - s * 0.08, s * 0.16, s * 0.16);
      }
    } else if (subtype === 'scriptTask') {
      // Script/code icon: angled brackets
      ctx.font = Math.max(10, Math.round(10 * zoom)) + 'px monospace';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('</>', ix + s / 2, iy + s / 2);
      ctx.textAlign = 'start';
    } else if (subtype === 'manualTask') {
      // Hand icon: palm + fingers
      ctx.fillRect(ix + s * 0.3, iy + s * 0.2, s * 0.4, s * 0.6);
      ctx.beginPath();
      ctx.moveTo(ix + s * 0.15, iy + s * 0.25);
      ctx.lineTo(ix + s * 0.15, iy + s * 0.85);
      ctx.moveTo(ix + s / 2, iy + s * 0.1);
      ctx.lineTo(ix + s / 2, iy + s * 0.85);
      ctx.moveTo(ix + s * 0.85, iy + s * 0.25);
      ctx.lineTo(ix + s * 0.85, iy + s * 0.85);
      ctx.stroke();
    } else if (subtype === 'businessRuleTask') {
      // Table/grid icon
      ctx.strokeRect(ix, iy, s, s * 0.75);
      ctx.beginPath();
      ctx.moveTo(ix, iy + s * 0.3);
      ctx.lineTo(ix + s, iy + s * 0.3);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(ix + s * 0.5, iy + s * 0.3);
      ctx.lineTo(ix + s * 0.5, iy + s * 0.75);
      ctx.stroke();
    }
  }
}
