// hmflowkit/src/main/ets/approval/FlowableHistoryAdapter.ets
import { IApprovalAdapter } from './IApprovalAdapter';
import { NodeStatusMap, NodeStatus, EdgeTrail } from './ApprovalTypes';
import { GraphModel } from '../model/GraphModel';

export interface FlowableActivity {
  activityId: string;
  activityName?: string;
  activityType: string;
  assignee?: string;
  startTime?: string;
  endTime?: string;
  deleteReason?: string;
  taskId?: string;
}

export class FlowableHistoryAdapter implements IApprovalAdapter {

  buildNodeStatuses(rawData: string, model: GraphModel): NodeStatusMap {
    let map: NodeStatusMap = new NodeStatusMap();
    let activities: FlowableActivity[] = [];
    try {
      let parsed: object = JSON.parse(rawData);
      if (Array.isArray(parsed) && parsed.length > 0) {
        let arr: object[] = parsed as object[];
        for (let k: number = 0; k < arr.length; k++) {
          activities.push(arr[k] as FlowableActivity);
        }
      }
    } catch (_e) {
      return map;
    }

    for (let i: number = 0; i < activities.length; i++) {
      let act: FlowableActivity = activities[i];
      if (act.activityId === undefined || act.activityId.length === 0) {
        continue;
      }
      let status: string = this._mapStatus(act);
      let s: NodeStatus = new NodeStatus(
        act.activityId,
        status as 'approved' | 'rejected' | 'current' | 'skipped' | 'transferred',
        act.assignee || '',
        '',
        act.endTime ? new Date(act.endTime).getTime() : 0,
        '',
        act.deleteReason || ''
      );
      map.set(act.activityId, s);
    }
    return map;
  }

  buildEdgeTrails(rawData: string, model: GraphModel): EdgeTrail[] {
    let trails: EdgeTrail[] = [];
    let activities: FlowableActivity[] = [];
    try {
      let parsed: object = JSON.parse(rawData);
      if (Array.isArray(parsed) && parsed.length > 0) {
        let arr: object[] = parsed as object[];
        for (let k: number = 0; k < arr.length; k++) {
          activities.push(arr[k] as FlowableActivity);
        }
      }
    } catch (_e) {
      return trails;
    }

    // 按 startTime 排序活动
    let sorted: FlowableActivity[] = [];
    for (let i: number = 0; i < activities.length; i++) {
      let act: FlowableActivity = activities[i];
      if (act.startTime !== undefined && act.activityId.length > 0) {
        sorted.push(act);
      }
    }
    sorted.sort((a: FlowableActivity, b: FlowableActivity): number => {
      let ta: number = a.startTime ? new Date(a.startTime).getTime() : 0;
      let tb: number = b.startTime ? new Date(b.startTime).getTime() : 0;
      return ta - tb;
    });

    // 相邻活动对 → edge trail
    for (let i: number = 0; i < sorted.length - 1; i++) {
      let src: FlowableActivity = sorted[i];
      let tgt: FlowableActivity = sorted[i + 1];
      // 找到连接 src.activityId → tgt.activityId 的边
      let edges = model.getEdges();
      let matchedEdgeId: string = '';
      for (let j: number = 0; j < edges.length; j++) {
        if (edges[j].sourceId === src.activityId &&
            edges[j].targetId === tgt.activityId) {
          matchedEdgeId = edges[j].id;
          break;
        }
      }
      if (matchedEdgeId.length === 0) {
        continue;
      }
      let kind: 'active' | 'historical' | 'rejected' | 'skipped' = 'historical';
      if (tgt.deleteReason === 'rejected') {
        kind = 'rejected';
      } else if (tgt.endTime && !tgt.deleteReason) {
        kind = 'active';
      }
      let label: string = '';
      if (tgt.deleteReason === 'rejected') {
        label = '驳回';
      }
      trails.push(new EdgeTrail(matchedEdgeId, kind, label,
        tgt.endTime ? new Date(tgt.endTime).getTime() : 0));
    }
    return trails;
  }

  private _mapStatus(act: FlowableActivity): string {
    if (!act.endTime) {
      return 'current';
    }
    if (act.deleteReason === 'rejected') {
      return 'rejected';
    }
    if (act.deleteReason === 'deleted') {
      return 'skipped';
    }
    if (act.deleteReason === 'transferred') {
      return 'transferred';
    }
    return 'approved';
  }
}
