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

import { ShapeDefinition, ShapeRenderKind, PerimeterPoint, PerimeterSegmentKind } from '../adapter/ShapeDefinition';

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
      // Rounded corners: lineTo midpoint entering corner, arcTo around vertex toward exit midpoint
      for (let i: number = 0; i < pts.length; i++) {
        let iPrev: number = (i - 1 + pts.length) % pts.length;
        let iCurr: number = i;
        let iNext: number = (i + 1) % pts.length;

        // Entry: midpoint of previous edge, entering this corner
        let entryX: number = (cxArr[iPrev] + cxArr[iCurr]) / 2;
        let entryY: number = (cyArr[iPrev] + cyArr[iCurr]) / 2;
        // Corner: the vertex itself
        let cornerX: number = cxArr[iCurr];
        let cornerY: number = cyArr[iCurr];
        // Exit: midpoint of next edge, leaving this corner
        let exitX: number = (cxArr[iCurr] + cxArr[iNext]) / 2;
        let exitY: number = (cyArr[iCurr] + cyArr[iNext]) / 2;

        if (i === 0) {
          ctx.moveTo(entryX, entryY);
        }
        ctx.lineTo(entryX, entryY);
        ctx.arcTo(cornerX, cornerY, exitX, exitY, crAbs);
      }
    } else {
      // Sharp corners: lineTo or quadraticCurveTo per point kind
      ctx.moveTo(cxArr[0], cyArr[0]);
      for (let i: number = 1; i < pts.length; i++) {
        let pt: PerimeterPoint = pts[i];
        if (pt.kind === PerimeterSegmentKind.QUAD &&
            pt.cpXFraction !== undefined && pt.cpYFraction !== undefined) {
          let cpx: number = x + pt.cpXFraction * w;
          let cpy: number = y + pt.cpYFraction * h;
          ctx.quadraticCurveTo(cpx, cpy, cxArr[i], cyArr[i]);
        } else {
          ctx.lineTo(cxArr[i], cyArr[i]);
        }
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
