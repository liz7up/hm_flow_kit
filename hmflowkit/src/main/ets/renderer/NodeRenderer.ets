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
        const r: number = 8 * zoom;
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

    ctx.fillStyle = '#ffffff';
    ctx.fill();
    ctx.strokeStyle = '#333333';
    ctx.lineWidth = 2;
    ctx.stroke();

    // 绘制居中文字
    const text: string = node.label;
    ctx.fillStyle = '#333333';
    ctx.font = Math.max(12, Math.round(14 * zoom)) + 'px sans-serif';
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