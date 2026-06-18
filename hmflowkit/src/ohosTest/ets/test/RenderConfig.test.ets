import { describe, it, expect } from '@ohos/hypium';
import { RenderConfig } from '../../../main/ets/renderer/RenderConfig';

export default function renderConfigTest(): void {
  describe('RenderConfig', () => {
    it('defaults_should_have_expected_values', 0, () => {
      let c: RenderConfig = new RenderConfig();
      expect(c.nodeWidth).assertEqual(120);
      expect(c.nodeHeight).assertEqual(60);
      expect(c.strokeColor).assertEqual('#333333');
      expect(c.fillColor).assertEqual('#FFFFFF');
    });

    it('task_colors_should_default_neutral', 0, () => {
      let c: RenderConfig = new RenderConfig();
      expect(c.taskFillColor).assertEqual('#FFFFFF');
      expect(c.taskStrokeColor).assertEqual('#616161');
    });

    it('subtype_stroke_map_should_have_expected_keys', 0, () => {
      let c: RenderConfig = new RenderConfig();
      expect(c.taskSubtypeStroke['userTask']).assertEqual('#1976D2');
      expect(c.taskSubtypeStroke['serviceTask']).assertEqual('#00897B');
      expect(c.taskSubtypeStroke['businessRuleTask']).assertEqual('#C62828');
    });

    it('gateway_marker_color_should_default', 0, () => {
      let c: RenderConfig = new RenderConfig();
      expect(c.gatewayMarkerColor).assertEqual('#333333');
    });

    it('event_icon_color_should_default', 0, () => {
      let c: RenderConfig = new RenderConfig();
      expect(c.eventIconColor).assertEqual('#333333');
    });
  });
}
