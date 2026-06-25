/**
 * ShapeDefinition — normalized perimeter path data for data-driven shape outlines.
 *
 * Stores drawio-style normalized perimeter points and routing strategy.
 * PathRenderer uses this for outline drawing; PerimeterRouter for edge attachment.
 */

import { PerimeterKind } from './ShapeConfig';

// ── PerimeterPoint ────────────────────────────────────────────────────────

export interface PerimeterPoint {
  xFraction: number;  // 0.0 ~ 1.0, relative to shape width
  yFraction: number;  // 0.0 ~ 1.0, relative to shape height
}

// ── ShapeRenderKind ───────────────────────────────────────────────────────

export enum ShapeRenderKind {
  NATIVE_ELLIPSE,  // Use Canvas ctx.ellipse() for perfect circles at any zoom
  NATIVE_RHOMBUS,  // Use direct rhombus coordinates (midpoints of each side)
  POLYLINE,        // Follow perimeterPath points with lineTo/arcTo
}

// ── ShapeDefinition ───────────────────────────────────────────────────────

export class ShapeDefinition {
  readonly shapeId: string;
  readonly renderKind: ShapeRenderKind;
  readonly perimeterKind: PerimeterKind;
  readonly perimeterPath: PerimeterPoint[];
  readonly cornerRadiusRatio: number;

  constructor(
    shapeId: string,
    renderKind: ShapeRenderKind,
    perimeterKind: PerimeterKind,
    perimeterPath: PerimeterPoint[],
    cornerRadiusRatio: number = 0
  ) {
    this.shapeId = shapeId;
    this.renderKind = renderKind;
    this.perimeterKind = perimeterKind;
    this.perimeterPath = perimeterPath;
    this.cornerRadiusRatio = cornerRadiusRatio;
  }
}

// ── Canonical perimeter paths from drawio official BPMN shapes ────────────

/**
 * TASK_PERIMETER — 12-point rounded rectangle from mxgraph.bpmn.task2.
 * Clockwise: top-left corner → top → top-right → right → ... → left.
 * CornerRadius = 0.133 * min(w, h) corresponding to cornerRadiusRatio 0.133.
 */
export const TASK_PERIMETER: PerimeterPoint[] = [
  { xFraction: 0.25, yFraction: 0 },
  { xFraction: 0.5,  yFraction: 0 },
  { xFraction: 0.75, yFraction: 0 },
  { xFraction: 1, yFraction: 0.25 },
  { xFraction: 1, yFraction: 0.5 },
  { xFraction: 1, yFraction: 0.75 },
  { xFraction: 0.75, yFraction: 1 },
  { xFraction: 0.5,  yFraction: 1 },
  { xFraction: 0.25, yFraction: 1 },
  { xFraction: 0, yFraction: 0.75 },
  { xFraction: 0, yFraction: 0.5 },
  { xFraction: 0, yFraction: 0.25 },
];

/**
 * EVENT_PERIMETER — 8-point octagon approximation from mxgraph.bpmn.event.
 * Used only for perimeter routing waypoint reference; rendering uses NATIVE_ELLIPSE.
 */
export const EVENT_PERIMETER: PerimeterPoint[] = [
  { xFraction: 0.145, yFraction: 0.145 },
  { xFraction: 0.5,   yFraction: 0 },
  { xFraction: 0.855, yFraction: 0.145 },
  { xFraction: 1, yFraction: 0.5 },
  { xFraction: 0.855, yFraction: 0.855 },
  { xFraction: 0.5, yFraction: 1 },
  { xFraction: 0.145, yFraction: 0.855 },
  { xFraction: 0, yFraction: 0.5 },
];

/**
 * GATEWAY_PERIMETER — 8-point rhombus/diamond from mxgraph.bpmn.gateway2.
 * Clockwise from top-left diagonal → top center → top-right → right center → ...
 */
export const GATEWAY_PERIMETER: PerimeterPoint[] = [
  { xFraction: 0.25, yFraction: 0.25 },
  { xFraction: 0.5,  yFraction: 0 },
  { xFraction: 0.75, yFraction: 0.25 },
  { xFraction: 1, yFraction: 0.5 },
  { xFraction: 0.75, yFraction: 0.75 },
  { xFraction: 0.5,  yFraction: 1 },
  { xFraction: 0.25, yFraction: 0.75 },
  { xFraction: 0, yFraction: 0.5 },
];
