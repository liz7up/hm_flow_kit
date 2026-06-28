// hmflowkit/src/main/ets/approval/IApprovalAdapter.ets

import { NodeStatusMap, EdgeTrail } from './ApprovalTypes';
import { GraphModel } from '../model/GraphModel';

export interface IApprovalAdapter {
  buildNodeStatuses(rawData: string, model: GraphModel): NodeStatusMap;
  buildEdgeTrails(rawData: string, model: GraphModel): EdgeTrail[];
}
