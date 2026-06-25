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
