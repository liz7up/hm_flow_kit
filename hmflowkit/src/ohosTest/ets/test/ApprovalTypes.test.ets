import { describe, it, expect } from '@ohos/hypium';
import {
  NodeStatus, MultiInstanceStatus, EdgeTrail, EdgeTrailKind,
  StatusColor, ApprovalOverlayConfig, ApprovalStatusColorMap,
  NodeStatusMap, NodeStatusEntry, NodeDrawRect
} from '../../../main/ets/approval/ApprovalTypes';
import { ApprovalColorPresets } from '../../../main/ets/approval/ApprovalPresets';

export default function approvalTypesTest() {
  describe('ApprovalTypes', () => {
    // ── NodeStatus ──
    it('NodeStatus_constructor_defaults', 0, () => {
      let s: NodeStatus = new NodeStatus('n1', 'approved');
      expect(s.nodeId).assertEqual('n1');
      expect(s.status).assertEqual('approved');
      expect(s.operator).assertEqual('');
      expect(s.timestamp).assertEqual(0);
      expect(s.multiInstance).assertNull();
    });

    it('NodeStatus_constructor_all_fields', 0, () => {
      let s: NodeStatus = new NodeStatus('n2', 'rejected', '张三', '', 1719561600000, '材料不全', '驳回至发起人');
      expect(s.operator).assertEqual('张三');
      expect(s.result).assertEqual('驳回至发起人');
      expect(s.comment).assertEqual('材料不全');
    });

    it('NodeStatus_withMultiInstance', 0, () => {
      let child1: NodeStatus = new NodeStatus('child1', 'approved');
      let child2: NodeStatus = new NodeStatus('child2', 'current');
      let s: NodeStatus = new NodeStatus('n3', 'current')
        .withMultiInstance(3, 2, [child1, child2]);
      expect(s.multiInstance !== null).assertTrue();
      if (s.multiInstance !== null) {
        expect(s.multiInstance.totalCount).assertEqual(3);
        expect(s.multiInstance.completedCount).assertEqual(2);
        expect(s.multiInstance.children.length).assertEqual(2);
      }
    });

    // ── MultiInstanceStatus ──
    it('MultiInstanceStatus_constructor', 0, () => {
      let children: NodeStatus[] = [new NodeStatus('c1', 'approved')];
      let mi: MultiInstanceStatus = new MultiInstanceStatus(5, 3, children);
      expect(mi.totalCount).assertEqual(5);
      expect(mi.completedCount).assertEqual(3);
      expect(mi.children.length).assertEqual(1);
    });

    // ── EdgeTrail ──
    it('EdgeTrail_constructor_defaults', 0, () => {
      let t: EdgeTrail = new EdgeTrail('e1', 'active');
      expect(t.edgeId).assertEqual('e1');
      expect(t.label).assertEqual('');
      expect(t.timestamp).assertEqual(0);
    });

    it('EdgeTrail_constructor_all_fields', 0, () => {
      let t: EdgeTrail = new EdgeTrail('e2', 'rejected', '驳回', 1719561600000, '张三');
      expect(t.kind).assertEqual('rejected');
      expect(t.label).assertEqual('驳回');
    });

    // ── StatusColor ──
    it('StatusColor_constructor', 0, () => {
      let c: StatusColor = new StatusColor('#E8F5E9', '#4CAF50');
      expect(c.fillColor).assertEqual('#E8F5E9');
      expect(c.badgeText).assertEqual('');
    });

    it('StatusColor_with_badge', 0, () => {
      let c: StatusColor = new StatusColor('#E8F5E9', '#4CAF50', 2, '\u2713');
      expect(c.strokeWidth).assertEqual(2);
      expect(c.badgeText).assertEqual('\u2713');
    });

    // ── ApprovalOverlayConfig ──
    it('ApprovalOverlayConfig_defaults', 0, () => {
      let c: ApprovalOverlayConfig = new ApprovalOverlayConfig();
      expect(c.pulseCurrentNode).assertTrue();
      expect(c.pulseDuration).assertEqual(800);
      expect(c.badgePosition).assertEqual('topRight');
      expect(c.infoPanelEnabled).assertTrue();
    });

    // ── ApprovalStatusColorMap ──
    it('ApprovalStatusColorMap_getByStatus', 0, () => {
      let map: ApprovalStatusColorMap = new ApprovalStatusColorMap();
      map.approved = new StatusColor('#E8F5E9', '#4CAF50');
      map.rejected = new StatusColor('#FFEBEE', '#F44336');
      let c: StatusColor | null = map.getByStatus('approved');
      expect(c !== null).assertTrue();
      if (c !== null) {
        expect(c.fillColor).assertEqual('#E8F5E9');
      }
    });

    it('ApprovalStatusColorMap_getByStatus_null', 0, () => {
      let map: ApprovalStatusColorMap = new ApprovalStatusColorMap();
      expect(map.getByStatus('pending')).assertNull();
    });

    // ── NodeStatusMap ──
    it('NodeStatusMap_set_and_get', 0, () => {
      let map: NodeStatusMap = new NodeStatusMap();
      map.set('n1', new NodeStatus('n1', 'approved'));
      expect(map.get('n1') !== null).assertTrue();
      expect(map.has('n1')).assertTrue();
      expect(map.has('n2')).assertFalse();
    });

    it('NodeStatusMap_entries', 0, () => {
      let map: NodeStatusMap = new NodeStatusMap();
      map.set('a', new NodeStatus('a', 'approved'));
      map.set('b', new NodeStatus('b', 'rejected'));
      let entries: NodeStatusEntry[] = map.entries();
      expect(entries.length).assertEqual(2);
    });

    it('NodeStatusMap_fromRecord', 0, () => {
      let rec: Record<string, NodeStatus> = {};
      rec['x'] = new NodeStatus('x', 'current');
      rec['y'] = new NodeStatus('y', 'skipped');
      let map: NodeStatusMap = NodeStatusMap.fromRecord(rec);
      expect(map.has('x')).assertTrue();
      expect(map.has('y')).assertTrue();
    });

    // ── NodeDrawRect ──
    it('NodeDrawRect_constructor', 0, () => {
      let r: NodeDrawRect = new NodeDrawRect(10, 20, 100, 50);
      expect(r.x).assertEqual(10);
      expect(r.y).assertEqual(20);
      expect(r.width).assertEqual(100);
      expect(r.height).assertEqual(50);
    });

    // ── Presets ──
    it('Presets_CLASSIC_exists', 0, () => {
      let classic: ApprovalStatusColorMap = ApprovalColorPresets.CLASSIC;
      expect(classic.approved !== null).assertTrue();
      expect(classic.rejected !== null).assertTrue();
      expect(classic.current !== null).assertTrue();
    });

    it('Presets_GOVERNMENT_has_chinese_badges', 0, () => {
      let gov: ApprovalStatusColorMap = ApprovalColorPresets.GOVERNMENT;
      if (gov.approved !== null) {
        expect(gov.approved.badgeText).assertEqual('\u5DF2\u6279');
      }
    });

    it('Presets_DARK_exists', 0, () => {
      let dark: ApprovalStatusColorMap = ApprovalColorPresets.DARK;
      expect(dark.approved !== null).assertTrue();
    });
  });
}
