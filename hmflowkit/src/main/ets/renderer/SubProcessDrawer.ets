import { GraphNode } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';
import { ShapeDefinition } from '../adapter/ShapeDefinition';
import { PathRenderer } from './PathRenderer';
import { ShapeConfig } from '../adapter/ShapeConfig';
import { sanitizeLabel } from './TextUtils';

export class SubProcessDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition(node.type);
    let isTx: boolean = node.properties['bpmnElement'] === 'transaction';

    // Event subProcess → dashed; Transaction → double-line; else → solid
    if (node.properties['triggeredByEvent'] === 'true') {
      ctx.setLineDash([config.subProcessDashPattern[0] * zoom, config.subProcessDashPattern[1] * zoom]);
      PathRenderer.render(ctx, shapeDef, x, y, w, h,
        config.taskFillColor, config.taskStrokeColor,
        config.strokeWidth * zoom);
      ctx.setLineDash([]);
    } else if (isTx) {
      // Double border: outer + inner
      PathRenderer.render(ctx, shapeDef, x, y, w, h,
        config.taskFillColor, config.taskStrokeColor,
        config.strokeWidth * zoom * 1.5);
      let inset: number = config.subProcessInset * zoom;
      PathRenderer.render(ctx, shapeDef,
        x + inset, y + inset, w - inset * 2, h - inset * 2,
        'none', config.taskStrokeColor,
        config.strokeWidth * zoom);
    } else {
      PathRenderer.render(ctx, shapeDef, x, y, w, h,
        config.taskFillColor, config.taskStrokeColor,
        config.strokeWidth * zoom);
    }

    // [+] expand marker — only collapsed <subProcess>, not <transaction>
    let isExpanded: boolean = node.properties['isExpanded'] !== 'false';
    if (!isTx && !isExpanded) {
      let markerSize: number = config.subProcessExpandMarkerSize * zoom;
      let mx: number = x + w / 2;
      let my: number = y + h + markerSize / 2;
      ctx.fillStyle = '#1890FF';
      ctx.fillRect(mx - markerSize / 2, my - markerSize / 2, markerSize, markerSize);
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1.5 * zoom;
      ctx.beginPath();
      ctx.moveTo(mx - markerSize * 0.35, my);
      ctx.lineTo(mx + markerSize * 0.35, my);
      ctx.moveTo(mx, my - markerSize * 0.35);
      ctx.lineTo(mx, my + markerSize * 0.35);
      ctx.stroke();
    }

    // Label — expanded: top-left, collapsed: center
    let text: string = sanitizeLabel(node.label);
    if (text.length > 0) {
      ctx.fillStyle = config.taskTextColor;
      ctx.font = Math.max(config.fontSizeMin, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
      if (isExpanded) {
        // expanded subProcess: label centered near top (avoids rounded corners + internal elements)
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(text, x + w / 2, y + 14 * zoom);
      } else {
        // collapsed subProcess: label centered
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(text, x + w / 2, y + h / 2);
      }
    }
  }
}
