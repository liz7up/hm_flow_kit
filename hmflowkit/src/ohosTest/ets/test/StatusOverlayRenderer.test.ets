// hmflowkit/src/ohosTest/ets/test/StatusOverlayRenderer.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { StatusOverlayRenderer } from '../../main/ets/approval/StatusOverlayRenderer';
import { StatusColor, ApprovalOverlayConfig, NodeStatusMap, NodeStatus } from '../../main/ets/approval/ApprovalTypes';

export default function statusOverlayRendererTest() {
  describe('StatusOverlayRenderer', () => {
    it('resolveColor_fallback_when_no_config', 0, () => {
      let c: StatusColor = StatusOverlayRenderer.resolveColor('approved', undefined, undefined);
      expect(c.fillColor).assertEqual('#E8F5E9');
      expect(c.badgeText).assertEqual('✓');
    });

    it('resolveColor_preset_override', 0, () => {
      let c: StatusColor = StatusOverlayRenderer.resolveColor('approved', undefined, 'GOVERNMENT');
      expect(c.fillColor).assertEqual('#F0F4FF');
      expect(c.badgeText).assertEqual('已批');
    });

    it('resolveColor_user_config_wins', 0, () => {
      let cfg: ApprovalOverlayConfig = new ApprovalOverlayConfig();
      cfg.statusColors.approved = new StatusColor('#000000', '#FFFFFF', 3, 'OK');
      let c: StatusColor = StatusOverlayRenderer.resolveColor('approved', cfg, 'CLASSIC');
      expect(c.fillColor).assertEqual('#000000');
      expect(c.badgeText).assertEqual('OK');
    });

    it('resolveColor_unknown_status_fallback', 0, () => {
      let c: StatusColor = StatusOverlayRenderer.resolveColor('transferred', undefined, undefined);
      expect(c.fillColor).assertEqual('#FFF3E0');
    });
  });
}
