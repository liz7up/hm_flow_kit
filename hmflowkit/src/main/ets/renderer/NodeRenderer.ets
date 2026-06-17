import { GraphNode, NodeType } from '../model/GraphModel';
import { RenderConfig, NodeShape } from './RenderConfig';

export class NodeRenderer {
  public static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    const x: number = node.x * zoom + offsetX;
    const y: number = node.y * zoom + offsetY;
    const w: number = node.width * zoom;
    const h: number = node.height * zoom;

    ctx.save();
    ctx.beginPath();

    const shape: NodeShape = NodeRenderer.getShape(node.type);

    switch (shape) {
      case NodeShape.ROUNDED_RECT: {
        const r: number = config.cornerRadius * zoom;
        const left: number = x;
        const top: number = y;
        const right: number = x + w;
        const bottom: number = y + h;
        ctx.moveTo(left + r, top);
        ctx.lineTo(right - r, top);
        ctx.arcTo(right, top, right, top + r, r);
        ctx.lineTo(right, bottom - r);
        ctx.arcTo(right, bottom, right - r, bottom, r);
        ctx.lineTo(left + r, bottom);
        ctx.arcTo(left, bottom, left, bottom - r, r);
        ctx.lineTo(left, top + r);
        ctx.arcTo(left, top, left + r, top, r);
        break;
      }
      case NodeShape.DIAMOND: {
        const cx: number = x + w / 2;
        const cy: number = y + h / 2;
        ctx.moveTo(cx, y);
        ctx.lineTo(x + w, cy);
        ctx.lineTo(cx, y + h);
        ctx.lineTo(x, cy);
        ctx.closePath();
        break;
      }
      case NodeShape.CIRCLE: {
        const cx: number = x + w / 2;
        const cy: number = y + h / 2;
        const r: number = Math.min(w, h) / 2;
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        break;
      }
      case NodeShape.RECTANGLE:
      default: {
        ctx.rect(x, y, w, h);
        break;
      }
    }

    // 按节点类型选取颜色
    let fill: string;
    let stroke: string;
    let textColor: string;
    let lineW: number;
    if (node.type === NodeType.TASK) {
      fill = config.taskFillColor;
      textColor = config.taskTextColor;
      lineW = config.strokeWidth;
      // 查子类型边框色
      let subtype: string | undefined = node.properties['bpmnElement'];
      stroke = config.taskStrokeColor;
      if (subtype !== undefined) {
        let c: string | undefined = config.taskSubtypeStroke[subtype];
        if (c !== undefined) {
          stroke = c;
        }
      }
    } else if (node.type === NodeType.GATEWAY) {
      fill = config.gatewayFillColor;
      stroke = config.gatewayStrokeColor;
      textColor = config.gatewayTextColor;
      lineW = config.strokeWidth;
    } else if (node.type === NodeType.START_EVENT) {
      fill = config.eventStartFillColor;
      stroke = config.eventStartStrokeColor;
      textColor = config.textColor;
      lineW = config.eventStartStrokeWidth;
    } else {
      fill = config.eventEndFillColor;
      stroke = config.eventEndStrokeColor;
      textColor = config.textColor;
      lineW = config.eventEndStrokeWidth;
    }

    ctx.fillStyle = fill;
    ctx.fill();
    ctx.strokeStyle = stroke;
    ctx.lineWidth = lineW * zoom;
    ctx.stroke();

    // 绘制居中文字
    const text: string = node.label;
    ctx.fillStyle = textColor;
    ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, x + w / 2, y + h / 2);

    ctx.restore();
  }

  private static getShape(nodeType: NodeType): NodeShape {
    switch (nodeType) {
      case NodeType.START_EVENT:
      case NodeType.END_EVENT:
        return NodeShape.CIRCLE;
      case NodeType.GATEWAY:
        return NodeShape.DIAMOND;
      case NodeType.TASK:
      default:
        return NodeShape.ROUNDED_RECT;
    }
  }
}