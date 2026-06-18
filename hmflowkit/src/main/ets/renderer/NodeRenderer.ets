import { GraphNode, NodeType } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';
import { TaskDrawer } from './TaskDrawer';
import { GatewayDrawer } from './GatewayDrawer';
import { EventDrawer } from './EventDrawer';
import { SubProcessDrawer } from './SubProcessDrawer';
import { DataDrawer } from './DataDrawer';
import { AnnotationDrawer } from './AnnotationDrawer';

export class NodeRenderer {
  public static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    let x: number = node.x * zoom + offsetX;
    let y: number = node.y * zoom + offsetY;
    let w: number = node.width * zoom;
    let h: number = node.height * zoom;

    ctx.save();
    switch (node.type) {
      case NodeType.TASK:
      case NodeType.CALL_ACTIVITY:
        TaskDrawer.render(ctx, node, config, x, y, w, h, zoom);
        break;
      case NodeType.GATEWAY:
      case NodeType.EVENT_BASED_GATEWAY:
      case NodeType.COMPLEX_GATEWAY:
        GatewayDrawer.render(ctx, node, config, x, y, w, h, zoom);
        break;
      case NodeType.START_EVENT:
      case NodeType.END_EVENT:
      case NodeType.BOUNDARY_EVENT:
      case NodeType.INTERMEDIATE_EVENT:
        EventDrawer.render(ctx, node, config, x, y, w, h, zoom);
        break;
      case NodeType.SUB_PROCESS:
        SubProcessDrawer.render(ctx, node, config, x, y, w, h, zoom);
        break;
      case NodeType.DATA_OBJECT:
      case NodeType.DATA_STORE:
        DataDrawer.render(ctx, node, config, x, y, w, h, zoom);
        break;
      case NodeType.TEXT_ANNOTATION:
        AnnotationDrawer.render(ctx, node, config, x, y, w, h, zoom);
        break;
      default:
        // fallback: simple rect for unknown types
        ctx.fillStyle = config.fillColor;
        ctx.fillRect(x, y, w, h);
        ctx.strokeStyle = config.strokeColor;
        ctx.lineWidth = config.strokeWidth * zoom;
        ctx.strokeRect(x, y, w, h);
        break;
    }
    ctx.restore();
  }
}
