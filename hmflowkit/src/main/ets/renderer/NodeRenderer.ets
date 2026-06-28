import { GraphNode, NodeType } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';
import { TaskDrawer } from './TaskDrawer';
import { GatewayDrawer } from './GatewayDrawer';
import { EventDrawer } from './EventDrawer';
import { SubProcessDrawer } from './SubProcessDrawer';
import { DataDrawer } from './DataDrawer';
import { AnnotationDrawer } from './AnnotationDrawer';
import { StatusOverlayRenderer } from '../approval/StatusOverlayRenderer';
import {
  NodeStatus, NodeStatusMap, ApprovalOverlayConfig,
  OnNodeDecorator, NodeDrawRect
} from '../approval/ApprovalTypes';
import { PresetId } from '../approval/ApprovalPresets';

export type INodeDrawer = (
  ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
  x: number, y: number, w: number, h: number, zoom: number
) => void;

export class NodeRenderer {
  private static _registry: Record<string, INodeDrawer> = {};
  private static _inited: boolean = false;

  static register(type: string, drawer: INodeDrawer): void {
    NodeRenderer._registry[type] = drawer;
  }

  static render(
    ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
    offsetX: number, offsetY: number, zoom: number,
    nodeStatuses?: NodeStatusMap,
    approvalConfig?: ApprovalOverlayConfig,
    approvalColorPreset?: PresetId,
    onNodeDecorator?: OnNodeDecorator
  ): void {
    if (!NodeRenderer._inited) {
      NodeRenderer._initDefaultRegistry();
    }
    let x: number = node.x * zoom + offsetX;
    let y: number = node.y * zoom + offsetY;
    let w: number = node.width * zoom;
    let h: number = node.height * zoom;

    ctx.save();
    let drawer: INodeDrawer | undefined = NodeRenderer._registry[node.type];
    if (drawer !== undefined) {
      drawer(ctx, node, config, x, y, w, h, zoom);
    } else {
      NodeRenderer._fallbackRender(ctx, node, config, x, y, w, h, zoom);
    }

    // ── 审批状态覆盖层 ──
    let status: NodeStatus | null = null;
    if (nodeStatuses !== undefined) {
      status = nodeStatuses.get(node.id);
    }
    StatusOverlayRenderer.renderNodeStatus(
      ctx, node, nodeStatuses, approvalConfig, approvalColorPreset,
      x, y, w, h, zoom, node
    );

    // ── 开发者装饰器回调 ──
    if (onNodeDecorator !== undefined) {
      onNodeDecorator(node, status, ctx,
        new NodeDrawRect(x, y, w, h), zoom);
    }

    ctx.restore();
  }

  private static _initDefaultRegistry(): void {
    NodeRenderer._inited = true;

    // Wrap static-method drawers as INodeDrawer lambdas
    let taskDrawer: INodeDrawer = (ctx, node, config, x, y, w, h, zoom): void => {
      TaskDrawer.render(ctx, node, config, x, y, w, h, zoom);
    };
    let gatewayDrawer: INodeDrawer = (ctx, node, config, x, y, w, h, zoom): void => {
      GatewayDrawer.render(ctx, node, config, x, y, w, h, zoom);
    };
    let eventDrawer: INodeDrawer = (ctx, node, config, x, y, w, h, zoom): void => {
      EventDrawer.render(ctx, node, config, x, y, w, h, zoom);
    };
    let subProcessDrawer: INodeDrawer = (ctx, node, config, x, y, w, h, zoom): void => {
      SubProcessDrawer.render(ctx, node, config, x, y, w, h, zoom);
    };
    let dataDrawer: INodeDrawer = (ctx, node, config, x, y, w, h, zoom): void => {
      DataDrawer.render(ctx, node, config, x, y, w, h, zoom);
    };
    let annotationDrawer: INodeDrawer = (ctx, node, config, x, y, w, h, zoom): void => {
      AnnotationDrawer.render(ctx, node, config, x, y, w, h, zoom);
    };

    NodeRenderer.register(NodeType.TASK, taskDrawer);
    NodeRenderer.register(NodeType.CALL_ACTIVITY, taskDrawer);
    NodeRenderer.register(NodeType.GATEWAY, gatewayDrawer);
    NodeRenderer.register(NodeType.EVENT_BASED_GATEWAY, gatewayDrawer);
    NodeRenderer.register(NodeType.COMPLEX_GATEWAY, gatewayDrawer);
    NodeRenderer.register(NodeType.START_EVENT, eventDrawer);
    NodeRenderer.register(NodeType.END_EVENT, eventDrawer);
    NodeRenderer.register(NodeType.BOUNDARY_EVENT, eventDrawer);
    NodeRenderer.register(NodeType.INTERMEDIATE_EVENT, eventDrawer);
    NodeRenderer.register(NodeType.SUB_PROCESS, subProcessDrawer);
    NodeRenderer.register(NodeType.DATA_OBJECT, dataDrawer);
    NodeRenderer.register(NodeType.DATA_STORE, dataDrawer);
    NodeRenderer.register(NodeType.TEXT_ANNOTATION, annotationDrawer);
  }

  private static _fallbackRender(
    ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
    x: number, y: number, w: number, h: number, zoom: number
  ): void {
    let fill: string = node.properties['_fillColor'] || config.fillColor;
    let stroke: string = node.properties['_strokeColor'] || config.strokeColor;

    ctx.fillStyle = fill;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = stroke;
    ctx.lineWidth = config.strokeWidth * zoom;
    ctx.strokeRect(x, y, w, h);

    let label: string = node.label;
    if (label.length > 0) {
      let fontColor: string = node.properties['_fontColor'] || config.textColor;
      let fontSizeStr: string | undefined = node.properties['_fontSize'];
      let fontSize: number = fontSizeStr !== undefined ? parseInt(fontSizeStr) : config.fontSize;
      let scaledFontSize: number = Math.max(9, Math.round(fontSize * zoom));
      ctx.fillStyle = fontColor;
      ctx.font = scaledFontSize + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';

      let lines: string[] = label.split('\n');
      let lineHeight: number = Math.round(scaledFontSize * 1.4);
      let totalH: number = lineHeight * lines.length;
      let startY: number = y + h / 2 - totalH / 2 + lineHeight / 2;
      for (let i: number = 0; i < lines.length; i++) {
        let ly: number = startY + i * lineHeight;
        let maxW: number = w - 8;
        let text: string = lines[i];
        let metrics: TextMetrics = ctx.measureText(text);
        if (metrics.width > maxW) {
          while (text.length > 0 && ctx.measureText(text + '…').width > maxW) {
            text = text.substring(0, text.length - 1);
          }
          text = text + '…';
        }
        ctx.fillText(text, x + w / 2, ly);
      }
    }
  }
}
