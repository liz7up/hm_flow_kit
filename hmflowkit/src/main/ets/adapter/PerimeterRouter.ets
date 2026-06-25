/**
 * PerimeterRouter — exact edge-perimeter intersection for edge routing.
 *
 * Consumes ShapeDefinition to choose the right intersection algorithm
 * (continuous ellipse/rhombus/rect math), then computes the first
 * perimeter point hit by a ray from 'from' toward 'to'.
 */

import { ShapeDefinition } from './ShapeDefinition';
import { PerimeterKind } from './ShapeConfig';
import { NodeRect } from '../renderer/EdgeRenderer';

export class IntersectPoint {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

export class PerimeterRouter {
  /**
   * Compute the point on the shape's perimeter intersected by a ray
   * from (fromX, fromY) to (toX, toY). toX/toY are typically the shape center.
   */
  static intersect(
    shapeDef: ShapeDefinition,
    nodeRect: NodeRect,
    fromX: number, fromY: number,
    toX: number, toY: number
  ): IntersectPoint | null {
    let cx: number = nodeRect.x + nodeRect.w / 2;
    let cy: number = nodeRect.y + nodeRect.h / 2;

    // Ray direction from center toward the external point
    let dx: number = fromX - cx;
    let dy: number = fromY - cy;

    if (dx === 0 && dy === 0) {
      return new IntersectPoint(cx, cy);
    }

    if (shapeDef.perimeterKind === PerimeterKind.ELLIPSE) {
      return PerimeterRouter._ellipseIntersect(cx, cy,
        nodeRect.w / 2, nodeRect.h / 2, dx, dy);
    } else if (shapeDef.perimeterKind === PerimeterKind.RHOMBUS) {
      return PerimeterRouter._rhombusIntersect(cx, cy,
        nodeRect.w / 2, nodeRect.h / 2, dx, dy);
    }
    return PerimeterRouter._rectIntersect(cx, cy,
      nodeRect.w / 2, nodeRect.h / 2, dx, dy);
  }

  // ── Rectangle perimeter ───────────────────────────────────────────────

  private static _rectIntersect(cx: number, cy: number, hw: number, hh: number,
                                 dx: number, dy: number): IntersectPoint {
    if (dx === 0) {
      return new IntersectPoint(cx, cy + (dy > 0 ? hh : -hh));
    }
    if (dy === 0) {
      return new IntersectPoint(cx + (dx > 0 ? hw : -hw), cy);
    }
    let scaleX: number = hw / Math.abs(dx);
    let scaleY: number = hh / Math.abs(dy);
    let scale: number = scaleX < scaleY ? scaleX : scaleY;
    return new IntersectPoint(cx + dx * scale, cy + dy * scale);
  }

  // ── Ellipse perimeter ─────────────────────────────────────────────────

  private static _ellipseIntersect(cx: number, cy: number, rx: number, ry: number,
                                    dx: number, dy: number): IntersectPoint {
    let angle: number = Math.atan2(dy, dx);
    return new IntersectPoint(cx + rx * Math.cos(angle), cy + ry * Math.sin(angle));
  }

  // ── Rhombus perimeter ─────────────────────────────────────────────────

  private static _rhombusIntersect(cx: number, cy: number, hw: number, hh: number,
                                    dx: number, dy: number): IntersectPoint {
    let t: number = 1 / (Math.abs(dx) / hw + Math.abs(dy) / hh);
    return new IntersectPoint(cx + dx * t, cy + dy * t);
  }
}
