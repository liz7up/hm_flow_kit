// hmflowkit/src/main/ets/approval/ApprovalTypes.ets

import { GraphNode } from '../model/GraphModel'

// ═══ 审批状态枚举 ═══
export type ApprovalStatus = 'pending' | 'approved' | 'rejected'
  | 'current' | 'skipped' | 'transferred';

// ═══ 会签/多实例子状态 ═══
export class MultiInstanceStatus {
  totalCount: number;
  completedCount: number;
  children: NodeStatus[];

  constructor(totalCount: number, completedCount: number,
              children: NodeStatus[]) {
    this.totalCount = totalCount;
    this.completedCount = completedCount;
    this.children = children;
  }
}

// ═══ 单节点审批状态 ═══
export class NodeStatus {
  nodeId: string;
  status: ApprovalStatus;
  operator: string;
  operatorAvatar: string;
  timestamp: number;
  comment: string;
  result: string;
  multiInstance: MultiInstanceStatus | null;

  constructor(
    nodeId: string,
    status: ApprovalStatus,
    operator?: string,
    operatorAvatar?: string,
    timestamp?: number,
    comment?: string,
    result?: string
  ) {
    this.nodeId = nodeId;
    this.status = status;
    this.operator = operator !== undefined ? operator : '';
    this.operatorAvatar = operatorAvatar !== undefined ? operatorAvatar : '';
    this.timestamp = timestamp !== undefined ? timestamp : 0;
    this.comment = comment !== undefined ? comment : '';
    this.result = result !== undefined ? result : '';
    this.multiInstance = null;
  }

  withMultiInstance(total: number, completed: number,
                    children: NodeStatus[]): NodeStatus {
    this.multiInstance = new MultiInstanceStatus(total, completed, children);
    return this;
  }
}

// ═══ 流转路径 ═══
export type EdgeTrailKind = 'active' | 'rejected' | 'historical' | 'skipped';

export class EdgeTrail {
  edgeId: string;
  kind: EdgeTrailKind;
  label: string;
  timestamp: number;
  operator: string;

  constructor(edgeId: string, kind: EdgeTrailKind, label?: string,
              timestamp?: number, operator?: string) {
    this.edgeId = edgeId;
    this.kind = kind;
    this.label = label !== undefined ? label : '';
    this.timestamp = timestamp !== undefined ? timestamp : 0;
    this.operator = operator !== undefined ? operator : '';
  }
}

// ═══ 状态配色 ═══
export class StatusColor {
  fillColor: string;
  strokeColor: string;
  strokeWidth: number;
  badgeText: string;

  constructor(fillColor: string, strokeColor: string,
              strokeWidth?: number, badgeText?: string) {
    this.fillColor = fillColor;
    this.strokeColor = strokeColor;
    this.strokeWidth = strokeWidth !== undefined ? strokeWidth : 0;
    this.badgeText = badgeText !== undefined ? badgeText : '';
  }
}

// ═══ 覆盖层配置 ═══
export type BadgePosition = 'topRight' | 'topLeft' | 'bottomRight';

export class ApprovalStatusColorMap {
  approved: StatusColor | null;
  rejected: StatusColor | null;
  current: StatusColor | null;
  skipped: StatusColor | null;
  transferred: StatusColor | null;
  pending: StatusColor | null;

  constructor() {
    this.approved = null;
    this.rejected = null;
    this.current = null;
    this.skipped = null;
    this.transferred = null;
    this.pending = null;
  }

  getByStatus(status: ApprovalStatus): StatusColor | null {
    if (status === 'approved') return this.approved;
    if (status === 'rejected') return this.rejected;
    if (status === 'current') return this.current;
    if (status === 'skipped') return this.skipped;
    if (status === 'transferred') return this.transferred;
    if (status === 'pending') return this.pending;
    return null;
  }
}

export class ApprovalOverlayConfig {
  statusColors: ApprovalStatusColorMap;
  pulseCurrentNode: boolean;
  pulseDuration: number;
  badgePosition: BadgePosition;
  infoPanelEnabled: boolean;

  constructor() {
    this.statusColors = new ApprovalStatusColorMap();
    this.pulseCurrentNode = true;
    this.pulseDuration = 800;
    this.badgePosition = 'topRight';
    this.infoPanelEnabled = true;
  }
}

// ═══ 节点状态表条目 (ArkTS 禁止 inline object literal types) ═══
export class NodeStatusEntry {
  nodeId: string;
  status: NodeStatus;

  constructor(nodeId: string, status: NodeStatus) {
    this.nodeId = nodeId;
    this.status = status;
  }
}

// ═══ 节点状态表容器 (替代 Partial<Record<...>>) ═══
export class NodeStatusMap {
  _map: Record<string, NodeStatus>;

  constructor() {
    this._map = {};
  }

  get(nodeId: string): NodeStatus | null {
    let v: NodeStatus | undefined = this._map[nodeId];
    return v !== undefined ? v : null;
  }

  set(nodeId: string, status: NodeStatus): void {
    this._map[nodeId] = status;
  }

  has(nodeId: string): boolean {
    return this._map[nodeId] !== undefined;
  }

  keys(): string[] {
    return Object.keys(this._map);
  }

  entries(): NodeStatusEntry[] {
    let result: NodeStatusEntry[] = [];
    let ks: string[] = Object.keys(this._map);
    for (let i: number = 0; i < ks.length; i++) {
      result.push(new NodeStatusEntry(ks[i], this._map[ks[i]]));
    }
    return result;
  }

  // ArkTS 禁止 Record<K,V> 参数类型, 改用 object + 内部转换
  static fromRecord(record: object): NodeStatusMap {
    let map: NodeStatusMap = new NodeStatusMap();
    let r: Record<string, NodeStatus> = record as Record<string, NodeStatus>;
    let keys: string[] = Object.keys(r);
    for (let i: number = 0; i < keys.length; i++) {
      map._map[keys[i]] = r[keys[i]];
    }
    return map;
  }
}

// ═══ 节点装饰器类型 ═══
export class NodeDrawRect {
  x: number;
  y: number;
  width: number;
  height: number;

  constructor(x: number, y: number, width: number, height: number) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
}

export type OnNodeDecorator = (
  node: GraphNode,
  status: NodeStatus | null,
  ctx: CanvasRenderingContext2D,
  rect: NodeDrawRect,
  zoom: number
) => void;
