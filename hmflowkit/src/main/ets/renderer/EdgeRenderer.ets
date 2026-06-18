/*
 * Copyright (c) 2025 hm-flow-kit Contributors.
 *
 * Licensed under the MIT License. See LICENSE file in the project root.
 *
 * hm-flow-kit: Edge renderer — renders polyline edges with arrowheads on Canvas 2D.
 */

import { GraphEdge } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';

export class NodeRect {
  x: number;
  y: number;
  w: number;
  h: number;

  constructor(x: number, y: number, w: number, h: number) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
}

/**
 * Edge renderer.
 *
 * Renders a polyline (折线) path between source and target nodes,
 * with a filled arrowhead at the target end.
 *
 * Waypoint logic:
 *   - If GraphEdge.waypoints is non-empty, they are used verbatim.
 *   - Otherwise an orthogonal 3-segment path is computed from the
 *     center of the source node to the center of the target node.
 */
export class EdgeRenderer {
  /**
   * Render an edge onto the canvas.
   *
   * @param ctx       active Canvas2D context
   * @param edge      edge data to render
   * @param getNodePosition callback returning NodeRect for a node id
   * @param offsetX   canvas viewport offset X
   * @param offsetY   canvas viewport offset Y
   * @param zoom      current zoom factor
   */
  public static render(
    ctx: CanvasRenderingContext2D,
    edge: GraphEdge,
    getNodePosition: (id: string) => NodeRect,
    offsetX: number,
    offsetY: number,
    zoom: number,
    config: RenderConfig = new RenderConfig()
  ): void {
    ctx.save();
    ctx.translate(offsetX, offsetY);
    ctx.scale(zoom, zoom);

    const points: Array<number[]> = [];

    if (edge.waypoints.length > 0) {
      // Use explicit waypoints from the model
      for (let i = 0; i < edge.waypoints.length; i++) {
        const wp = edge.waypoints[i];
        points.push([wp.x, wp.y]);
      }
    } else {
      // Compute a 3-segment orthogonal path between source and target centers
      const srcRect: NodeRect = getNodePosition(edge.sourceId);
      const tgtRect: NodeRect = getNodePosition(edge.targetId);

      const sx: number = srcRect.x + srcRect.w / 2;
      const sy: number = srcRect.y + srcRect.h / 2;
      const tx: number = tgtRect.x + tgtRect.w / 2;
      const ty: number = tgtRect.y + tgtRect.h / 2;

      const dx: number = tx - sx;
      const dy: number = ty - sy;
      const absDx: number = dx < 0 ? -dx : dx;
      const absDy: number = dy < 0 ? -dy : dy;

      // Determine routing direction based on relative positions
      if (absDx > absDy) {
        // Horizontal dominant path: right/left → down/up → right/left
        const midX: number = (sx + tx) / 2;
        points.push([sx, sy]);
        points.push([midX, sy]);
        points.push([midX, ty]);
        points.push([tx, ty]);
      } else {
        // Vertical dominant path: down/up → right/left → down/up
        const midY: number = (sy + ty) / 2;
        points.push([sx, sy]);
        points.push([sx, midY]);
        points.push([tx, midY]);
        points.push([tx, ty]);
      }
    }

    // Draw the polyline
    {
      let isMessageFlow: boolean = edge.properties['bpmnElement'] === 'messageFlow';
      ctx.strokeStyle = isMessageFlow ? config.messageFlowStrokeColor : config.edgeStrokeColor;
      ctx.lineWidth = isMessageFlow ? config.messageFlowStrokeWidth : config.edgeStrokeWidth;
      if (isMessageFlow) {
        let src: number[] = config.messageFlowDashPattern;
        let dp: number[] = [src[0] * zoom, src[1] * zoom];
        ctx.setLineDash(dp);
      }
      ctx.beginPath();
      ctx.moveTo(points[0][0], points[0][1]);
      for (let i = 1; i < points.length; i++) {
        ctx.lineTo(points[i][0], points[i][1]);
      }
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Draw arrowhead at the end of the last segment
    if (points.length >= 2) {
      const last: number[] = points[points.length - 1];
      const prev: number[] = points[points.length - 2];

      const segDx: number = last[0] - prev[0];
      const segDy: number = last[1] - prev[1];
      const segLen: number = Math.sqrt(segDx * segDx + segDy * segDy);

      if (segLen > 0.1) {
        const angle: number = Math.atan2(segDy, segDx);
        const arrowLen: number = config.arrowSize;
        const arrowAngle: number = Math.PI / 6;

        let isMessageFlow: boolean = edge.properties['bpmnElement'] === 'messageFlow';
        if (isMessageFlow) {
          // Open arrowhead (空心箭头): stroke only, no fill
          ctx.strokeStyle = config.messageFlowStrokeColor;
          ctx.lineWidth = Math.max(1, config.messageFlowStrokeWidth * zoom);
          ctx.beginPath();
          ctx.moveTo(
            last[0] - arrowLen * Math.cos(angle - arrowAngle),
            last[1] - arrowLen * Math.sin(angle - arrowAngle)
          );
          ctx.lineTo(last[0], last[1]);
          ctx.lineTo(
            last[0] - arrowLen * Math.cos(angle + arrowAngle),
            last[1] - arrowLen * Math.sin(angle + arrowAngle)
          );
          ctx.stroke();
        } else {
          // Filled arrowhead
          ctx.fillStyle = config.edgeStrokeColor;
          ctx.beginPath();
          ctx.moveTo(last[0], last[1]);
          ctx.lineTo(
            last[0] - arrowLen * Math.cos(angle - arrowAngle),
            last[1] - arrowLen * Math.sin(angle - arrowAngle)
          );
          ctx.lineTo(
            last[0] - arrowLen * Math.cos(angle + arrowAngle),
            last[1] - arrowLen * Math.sin(angle + arrowAngle)
          );
          ctx.closePath();
          ctx.fill();
        }
      }
    }

    // Draw edge label at path midpoint
    {
      let label: string = edge.label;
      if (label.length > 0) {
        // Compute total path length
        let totalLen: number = 0;
        let segLens: number[] = [];
        for (let i: number = 1; i < points.length; i++) {
          let sdx: number = points[i][0] - points[i - 1][0];
          let sdy: number = points[i][1] - points[i - 1][1];
          let sl: number = Math.sqrt(sdx * sdx + sdy * sdy);
          segLens.push(sl);
          totalLen = totalLen + sl;
        }
        // Find midpoint along path
        let half: number = totalLen / 2;
        let acc: number = 0;
        let si: number = 0;
        for (let i: number = 0; i < segLens.length; i++) {
          if (acc + segLens[i] >= half) {
            si = i;
            break;
          }
          acc = acc + segLens[i];
        }
        let t: number = segLens[si] > 0.01 ? (half - acc) / segLens[si] : 0;
        let mx: number = points[si][0] + (points[si + 1][0] - points[si][0]) * t;
        let my: number = points[si][1] + (points[si + 1][1] - points[si][1]) * t;
        // Perpendicular offset
        let pdx: number = points[si + 1][0] - points[si][0];
        let pdy: number = points[si + 1][1] - points[si][1];
        let plen: number = segLens[si];
        let off: number = 12;
        let perpX: number = plen > 0.01 ? -pdy / plen : 0;
        let perpY: number = plen > 0.01 ? pdx / plen : 1;
        let lx: number = mx + perpX * off;
        let ly: number = my + perpY * off;

        let fontSize: number = Math.max(10, Math.round(config.fontSize * 0.92));
        ctx.font = fontSize + 'px ' + config.fontFamily;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        let tm: TextMetrics = ctx.measureText(label);
        let tw: number = tm.width;
        let th: number = fontSize;
        let pad: number = 3;
        // Draw white background for readability
        ctx.fillStyle = 'rgba(255,255,255,0.85)';
        ctx.fillRect(lx - tw / 2 - pad, ly - th / 2 - pad, tw + pad * 2, th + pad * 2);
        // Draw text
        ctx.fillStyle = config.edgeStrokeColor;
        ctx.fillText(label, lx, ly);
      }
    }

    ctx.restore();
  }
}