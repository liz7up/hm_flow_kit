/**
 * PathRenderer — draws shape outlines from ShapeDefinition perimeter data.
 *
 * Dispatches on renderKind:
 *   NATIVE_ELLIPSE -> ctx.ellipse()
 *   NATIVE_RHOMBUS -> direct diamond coordinates
 *   POLYLINE       -> iterates perimeterPath points, applying arcTo corners
 *
 * Colors are passed in by the caller (Drawer); PathRenderer does not
 * resolve colors from node properties or RenderConfig.
 */

import { ShapeDefinition, ShapeRenderKind, PerimeterPoint } from '../adapter/ShapeDefinition';

export class PathRenderer {
  static render(
    ctx: CanvasRenderingContext2D,
    shapeDef: ShapeDefinition,
    x: number, y: number, w: number, h: number,
    fillColor: string,
    strokeColor: string,
    strokeWidth: number,
    cornerRadiusOverride?: number
  ): void {
    ctx.fillStyle = fillColor;
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = strokeWidth;

    if (shapeDef.renderKind === ShapeRenderKind.NATIVE_ELLIPSE) {
      PathRenderer._drawEllipse(ctx, x, y, w, h);
    } else if (shapeDef.renderKind === ShapeRenderKind.NATIVE_RHOMBUS) {
      PathRenderer._drawRhombus(ctx, x, y, w, h);
    } else {
      PathRenderer._drawPolyline(ctx, shapeDef, x, y, w, h, cornerRadiusOverride);
    }
  }

  // -- Native ellipse -------------------------------------------------------

  private static _drawEllipse(
    ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number
  ): void {
    ctx.beginPath();
    ctx.ellipse(x + w / 2, y + h / 2, w / 2, h / 2, 0, 0, 2 * Math.PI);
    if (ctx.fillStyle !== 'none') {
      ctx.fill();
    }
    if (ctx.strokeStyle !== 'none') {
      ctx.stroke();
    }
  }

  // -- Native rhombus -------------------------------------------------------

  private static _drawRhombus(
    ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number
  ): void {
    ctx.beginPath();
    ctx.moveTo(x + w / 2, y);
    ctx.lineTo(x + w, y + h / 2);
    ctx.lineTo(x + w / 2, y + h);
    ctx.lineTo(x, y + h / 2);
    ctx.closePath();
    if (ctx.fillStyle !== 'none') {
      ctx.fill();
    }
    if (ctx.strokeStyle !== 'none') {
      ctx.stroke();
    }
  }

  // -- Polyline from perimeterPath ------------------------------------------

  private static _drawPolyline(
    ctx: CanvasRenderingContext2D,
    shapeDef: ShapeDefinition,
    x: number, y: number, w: number, h: number,
    cornerRadiusOverride?: number
  ): void {
    let pts: PerimeterPoint[] = shapeDef.perimeterPath;
    if (pts.length < 3) {
      return;
    }

    let cr: number = cornerRadiusOverride !== undefined
      ? cornerRadiusOverride : shapeDef.cornerRadiusRatio;
    let crAbs: number = cr * Math.min(w, h);

    ctx.beginPath();
    // Convert normalized points to canvas coordinates
    let cxArr: number[] = new Array<number>(pts.length);
    let cyArr: number[] = new Array<number>(pts.length);
    for (let i: number = 0; i < pts.length; i++) {
      cxArr[i] = x + pts[i].xFraction * w;
      cyArr[i] = y + pts[i].yFraction * h;
    }

    if (crAbs > 0) {
      // Rounded corners: use arcTo between consecutive segments
      ctx.moveTo((cxArr[0] + cxArr[pts.length - 1]) / 2 + (crAbs > 0 ? crAbs * 0.01 : 0),
                  (cyArr[0] + cyArr[pts.length - 1]) / 2);

      for (let i: number = 0; i < pts.length; i++) {
        let i0: number = (i - 1 + pts.length) % pts.length;
        let i1: number = i;
        let i2: number = (i + 1) % pts.length;
        if (i === 0) {
          ctx.moveTo(
            (cxArr[i0] + cxArr[i1]) / 2,
            (cyArr[i0] + cyArr[i1]) / 2
          );
        }
        ctx.lineTo(
          (cxArr[i1] + cxArr[i2]) / 2,
          (cyArr[i1] + cyArr[i2]) / 2
        );
        ctx.arcTo(cxArr[i2], cyArr[i2], cxArr[i2], cyArr[i2], crAbs);
      }
    } else {
      // Sharp corners: straight lineTo
      ctx.moveTo(cxArr[0], cyArr[0]);
      for (let i: number = 1; i < pts.length; i++) {
        ctx.lineTo(cxArr[i], cyArr[i]);
      }
    }
    ctx.closePath();

    if (ctx.fillStyle !== 'none') {
      ctx.fill();
    }
    if (ctx.strokeStyle !== 'none') {
      ctx.stroke();
    }
  }
}
