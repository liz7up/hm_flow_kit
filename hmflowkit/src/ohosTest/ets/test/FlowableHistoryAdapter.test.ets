// hmflowkit/src/ohosTest/ets/test/FlowableHistoryAdapter.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { FlowableHistoryAdapter } from '../../../main/ets/approval/FlowableHistoryAdapter';
import { NodeStatusMap, NodeStatus } from '../../../main/ets/approval/ApprovalTypes';
import { GraphModel } from '../../../main/ets/model/GraphModel';

export default function flowableHistoryAdapterTest() {
  describe('FlowableHistoryAdapter', () => {
    it('buildNodeStatuses_empty_json', 0, () => {
      let adapter: FlowableHistoryAdapter = new FlowableHistoryAdapter();
      let model: GraphModel = GraphModel.createEmpty();
      let map: NodeStatusMap = adapter.buildNodeStatuses('[]', model);
      expect(map.entries().length).assertEqual(0);
    });

    it('buildNodeStatuses_approved_activity', 0, () => {
      let adapter: FlowableHistoryAdapter = new FlowableHistoryAdapter();
      let model: GraphModel = GraphModel.createEmpty();
      let json: string = JSON.stringify([
        { activityId: 'Activity_1', activityType: 'userTask',
          assignee: '张三', endTime: '2026-06-28T14:30:00Z' }
      ]);
      let map: NodeStatusMap = adapter.buildNodeStatuses(json, model);
      let s: NodeStatus | null = map.get('Activity_1');
      expect(s !== null).assertTrue();
      if (s !== null) {
        expect(s.status).assertEqual('approved');
        expect(s.operator).assertEqual('张三');
      }
    });

    it('buildNodeStatuses_current_activity', 0, () => {
      let adapter: FlowableHistoryAdapter = new FlowableHistoryAdapter();
      let model: GraphModel = GraphModel.createEmpty();
      let json: string = JSON.stringify([
        { activityId: 'Activity_2', activityType: 'userTask',
          assignee: '李四' }
      ]);
      let map: NodeStatusMap = adapter.buildNodeStatuses(json, model);
      let s: NodeStatus | null = map.get('Activity_2');
      expect(s !== null).assertTrue();
      if (s !== null) {
        expect(s.status).assertEqual('current');
      }
    });

    it('buildNodeStatuses_rejected_activity', 0, () => {
      let adapter: FlowableHistoryAdapter = new FlowableHistoryAdapter();
      let model: GraphModel = GraphModel.createEmpty();
      let json: string = JSON.stringify([
        { activityId: 'Activity_3', activityType: 'userTask',
          endTime: '2026-06-28T14:30:00Z', deleteReason: 'rejected' }
      ]);
      let map: NodeStatusMap = adapter.buildNodeStatuses(json, model);
      let s: NodeStatus | null = map.get('Activity_3');
      expect(s !== null).assertTrue();
      if (s !== null) {
        expect(s.status).assertEqual('rejected');
      }
    });

    it('buildNodeStatuses_invalid_json', 0, () => {
      let adapter: FlowableHistoryAdapter = new FlowableHistoryAdapter();
      let model: GraphModel = GraphModel.createEmpty();
      let map: NodeStatusMap = adapter.buildNodeStatuses('not json', model);
      expect(map.entries().length).assertEqual(0);
    });

    it('buildEdgeTrails_empty_json', 0, () => {
      let adapter: FlowableHistoryAdapter = new FlowableHistoryAdapter();
      let model: GraphModel = GraphModel.createEmpty();
      let trails = adapter.buildEdgeTrails('[]', model);
      expect(trails.length).assertEqual(0);
    });
  });
}
