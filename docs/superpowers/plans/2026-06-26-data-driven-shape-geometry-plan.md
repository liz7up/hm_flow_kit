# Data-Driven Shape Geometry — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a data-driven shape geometry system that extracts perimeter path data from drawio's official BPMN shapes, enabling unified outline rendering and precise edge-perimeter intersection across BPMN XML and drawio formats.

**Architecture:** Three new modules in adapter/ and renderer/ layers. ShapeDefinition stores normalized perimeter points + render/routing strategy. PathRenderer draws outlines from ShapeDefinition. PerimeterRouter computes edge-perimeter intersection using continuous math (ellipse/rhombus/rect) routing formulas. Six existing Drawers refactored to use PathRenderer for outlines while preserving all icon/marker drawing code. BPMN 1.0 behavior unchanged.

**Tech Stack:** ArkTS, Canvas 2D (CanvasRenderingContext2D), @ohos/hypium test framework. Zero third-party dependencies.

## Global Constraints

- Zero npm/ohpm dependencies (MVP constraint)
- Must not modify BPMN 1.0 behavior — existing rendering identical after refactor
- Must follow 4-layer architecture: adapter ← parser, renderer ← adapter
- All public API exported via `hmflowkit/Index.ets`
- Tests use Hypium `describe/it/expect`, pure data/algorithm, no Canvas mock
- `test_all.sh` compile verification; no CI runner for unit test execution
- Coexistence: new modules are additive, old outline code removed only after visual verification

---

### Task 1: Create ShapeDefinition module

**Files:**
- Create: `hmflowkit/src/main/ets/adapter/ShapeDefinition.ets`
- Create: `hmflowkit/src/ohosTest/ets/test/ShapeDefinition.test.ets`

**Interfaces:**
- Produces: `interface PerimeterPoint { xFraction: number; yFraction: number }`, `enum ShapeRenderKind { NATIVE_ELLIPSE, NATIVE_RHOMBUS, POLYLINE }`, `class ShapeDefinition { shapeId, renderKind, perimeterKind, perimeterPath, cornerRadiusRatio }`, const `TASK_PERIMETER`, `EVENT_PERIMETER`, `GATEWAY_PERIMETER`

- [ ] **Step 1: Write the failing test**

```typescript
// ShapeDefinition.test.ets
import { describe, it, expect } from '@ohos/hypium';
import {
  PerimeterPoint,
  ShapeRenderKind,
  ShapeDefinition,
  TASK_PERIMETER,
  EVENT_PERIMETER,
  GATEWAY_PERIMETER
} from '../../../main/ets/adapter/ShapeDefinition';
import { PerimeterKind } from '../../../main/ets/adapter/ShapeConfig';

export default function shapeDefinitionTest(): void {
  describe('ShapeDefinition', () => {

    it('should_create_ShapeDefinition_with_given_fields', 0, () => {
      let pts: PerimeterPoint[] = [
        { xFraction: 0, yFraction: 0 },
        { xFraction: 1, yFraction: 1 }
      ];
      let def: ShapeDefinition = new ShapeDefinition(
        'test.shape', ShapeRenderKind.POLYLINE, PerimeterKind.RECT, pts, 0.1
      );
      expect(def.shapeId).assertEqual('test.shape');
      expect(def.renderKind).assertEqual(ShapeRenderKind.POLYLINE);
      expect(def.perimeterKind).assertEqual(PerimeterKind.RECT);
      expect(def.perimeterPath.length).assertEqual(2);
      expect(def.perimeterPath[0].xFraction).assertEqual(0);
      expect(def.perimeterPath[0].yFraction).assertEqual(0);
      expect(def.cornerRadiusRatio).assertEqual(0.1);
    });

    it('TASK_PERIMETER_should_have_12_points', 0, () => {
      expect(TASK_PERIMETER.length).assertEqual(12);
      expect(TASK_PERIMETER[0].xFraction).assertEqual(0.25);
      expect(TASK_PERIMETER[0].yFraction).assertEqual(0);
      expect(TASK_PERIMETER[3].xFraction).assertEqual(1);
      expect(TASK_PERIMETER[3].yFraction).assertEqual(0.25);
    });

    it('EVENT_PERIMETER_should_have_8_points', 0, () => {
      expect(EVENT_PERIMETER.length).assertEqual(8);
      expect(EVENT_PERIMETER[1].xFraction).assertEqual(0.5);
      expect(EVENT_PERIMETER[1].yFraction).assertEqual(0);
    });

    it('GATEWAY_PERIMETER_should_have_8_points', 0, () => {
      expect(GATEWAY_PERIMETER.length).assertEqual(8);
      expect(GATEWAY_PERIMETER[2].xFraction).assertEqual(0.75);
      expect(GATEWAY_PERIMETER[2].yFraction).assertEqual(0.25);
    });

    it('all_points_should_have_fractions_in_0_1_range', 0, () => {
      let allPaths: PerimeterPoint[][] = [TASK_PERIMETER, EVENT_PERIMETER, GATEWAY_PERIMETER];
      for (let pi: number = 0; pi < allPaths.length; pi++) {
        for (let i: number = 0; i < allPaths[pi].length; i++) {
          let p: PerimeterPoint = allPaths[pi][i];
          expect(p.xFraction >= 0 && p.xFraction <= 1).assertTrue();
          expect(p.yFraction >= 0 && p.yFraction <= 1).assertTrue();
        }
      }
    });

  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
# Test will fail — ShapeDefinition file doesn't exist yet
# Compile will produce error about missing module
```

Expected: compilation error — `ShapeDefinition` module not found.

- [ ] **Step 3: Write ShapeDefinition.ets**

```typescript
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
# Compile via build.sh or direct hvigorw
# Tests compile and pass for ShapeDefinition
```

Expected: all 5 ShapeDefinition tests pass.

- [ ] **Step 5: Commit**

```bash
git add hmflowkit/src/main/ets/adapter/ShapeDefinition.ets \
        hmflowkit/src/ohosTest/ets/test/ShapeDefinition.test.ets
git commit -m "feat: add ShapeDefinition module with canonical perimeter paths"
```

---

### Task 2: Add registerShape/getShapeDefinition to ShapeConfig

**Files:**
- Modify: `hmflowkit/src/main/ets/adapter/ShapeConfig.ets`
- Modify: `hmflowkit/src/ohosTest/ets/test/ShapeDefinition.test.ets` (add to existing test)

**Interfaces:**
- Consumes: `ShapeDefinition`, `ShapeRenderKind`, `TASK_PERIMETER`, `EVENT_PERIMETER`, `GATEWAY_PERIMETER` from Task 1
- Produces: `ShapeConfig.registerShape(id, renderKind, perimeterKind, path, cornerRadiusRatio?)`, `ShapeConfig.getShapeDefinition(id): ShapeDefinition`, `ShapeConfig.shapeCount(): number`

- [ ] **Step 1: Write the failing test**

Add to `ShapeDefinition.test.ets`:

```typescript
import { ShapeConfig } from '../../../main/ets/adapter/ShapeConfig';
import { PerimeterKind } from '../../../main/ets/adapter/ShapeConfig';

// Add these test cases to the existing describe block:

it('registerShape_and_getShapeDefinition_should_roundtrip', 0, () => {
  let pts: PerimeterPoint[] = [{ xFraction: 0, yFraction: 0 }];
  ShapeConfig.registerShape('test.roundtrip', ShapeRenderKind.POLYLINE,
    PerimeterKind.RECT, pts, 0.05);
  let def: ShapeDefinition | null = ShapeConfig.getShapeDefinition('test.roundtrip');
  expect(def !== null).assertTrue();
  if (def !== null) {
    expect(def.shapeId).assertEqual('test.roundtrip');
    expect(def.renderKind).assertEqual(ShapeRenderKind.POLYLINE);
    expect(def.perimeterKind).assertEqual(PerimeterKind.RECT);
  }
});

it('getShapeDefinition_unknown_should_return_default_RECT', 0, () => {
  let def: ShapeDefinition | null = ShapeConfig.getShapeDefinition('nonexistent.type');
  expect(def !== null).assertTrue();
  if (def !== null) {
    expect(def.perimeterKind).assertEqual(PerimeterKind.RECT);
    expect(def.renderKind).assertEqual(ShapeRenderKind.POLYLINE);
  }
});

it('default_shape_definition_should_never_return_null', 0, () => {
  let def: ShapeDefinition | null = ShapeConfig.getShapeDefinition('completely.unknown');
  expect(def !== null).assertTrue();
});

it('predefined_bpmn_shapes_should_be_registrable', 0, () => {
  ShapeConfig.registerShape('bpmn.task2', ShapeRenderKind.POLYLINE,
    PerimeterKind.RECT, TASK_PERIMETER, 0.133);
  ShapeConfig.registerShape('bpmn.event', ShapeRenderKind.NATIVE_ELLIPSE,
    PerimeterKind.ELLIPSE, EVENT_PERIMETER);
  ShapeConfig.registerShape('bpmn.gateway2', ShapeRenderKind.NATIVE_RHOMBUS,
    PerimeterKind.RHOMBUS, GATEWAY_PERIMETER);

  expect(ShapeConfig.getShapeDefinition('bpmn.task2') !== null).assertTrue();
  expect(ShapeConfig.getShapeDefinition('bpmn.event') !== null).assertTrue();
  expect(ShapeConfig.getShapeDefinition('bpmn.gateway2') !== null).assertTrue();
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
# registerShape / getShapeDefinition don't exist yet
```

Expected: compilation error.

- [ ] **Step 3: Add registry to ShapeConfig.ets**

Insert after the `PerimeterKind` enum definition, before the `ShapeConfig` class:

```typescript
import { ShapeDefinition, ShapeRenderKind, PerimeterPoint } from './ShapeDefinition';

// ── Shape definition registry ─────────────────────────────────────────────

const _shapeDefMap: Record<string, ShapeDefinition> = {};
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
```

Add to the `ShapeConfig` class:

```typescript
export class ShapeConfig {

  // ... keep existing perimeterKind() method ...

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
    let count: number = 0;
    for (let _key in _shapeDefMap) {
      count++;
    }
    return count;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

All 9 tests in ShapeDefinition.test.ets compile and pass.

- [ ] **Step 5: Commit**

```bash
git add hmflowkit/src/main/ets/adapter/ShapeConfig.ets \
        hmflowkit/src/ohosTest/ets/test/ShapeDefinition.test.ets
git commit -m "feat: add ShapeDefinition registry to ShapeConfig"
```

---

### Task 3: Create PerimeterRouter

**Files:**
- Create: `hmflowkit/src/main/ets/adapter/PerimeterRouter.ets`
- Create: `hmflowkit/src/ohosTest/ets/test/PerimeterRouter.test.ets`

**Interfaces:**
- Consumes: `ShapeDefinition`, `PerimeterKind` from Task 1/2; `NodeRect` from `EdgeRenderer`
- Produces: `PerimeterRouter.intersect(shapeDef, nodeRect, fromX, fromY, toX, toY): { x, y } | null`

- [ ] **Step 1: Write the failing test**

```typescript
// PerimeterRouter.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { PerimeterRouter } from '../../../main/ets/adapter/PerimeterRouter';
import { ShapeDefinition, ShapeRenderKind, TASK_PERIMETER, EVENT_PERIMETER, GATEWAY_PERIMETER } from '../../../main/ets/adapter/ShapeDefinition';
import { PerimeterKind, ShapeConfig } from '../../../main/ets/adapter/ShapeConfig';
import { NodeRect } from '../../../main/ets/renderer/EdgeRenderer';

export default function perimeterRouterTest(): void {
  describe('PerimeterRouter', () => {

    // ── RECT perimeter ──

    it('rect_perimeter_right_side', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('test', ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, TASK_PERIMETER, 0.133);
      let rect: NodeRect = new NodeRect(100, 100, 120, 80);
      // Ray from center (160, 140) toward right (300, 140)
      let r = PerimeterRouter.intersect(def, rect, 300, 140, 160, 140);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(220, 1);  // right edge at x=220
        expect(r.y).assertClose(140, 1);
      }
    });

    it('rect_perimeter_top_side', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('test', ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, TASK_PERIMETER, 0.133);
      let rect: NodeRect = new NodeRect(100, 100, 120, 80);
      // Ray from center (160, 140) toward top (160, 0)
      let r = PerimeterRouter.intersect(def, rect, 160, 0, 160, 140);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(160, 1);
        expect(r.y).assertClose(100, 1);  // top edge at y=100
      }
    });

    it('rect_perimeter_diagonal', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('test', ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, TASK_PERIMETER, 0.133);
      let rect: NodeRect = new NodeRect(0, 0, 100, 100);
      // Ray from center (50, 50) toward top-right
      let r = PerimeterRouter.intersect(def, rect, 150, 0, 50, 50);
      expect(r !== null).assertTrue();
      if (r !== null) {
        // Should hit top edge (dy dominates) or right edge (dx dominates)
        // Top: y=0, x ≈ 50 + (50/100)*50 = 75
        // Right: x=100, y ≈ 50 + (50/100)*50 = 75
        // Both give same distance → top edge wins with scaleX > scaleY
        expect(r.x).assertClose(75, 5);
        expect(r.y).assertClose(0, 5);
      }
    });

    // ── ELLIPSE perimeter ──

    it('ellipse_perimeter_horizontal', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('event', ShapeRenderKind.NATIVE_ELLIPSE,
        PerimeterKind.ELLIPSE, EVENT_PERIMETER);
      let rect: NodeRect = new NodeRect(0, 0, 100, 100);
      let r = PerimeterRouter.intersect(def, rect, 200, 50, 50, 50);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(100, 5);  // right edge of ellipse
        expect(r.y).assertClose(50, 5);
      }
    });

    it('ellipse_perimeter_vertical', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('event', ShapeRenderKind.NATIVE_ELLIPSE,
        PerimeterKind.ELLIPSE, EVENT_PERIMETER);
      let rect: NodeRect = new NodeRect(0, 0, 100, 100);
      let r = PerimeterRouter.intersect(def, rect, 50, -50, 50, 50);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(50, 5);
        expect(r.y).assertClose(0, 5);  // top edge
      }
    });

    // ── RHOMBUS perimeter ──

    it('rhombus_perimeter_horizontal', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('gateway', ShapeRenderKind.NATIVE_RHOMBUS,
        PerimeterKind.RHOMBUS, GATEWAY_PERIMETER);
      let rect: NodeRect = new NodeRect(0, 0, 100, 100);
      let r = PerimeterRouter.intersect(def, rect, 200, 50, 50, 50);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(100, 5);  // right point of diamond
        expect(r.y).assertClose(50, 5);
      }
    });

    it('rhombus_perimeter_45_degree', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('gateway', ShapeRenderKind.NATIVE_RHOMBUS,
        PerimeterKind.RHOMBUS, GATEWAY_PERIMETER);
      let rect: NodeRect = new NodeRect(0, 0, 100, 100);
      // From center to top-left (45°)
      let r = PerimeterRouter.intersect(def, rect, 0, 0, 50, 50);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(25, 5);
        expect(r.y).assertClose(25, 5);
      }
    });

    // ── Edge cases ──

    it('should_handle_ray_from_center', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('test', ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, TASK_PERIMETER, 0.133);
      let rect: NodeRect = new NodeRect(0, 0, 100, 100);
      // Ray origin at center, direction zero (from=to)
      let r = PerimeterRouter.intersect(def, rect, 50, 50, 50, 50);
      expect(r !== null).assertTrue();
      if (r !== null) {
        // Degenerate case: return center
        expect(r.x).assertClose(50, 1);
        expect(r.y).assertClose(50, 1);
      }
    });

    it('should_handle_narrow_rectangle', 0, () => {
      let def: ShapeDefinition = new ShapeDefinition('test', ShapeRenderKind.POLYLINE,
        PerimeterKind.RECT, TASK_PERIMETER, 0.133);
      let rect: NodeRect = new NodeRect(0, 0, 10, 200);
      let r = PerimeterRouter.intersect(def, rect, 100, 100, 5, 100);
      expect(r !== null).assertTrue();
      if (r !== null) {
        expect(r.x).assertClose(10, 1);  // right edge
        expect(r.y).assertClose(100, 2);
      }
    });

  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
# PerimeterRouter doesn't exist yet
```

Expected: compilation error.

- [ ] **Step 3: Write PerimeterRouter.ets**

```typescript
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
  ): { x: number, y: number } | null {
    let cx: number = nodeRect.x + nodeRect.w / 2;
    let cy: number = nodeRect.y + nodeRect.h / 2;

    // Ray direction from center toward the external point
    let dx: number = fromX - cx;
    let dy: number = fromY - cy;

    if (dx === 0 && dy === 0) {
      return { x: cx, y: cy };
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
                                 dx: number, dy: number): { x: number, y: number } {
    if (dx === 0) {
      return { x: cx, y: cy + (dy > 0 ? hh : -hh) };
    }
    if (dy === 0) {
      return { x: cx + (dx > 0 ? hw : -hw), y: cy };
    }
    let scaleX: number = hw / Math.abs(dx);
    let scaleY: number = hh / Math.abs(dy);
    let scale: number = scaleX < scaleY ? scaleX : scaleY;
    return { x: cx + dx * scale, y: cy + dy * scale };
  }

  // ── Ellipse perimeter ─────────────────────────────────────────────────

  private static _ellipseIntersect(cx: number, cy: number, rx: number, ry: number,
                                    dx: number, dy: number): { x: number, y: number } {
    let angle: number = Math.atan2(dy, dx);
    return { x: cx + rx * Math.cos(angle), y: cy + ry * Math.sin(angle) };
  }

  // ── Rhombus perimeter ─────────────────────────────────────────────────

  private static _rhombusIntersect(cx: number, cy: number, hw: number, hh: number,
                                    dx: number, dy: number): { x: number, y: number } {
    if (dx === 0 && dy === 0) {
      return { x: cx, y: cy };
    }
    let t: number = 1 / (Math.abs(dx) / hw + Math.abs(dy) / hh);
    return { x: cx + dx * t, y: cy + dy * t };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

All 8 PerimeterRouter tests pass.

- [ ] **Step 5: Commit**

```bash
git add hmflowkit/src/main/ets/adapter/PerimeterRouter.ets \
        hmflowkit/src/ohosTest/ets/test/PerimeterRouter.test.ets
git commit -m "feat: add PerimeterRouter with exact ellipse/rhombus/rect intersection"
```

---

### Task 4: Create PathRenderer

**Files:**
- Create: `hmflowkit/src/main/ets/renderer/PathRenderer.ets`

**Interfaces:**
- Consumes: `ShapeDefinition`, `ShapeRenderKind` from Task 1
- Produces: `PathRenderer.render(ctx, shapeDef, x, y, w, h, fillColor, strokeColor, strokeWidth, cornerRadiusOverride?)`

**Note:** No separate test file — PathRenderer is a thin Canvas dispatch layer. Tested visually via Phase 2 drawer integration.

- [ ] **Step 1: Write PathRenderer.ets**

```typescript
/**
 * PathRenderer — draws shape outlines from ShapeDefinition perimeter data.
 *
 * Dispatches on renderKind:
 *   NATIVE_ELLIPSE → ctx.ellipse()
 *   NATIVE_RHOMBUS → direct diamond coordinates
 *   POLYLINE       → iterates perimeterPath points, applying arcTo corners
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

  // ── Native ellipse ───────────────────────────────────────────────────

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

  // ── Native rhombus ───────────────────────────────────────────────────

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

  // ── Polyline from perimeterPath ──────────────────────────────────────

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
```

- [ ] **Step 2: Verify compilation**

```bash
# Trigger build via build.sh
echo "1" > .bitfun/build-flag
```

Expected: `PathRenderer.ets` compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add hmflowkit/src/main/ets/renderer/PathRenderer.ets
git commit -m "feat: add PathRenderer for data-driven outline drawing"
```

---

### Task 5: Switch DrawioXmlParser to use PerimeterRouter

**Files:**
- Modify: `hmflowkit/src/main/ets/parser/DrawioXmlParser.ets`

**Interfaces:**
- Consumes: `ShapeDefinition`, `PerimeterRouter` from Tasks 1/3; `ShapeConfig.getShapeDefinition()`

- [ ] **Step 1: Replace _perimeterPoint and related methods**

In `DrawioXmlParser.ets`, replace the `_perimeterPoint`, `_perimeterRect`, `_perimeterEllipse`, `_perimeterRhombus` methods:

```typescript
  // ── Perimeter / routing helpers ──────────────────────────────────────────

  /**
   * Compute the point on a node's perimeter in the direction toward (targetX, targetY).
   * Now delegates to PerimeterRouter for exact continuous-math intersection.
   */
  private static _perimeterPoint(node: GraphNode, targetX: number, targetY: number): _Point {
    let cx: number = node.x + node.width / 2;
    let cy: number = node.y + node.height / 2;
    let dx: number = targetX - cx;
    let dy: number = targetY - cy;

    if (dx === 0 && dy === 0) {
      return new _Point(cx, cy);
    }

    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition(node.type);
    let nodeRect: NodeRect = new NodeRect(node.x, node.y, node.width, node.height);
    let r = PerimeterRouter.intersect(shapeDef, nodeRect, targetX, targetY, cx, cy);
    if (r !== null) {
      return new _Point(r.x, r.y);
    }
    return new _Point(cx, cy);
  }
```

Delete the `_perimeterRect`, `_perimeterEllipse`, `_perimeterRhombus` methods (lines 423-452 in current file).

Add imports at top of file:
```typescript
import { ShapeDefinition } from '../adapter/ShapeDefinition';
import { PerimeterRouter } from '../adapter/PerimeterRouter';
import { NodeRect } from '../renderer/EdgeRenderer';
```

Note: `ShapeConfig` and `PerimeterKind` are already imported.

- [ ] **Step 2: Update _cardinalPerimeter similarly**

Replace the kind-dispatch in `_cardinalPerimeter` to use ShapeDefinition:

```typescript
  private static _cardinalPerimeter(node: GraphNode, targetCx: number,
                                     targetCy: number): _Point {
    let cx: number = node.x + node.width / 2;
    let cy: number = node.y + node.height / 2;
    let dx: number = targetCx - cx;
    let dy: number = targetCy - cy;

    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition(node.type);
    let kind: PerimeterKind = shapeDef.perimeterKind;
    let hw: number = node.width / 2;
    let hh: number = node.height / 2;

    if (kind === PerimeterKind.RHOMBUS || kind === PerimeterKind.ELLIPSE) {
      if (Math.abs(dx) > Math.abs(dy)) {
        return new _Point(cx + (dx > 0 ? hw : -hw), cy);
      } else {
        return new _Point(cx, cy + (dy > 0 ? hh : -hh));
      }
    }

    // Rectangle: snap to nearest side center
    if (Math.abs(dx) > Math.abs(dy)) {
      let sideX: number = dx > 0 ? node.x + node.width : node.x;
      let clampedY: number = cy + dy * Math.min(1, hh / Math.abs(dy));
      if (Math.abs(dy) < 0.01) clampedY = cy;
      if (clampedY < node.y) clampedY = node.y;
      if (clampedY > node.y + node.height) clampedY = node.y + node.height;
      return new _Point(sideX, clampedY);
    } else {
      let sideY: number = dy > 0 ? node.y + node.height : node.y;
      let clampedX: number = cx + dx * Math.min(1, hw / Math.abs(dx));
      if (Math.abs(dx) < 0.01) clampedX = cx;
      if (clampedX < node.x) clampedX = node.x;
      if (clampedX > node.x + node.width) clampedX = node.x + node.width;
      return new _Point(clampedX, sideY);
    }
  }
```

- [ ] **Step 3: Register BPMN shapes in perimeter registry**

Add a one-time initialization call. In `DrawioXmlParser.parse()`, before the parsing loop, call:

```typescript
static _initShapeRegistry(): void {
  if (ShapeConfig.shapeCount() > 0) return; // already initialized
  ShapeConfig.registerShape('bpmn.task2', ShapeRenderKind.POLYLINE,
    PerimeterKind.RECT, TASK_PERIMETER, 0.133);
  ShapeConfig.registerShape('bpmn.event', ShapeRenderKind.NATIVE_ELLIPSE,
    PerimeterKind.ELLIPSE, EVENT_PERIMETER);
  ShapeConfig.registerShape('bpmn.gateway2', ShapeRenderKind.NATIVE_RHOMBUS,
    PerimeterKind.RHOMBUS, GATEWAY_PERIMETER);
}
```

And add import for `ShapeRenderKind` and `PerimeterPoint` from '../adapter/ShapeDefinition'.

- [ ] **Step 4: Verify build**

```bash
echo "1" > .bitfun/build-flag
# Wait for build flag to reset, then check log
cat .bitfun/build-latest.log
```

Expected: HAR + HAP + ohosTest all compile. Existing 19 DrawioXmlParser tests still pass (no behavioral change in test data — perimeter math is identical).

- [ ] **Step 5: Commit**

```bash
git add hmflowkit/src/main/ets/parser/DrawioXmlParser.ets
git commit -m "refactor: switch DrawioXmlParser perimeter routing to PerimeterRouter"
```

---

### Task 6: Refactor TaskDrawer to use PathRenderer

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/TaskDrawer.ets`

**Interfaces:**
- Consumes: `PathRenderer.render()`, `ShapeConfig.getShapeDefinition()`

- [ ] **Step 1: Replace rounded rect outline with PathRenderer call**

In `TaskDrawer.render()`, replace lines 34-49 (the beginPath/moveTo/lineTo/arcTo chain) with:

```typescript
    // Outline via PathRenderer
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition('bpmn.task2');
    let subFill: string = config.taskFillColor;
    let subStroke: string = config.taskStrokeColor;

    if (subtype !== undefined) {
      let c: string | undefined = config.taskSubtypeStroke[subtype];
      if (c !== undefined) {
        subStroke = c;
      }
    }

    // Transaction double-line border uses no fill, thick stroke
    let bpmnShapeType: string | undefined = node.properties['bpmnShapeType'];
    if (bpmnShapeType === 'transaction') {
      PathRenderer.render(ctx, shapeDef, x, y, w, h, 'none', subStroke,
        config.strokeWidth * zoom * 1.8);
      // Inner border
      let inset: number = config.subProcessInset * zoom;
      PathRenderer.render(ctx, shapeDef,
        x + inset, y + inset, w - inset * 2, h - inset * 2,
        'none', subStroke, config.strokeWidth * zoom);
    } else {
      PathRenderer.render(ctx, shapeDef, x, y, w, h, subFill, subStroke,
        config.strokeWidth * zoom);
    }
```

Remove the old outline code (lines 34-49, the beginPath through closePath/fill/stroke block).

Keep all remaining code: color selection by subtype, task marker drawing, loop marker drawing, AdHoc marker, label rendering — all intact.

Add import:
```typescript
import { ShapeDefinition } from '../adapter/ShapeDefinition';
import { PathRenderer } from './PathRenderer';
import { ShapeConfig } from '../adapter/ShapeConfig';
```

- [ ] **Step 2: Verify visual output**

Compare Task rendering in kitchen-sink.bpmn and drawio-bpmn20-Task-full.drawio with previous version. No visual difference expected.

- [ ] **Step 3: Commit**

```bash
git add hmflowkit/src/main/ets/renderer/TaskDrawer.ets
git commit -m "refactor: TaskDrawer outline to PathRenderer"
```

---

### Task 7: Refactor GatewayDrawer to use PathRenderer

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/GatewayDrawer.ets`

- [ ] **Step 1: Replace diamond outline with PathRenderer**

Replace the diamond path block (beginPath through closePath/fill/stroke) with:

```typescript
    // Diamond outline via PathRenderer
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition('bpmn.gateway2');
    PathRenderer.render(ctx, shapeDef, x, y, w, h,
      config.gatewayFillColor, config.gatewayStrokeColor,
      config.strokeWidth * zoom);
```

Keep all gateway marker drawing code intact. Add imports as in Task 6.

- [ ] **Step 2: Verify, commit**

```bash
git add hmflowkit/src/main/ets/renderer/GatewayDrawer.ets
git commit -m "refactor: GatewayDrawer outline to PathRenderer"
```

---

### Task 8: Refactor EventDrawer to use PathRenderer

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/EventDrawer.ets`

- [ ] **Step 1: Replace ellipse outline with PathRenderer**

The EventDrawer is complex — it draws 1-2 concentric circles depending on event type (start/intermediate/end/boundary) and properties (cancelActivity, isInterrupting, interruptType). Replace only the outermost circle drawing:

```typescript
    // Outer circle outline via PathRenderer
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition('bpmn.event');
    PathRenderer.render(ctx, shapeDef, x, y, w, h, fill, stroke, lineW * zoom);
```

If a dashed outline is needed, set `ctx.setLineDash()` before the PathRenderer call and reset after. Keep all inner-ring logic (boundary event second circle) and symbol icon drawing intact.

Add imports as in Task 6.

- [ ] **Step 2: Verify, commit**

```bash
git add hmflowkit/src/main/ets/renderer/EventDrawer.ets
git commit -m "refactor: EventDrawer outline to PathRenderer"
```

---

### Task 9: Refactor SubProcessDrawer to use PathRenderer

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/SubProcessDrawer.ets`

- [ ] **Step 1: Replace rounded rect with PathRenderer call**

Replace the rounded rect path drawing and fill/stroke with:

```typescript
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition('bpmn.task2');
    PathRenderer.render(ctx, shapeDef, x, y, w, h,
      config.taskFillColor, config.taskStrokeColor,
      config.strokeWidth * zoom);
```

Keep expanded/collapsed logic, transaction double-border (use same inset approach as TaskDrawer), expand marker, and label rendering intact.

Add imports as in Task 6.

- [ ] **Step 2: Verify, commit**

```bash
git add hmflowkit/src/main/ets/renderer/SubProcessDrawer.ets
git commit -m "refactor: SubProcessDrawer outline to PathRenderer"
```

---

### Task 10: Refactor DataDrawer to use PathRenderer

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/DataDrawer.ets`

- [ ] **Step 1: Replace outline logic**

DataDrawer has two shapes: DATA_OBJECT (folded corner rect) and DATA_STORE (cylinder). For DATA_OBJECT, the folded corner is currently drawn as a polygon. Replace the polygon path with a POLYLINE shape through ShapeDefinition. For the DATA_STORE cylinder, keep the current specialized drawing (no equivalent in our 3 canon shapes).

Register a simple DATA_OBJECT definition inline or reuse TASK_PERIMETER with no rounding:

```typescript
    // DATA_OBJECT outline
    // Reuse task perimeter but square (no rounding) — close enough for visual
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition('bpmn.task2');
    // Override corner radius to 0 for sharp data-object fold
    PathRenderer.render(ctx, shapeDef, x, y, w, h,
      config.fillColor, config.strokeColor,
      config.strokeWidth * zoom, 0);

    // Fold crease lines (keep existing fold line drawing)
    let fold: number = config.dataObjectFoldSize * zoom;
    ctx.beginPath();
    ctx.moveTo(x + w - fold, y);
    ctx.lineTo(x + w - fold, y + fold);
    ctx.lineTo(x + w, y + fold);
    ctx.stroke();
```

Keep DATA_STORE rendering unchanged.

Add imports as in Task 6.

- [ ] **Step 2: Verify, commit**

```bash
git add hmflowkit/src/main/ets/renderer/DataDrawer.ets
git commit -m "refactor: DataDrawer outline to PathRenderer"
```

---

### Task 11: Refactor AnnotationDrawer to use PathRenderer

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/AnnotationDrawer.ets`

- [ ] **Step 1: The AnnotationDrawer has no fill/stroke outline — it only draws a left bracket. PathRenderer doesn't apply here. Skip this drawer for now (no change needed).**

- [ ] **Step 2: Commit an empty marker**

No changes. Mark as complete.

---

### Task 12: Extract shared sanitizeLabel utility

**Files:**
- Create: `hmflowkit/src/main/ets/renderer/TextUtils.ets`
- Modify: `hmflowkit/src/main/ets/renderer/TaskDrawer.ets`, `EventDrawer.ets`, `GatewayDrawer.ets`, `SubProcessDrawer.ets`, `DataDrawer.ets`

- [ ] **Step 1: Create TextUtils.ets**

```typescript
/**
 * TextUtils — shared text helpers for Drawers.
 */

export function sanitizeLabel(text: string): string {
  if (text.length === 0) {
    return text;
  }
  let result: string = '';
  for (let i: number = 0; i < text.length; i++) {
    let code: number = text.charCodeAt(i);
    if (code === 0x201C || code === 0x201D || code === 0x201E || code === 0x201F) {
      result += '"';
    } else if (code === 0x2018 || code === 0x2019 || code === 0x201A || code === 0x201B) {
      result += "'";
    } else if (code === 0x2013 || code === 0x2014) {
      result += '-';
    } else if (code >= 32 && code <= 126) {
      result += text.charAt(i);
    }
  }
  return result;
}
```

- [ ] **Step 2: Replace sanitizeLabel in all 5 Drawers**

In each of TaskDrawer, EventDrawer, GatewayDrawer, SubProcessDrawer, DataDrawer:
- Remove the local `sanitizeLabel` function
- Add import: `import { sanitizeLabel } from './TextUtils';`

- [ ] **Step 3: Verify build and commit**

```bash
git add hmflowkit/src/main/ets/renderer/TextUtils.ets \
        hmflowkit/src/main/ets/renderer/TaskDrawer.ets \
        hmflowkit/src/main/ets/renderer/EventDrawer.ets \
        hmflowkit/src/main/ets/renderer/GatewayDrawer.ets \
        hmflowkit/src/main/ets/renderer/SubProcessDrawer.ets \
        hmflowkit/src/main/ets/renderer/DataDrawer.ets
git commit -m "refactor: extract shared sanitizeLabel to TextUtils"
```

---

### Task 13: Update DrawioNodeDrawer to use PathRenderer for BPMN shapes

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/DrawioNodeDrawer.ets`

- [ ] **Step 1: Route BPMN-mapped drawio shapes through PathRenderer**

In `DrawioNodeDrawer.render()`, check if the shape has a registered ShapeDefinition and delegate:

```typescript
  render(
    ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
    x: number, y: number, w: number, h: number, zoom: number
  ): void {
    let shape: string = this._extractShape(node.type);
    let shapeDef: ShapeDefinition = ShapeConfig.getShapeDefinition(node.type);

    // If this drawio shape maps to a registered BPMN shape, use PathRenderer
    if (shapeDef.shapeId !== '_default') {
      let fill: string = DrawioNodeDrawer._resolveColor(
        node.properties['_fillColor'], config.fillColor);
      let stroke: string = DrawioNodeDrawer._resolveColor(
        node.properties['_strokeColor'], config.strokeColor);
      let lineW: number = config.strokeWidth * zoom;
      let dashed: boolean = node.properties['_dashed'] === '1';
      let opacity: number = parseInt(node.properties['_opacity'] || '100') / 100;

      ctx.globalAlpha = opacity;
      if (dashed) {
        let dp: number[] = DrawioNodeDrawer._parseDash(node, zoom);
        ctx.setLineDash(dp);
      }
      PathRenderer.render(ctx, shapeDef, x, y, w, h, fill, stroke, lineW);
      ctx.setLineDash([]);
      ctx.globalAlpha = 1.0;
      this._renderLabel(ctx, node, config, x, y, w, h, zoom);
      return;
    }

    // Fall through to existing shape switch for non-BPMN shapes
    // ... (keep existing code)
```

Add imports:
```typescript
import { ShapeDefinition } from '../adapter/ShapeDefinition';
import { ShapeConfig } from '../adapter/ShapeConfig';
import { PathRenderer } from './PathRenderer';
```

- [ ] **Step 2: Add _parseDash helper**

```typescript
  private static _parseDash(node: GraphNode, zoom: number): number[] {
    let dpStr: string = node.properties['_dashPattern'] || '6 4';
    let dpParts: string[] = dpStr.split(' ');
    let dp: number[] = [];
    for (let i: number = 0; i < dpParts.length; i++) {
      let v: number = parseInt(dpParts[i]);
      if (!isNaN(v)) {
        dp.push(v * zoom);
      }
    }
    if (dp.length === 0) {
      dp = [6 * zoom, 4 * zoom];
    }
    return dp;
  }
```

- [ ] **Step 3: Verify, commit**

```bash
git add hmflowkit/src/main/ets/renderer/DrawioNodeDrawer.ets
git commit -m "refactor: route DrawioNodeDrawer BPMN shapes through PathRenderer"
```

---

### Task 14: Final verification — full test suite

- [ ] **Step 1: Trigger full build**

```bash
echo "1" > .bitfun/build-flag
until [ "$(cat .bitfun/build-flag 2>/dev/null)" = "0" ]; do sleep 2; done
cat .bitfun/build-latest.log
```

Expected: HAR + HAP + ohosTest all compile. All 216 tests pass (186 existing + 30 new).

- [ ] **Step 2: Verify build log for any unexpected warnings**

Check for any import errors, unused variable warnings, or type mismatches.

- [ ] **Step 3: Commit final status**

```bash
git add -A
git commit -m "chore: final verification — all 216 tests compile"
```

---

## Task Summary

| # | Task | New Files | Modified Files |
|---|------|-----------|---------------|
| 1 | ShapeDefinition module | 2 | 0 |
| 2 | ShapeConfig registry | 0 | 2 |
| 3 | PerimeterRouter | 2 | 0 |
| 4 | PathRenderer | 1 | 0 |
| 5 | DrawioXmlParser switch | 0 | 1 |
| 6 | TaskDrawer refactor | 0 | 1 |
| 7 | GatewayDrawer refactor | 0 | 1 |
| 8 | EventDrawer refactor | 0 | 1 |
| 9 | SubProcessDrawer refactor | 0 | 1 |
| 10 | DataDrawer refactor | 0 | 1 |
| 11 | AnnotationDrawer (no-op) | 0 | 0 |
| 12 | Extract sanitizeLabel | 1 | 5 |
| 13 | DrawioNodeDrawer update | 0 | 1 |
| 14 | Final verification | 0 | 0 |
| **Total** | | **6 new** | **14 modified** |
