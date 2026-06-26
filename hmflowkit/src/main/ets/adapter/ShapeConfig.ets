/**
 * ShapeConfig — centralized shape-type registry and perimeter rules.
 *
 * All external formats (drawio, BPMN, future Visio/UML) map their shapes
 * to the internal types defined here. Renderers only see these types and
 * can call getPerimeterType() / getEdgeDefaults() without knowing the source format.
 */

import { ShapeDefinition, ShapeRenderKind, PerimeterPoint, SIMPLE_RECT, EVENT_PERIMETER, GATEWAY_PERIMETER } from './ShapeDefinition';

// ─── Internal perimeter categories ──────────────────────────────────────────

export enum PerimeterKind {
  RECT,      // rectangle / rounded-rect (task, subProcess, data*, annotation, swimlane...)
  ELLIPSE,   // ellipse / circle (events)
  RHOMBUS    // rhombus / diamond (gateways)
}

// ─── Type → perimeter mapping ──────────────────────────────────────────────

const _perimeterMap: Record<string, PerimeterKind> = {
  // BPMN types
  'task':          PerimeterKind.RECT,
  'callActivity':  PerimeterKind.RECT,
  'subProcess':    PerimeterKind.RECT,
  'dataObject':    PerimeterKind.RECT,
  'dataStore':     PerimeterKind.RECT,
  'textAnnotation': PerimeterKind.RECT,
  'startEvent':    PerimeterKind.ELLIPSE,
  'endEvent':      PerimeterKind.ELLIPSE,
  'intermediateEvent': PerimeterKind.ELLIPSE,
  'boundaryEvent': PerimeterKind.ELLIPSE,
  'gateway':       PerimeterKind.RHOMBUS,
  'eventBasedGateway': PerimeterKind.RHOMBUS,
  'complexGateway': PerimeterKind.RHOMBUS,

  // drawio basic types
  'drawio.rect':         PerimeterKind.RECT,
  'drawio.roundedRect':  PerimeterKind.RECT,
  'drawio.ellipse':      PerimeterKind.ELLIPSE,
  'drawio.rhombus':      PerimeterKind.RHOMBUS,
  'drawio.triangle':     PerimeterKind.RECT,
  'drawio.parallelogram': PerimeterKind.RECT,
  'drawio.text':         PerimeterKind.RECT,
  'drawio.swimlane':     PerimeterKind.RECT,
  'drawio.unknown':      PerimeterKind.RECT,
};

// ── Shape definition registry ─────────────────────────────────────────────

const _shapeDefMap: Record<string, ShapeDefinition> = {};
let _shapeDefCount: number = 0;
let _shapeDefDefault: ShapeDefinition;

function _buildDefaultShapeDef(): ShapeDefinition {
  let defaultPath: PerimeterPoint[] = [
    { xFraction: 0, yFraction: 0 },
    { xFraction: 1, yFraction: 0 },
    { xFraction: 1, yFraction: 1 },
    { xFraction: 0, yFraction: 1 },
  ];
  return new ShapeDefinition('_default', ShapeRenderKind.POLYLINE,
    PerimeterKind.RECT, defaultPath, 0);
}

_shapeDefDefault = _buildDefaultShapeDef();

// Pre-populate shape definitions from the existing PerimeterKind map.
// This ensures both BPMN and drawio types have correct ShapeDefinitions
// regardless of which parser runs first.
// NOTE: executed inline (no function wrapper) to satisfy arkts-no-func-expressions.
{
  let rectPath: PerimeterPoint[] = SIMPLE_RECT;
  let ellipsePath: PerimeterPoint[] = EVENT_PERIMETER;
  let rhombusPath: PerimeterPoint[] = GATEWAY_PERIMETER;

  let keys: string[] = Object.keys(_perimeterMap);
  for (let i: number = 0; i < keys.length; i++) {
    let k: string = keys[i];
    let kind: PerimeterKind = _perimeterMap[k];
    if (kind === PerimeterKind.ELLIPSE) {
      _shapeDefMap[k] = new ShapeDefinition(k, ShapeRenderKind.NATIVE_ELLIPSE,
        PerimeterKind.ELLIPSE, ellipsePath, 0);
    } else if (kind === PerimeterKind.RHOMBUS) {
      _shapeDefMap[k] = new ShapeDefinition(k, ShapeRenderKind.NATIVE_RHOMBUS,
        PerimeterKind.RHOMBUS, rhombusPath, 0);
    } else {
      _shapeDefMap[k] = new ShapeDefinition(k, ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, rectPath, 0.133);
    }
  }
  _shapeDefCount = keys.length;
}

export class ShapeConfig {
  /**
   * Returns the perimeter algorithm category for any internal node type.
   * Unknown types fall back to RECT.
   */
  static perimeterKind(nodeType: string): PerimeterKind {
    let k: PerimeterKind | undefined = _perimeterMap[nodeType];
    return k !== undefined ? k : PerimeterKind.RECT;
  }

  /**
   * Returns true if edges from this format should suppress arrows
   * when the edge style explicitly says "none".
   */
  static formatRespectsArrowNone(format: string): boolean {
    // drawio uses endArrow=none; BPMN uses association element tag.
    // Both are handled in EdgeRenderer via union check.
    return true;
  }

  /**
   * Register a shape definition. Later calls with the same shapeId overwrite.
   */
  static registerShape(
    shapeId: string,
    renderKind: ShapeRenderKind,
    perimeterKind: PerimeterKind,
    perimeterPath: PerimeterPoint[],
    cornerRadiusRatio: number = 0
  ): void {
    if (_shapeDefMap[shapeId] === undefined) {
      _shapeDefCount++;
    }
    _shapeDefMap[shapeId] = new ShapeDefinition(
      shapeId, renderKind, perimeterKind,
      perimeterPath, cornerRadiusRatio
    );
  }

  /**
   * Get a shape definition by id. Never returns null — unknown ids
   * fall back to a default RECT definition.
   */
  static getShapeDefinition(shapeId: string): ShapeDefinition {
    let d: ShapeDefinition | undefined = _shapeDefMap[shapeId];
    if (d !== undefined) {
      return d;
    }
    return _shapeDefDefault;
  }

  /**
   * Returns the number of registered shape definitions (excluding default).
   */
  static shapeCount(): number {
    return _shapeDefCount;
  }
}
