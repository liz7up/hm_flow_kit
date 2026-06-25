import { describe, it, expect } from '@ohos/hypium';
import {
  PerimeterPoint,
  ShapeRenderKind,
  ShapeDefinition,
  TASK_PERIMETER,
  EVENT_PERIMETER,
  GATEWAY_PERIMETER
} from '../../../main/ets/adapter/ShapeDefinition';
import { PerimeterKind, ShapeConfig } from '../../../main/ets/adapter/ShapeConfig';

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

  });
}
