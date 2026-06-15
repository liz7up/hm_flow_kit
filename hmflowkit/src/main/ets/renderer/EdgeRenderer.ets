/*
 * Copyright (c) 2025 hm-flow-kit Contributors.
 *
 * Licensed under the MIT License. See LICENSE file in the project root.
 *
 * hm-flow-kit: Edge renderer — renders polyline edges with arrowheads on Canvas 2D.
 */

import { GraphEdge } from '../model/GraphModel';

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
    zoom: number
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
      const strokeColor: string = '#5e5e5e';
      const lineWidth: number = 2;
      ctx.strokeStyle = strokeColor;
      ctx.lineWidth = lineWidth;
      ctx.beginPath();
      ctx.moveTo(points[0][0], points[0][1]);
      for (let i = 1; i < points.length; i++) {
        ctx.lineTo(points[i][0], points[i][1]);
      }
      ctx.stroke();
    }

    // Draw arrowhead at the end of the last segment
    if (points.length >= 2) {
      const last: number[] = points[points.length - 1];
      const prev: number[] = points[points.length - 2];

      // Segment vector pointing from prev to last
      const segDx: number = last[0] - prev[0];
      const segDy: number = last[1] - prev[1];
      const segLen: number = Math.sqrt(segDx * segDx + segDy * segDy);

      if (segLen > 0.1) {
        const angle: number = Math.atan2(segDy, segDx);
        const arrowLen: number = 12;
        const arrowAngle: number = Math.PI / 6;

        ctx.fillStyle = '#5e5e5e';
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

    ctx.restore();
  }
}