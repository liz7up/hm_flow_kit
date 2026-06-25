/**
 * ShapeConfig — centralized shape-type registry and perimeter rules.
 *
 * All external formats (drawio, BPMN, future Visio/UML) map their shapes
 * to the internal types defined here. Renderers only see these types and
 * can call getPerimeterType() / getEdgeDefaults() without knowing the source format.
 */

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
}
