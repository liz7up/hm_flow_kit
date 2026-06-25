import { GraphNode } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';
import { ShapeDefinition } from '../adapter/ShapeDefinition';
import { PathRenderer } from './PathRenderer';
import { ShapeConfig } from '../adapter/ShapeConfig';
import { sanitizeLabel } from './TextUtils';

export class GatewayDrawer {
  static render(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    config: RenderConfig,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    let cx: number = x + w / 2;
    let cy: number = y + h / 2;

    // Diamond outline via PathRenderer
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition('bpmn.gateway2');
    PathRenderer.render(ctx, shapeDef, x, y, w, h,
      config.gatewayFillColor, config.gatewayStrokeColor,
      config.strokeWidth * zoom);

    // Gateway internal marker — per-type sizing
    let gwTag: string | undefined = node.properties['bpmnElement'];
    if (gwTag !== undefined && gwTag.length > 0) {
      let base: number = Math.min(w, h);
      let s: number;
      let scale: number | undefined = config.gatewayMarkerScale[gwTag];
      s = base * (scale !== undefined ? scale : 0.28) * zoom;
      ctx.fillStyle = config.gatewayMarkerColor;
      ctx.strokeStyle = config.gatewayMarkerColor;
      ctx.lineWidth = Math.max(1.5, 2 * zoom);
      GatewayDrawer.drawMarker(ctx, gwTag, cx, cy, s);
    }

    // Label (only when no marker, otherwise marker overlaps)
    let hasMarker: boolean = gwTag !== undefined && gwTag.length > 0;
    if (!hasMarker) {
      let text: string = sanitizeLabel(node.label);
      if (text.length > 0) {
        ctx.fillStyle = config.gatewayTextColor;
        ctx.font = Math.max(config.fontSizeMin, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(text, cx, cy);
      }
    }
  }

  // ── 网关内部标记 ──

  private static drawMarker(
    ctx: CanvasRenderingContext2D,
    tagName: string,
    cx: number,
    cy: number,
    s: number
  ): void {
    ctx.beginPath();
    if (tagName === 'exclusiveGateway') {
      ctx.moveTo(cx - s, cy - s);
      ctx.lineTo(cx + s, cy + s);
      ctx.moveTo(cx + s, cy - s);
      ctx.lineTo(cx - s, cy + s);
    } else if (tagName === 'parallelGateway') {
      ctx.moveTo(cx - s, cy);
      ctx.lineTo(cx + s, cy);
      ctx.moveTo(cx, cy - s);
      ctx.lineTo(cx, cy + s);
    } else if (tagName === 'inclusiveGateway') {
      ctx.arc(cx, cy, s * 0.7, 0, Math.PI * 2);
    } else if (tagName === 'eventBasedGateway') {
      // Pentagon inside circle (outer circle, inner pentagon)
      ctx.arc(cx, cy, s * 0.55, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      let pentR: number = s * 0.35;
      for (let i: number = 0; i < 5; i++) {
        let angle: number = (-Math.PI / 2) + (i * 2 * Math.PI / 5);
        let px: number = cx + pentR * Math.cos(angle);
        let py: number = cy + pentR * Math.sin(angle);
        if (i === 0) {
          ctx.moveTo(px, py);
        } else {
          ctx.lineTo(px, py);
        }
      }
      ctx.closePath();
    } else if (tagName === 'complexGateway') {
      // Asterisk/star: 3 crossed lines inside circle
      ctx.arc(cx, cy, s * 0.55, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      for (let i: number = 0; i < 3; i++) {
        let angle: number = (Math.PI * i) / 3;
        let dx: number = s * 0.4 * Math.cos(angle);
        let dy: number = s * 0.4 * Math.sin(angle);
        ctx.moveTo(cx - dx, cy - dy);
        ctx.lineTo(cx + dx, cy + dy);
      }
    }
    ctx.stroke();
  }
}
