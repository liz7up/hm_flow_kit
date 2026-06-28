// hmflowkit/src/main/ets/approval/ApprovalPresets.ets
import { StatusColor, ApprovalStatusColorMap } from './ApprovalTypes';

export type PresetId = 'CLASSIC' | 'GOVERNMENT' | 'DARK';

// ArkTS 不允许 Record<K,V> 或匿名对象字面量作为类型,
// 因此用显式接口定义预设集结构
export interface IApprovalColorPresets {
  CLASSIC: ApprovalStatusColorMap;
  GOVERNMENT: ApprovalStatusColorMap;
  DARK: ApprovalStatusColorMap;
}

export const ApprovalColorPresets: IApprovalColorPresets = {
  CLASSIC: buildPreset(
    new StatusColor('#E8F5E9', '#4CAF50', 0, '\u2713'),
    new StatusColor('#FFEBEE', '#F44336', 0, '\u2717'),
    new StatusColor('#E3F2FD', '#2196F3', 0, '\u25CF'),
    new StatusColor('#F5F5F5', '#9E9E9E', 0, '\u2014'),
    new StatusColor('#FFF3E0', '#FF9800', 0, '\u2197'),
    new StatusColor('#FFFFFF', '#BDBDBD', 0, '')
  ),
  GOVERNMENT: buildPreset(
    new StatusColor('#F0F4FF', '#1565C0', 0, '\u5DF2\u6279'),
    new StatusColor('#FFF0F0', '#C62828', 0, '\u9A73\u56DE'),
    new StatusColor('#FFF8E1', '#F57F17', 0, '\u5BA1\u6279\u4E2D'),
    new StatusColor('#F5F5F5', '#BDBDBD', 0, '\u8DF3\u8FC7'),
    new StatusColor('#F3E5F5', '#7B1FA2', 0, '\u8F6C\u529E'),
    new StatusColor('#FFFFFF', '#BDBDBD', 0, '')
  ),
  DARK: buildPreset(
    new StatusColor('#1B3A1B', '#4CAF50', 0, '\u2713'),
    new StatusColor('#3A1B1B', '#F44336', 0, '\u2717'),
    new StatusColor('#1B2A3A', '#2196F3', 0, '\u25CF'),
    new StatusColor('#2A2A2A', '#666666', 0, '\u2014'),
    new StatusColor('#3A2A1B', '#FF9800', 0, '\u2197'),
    new StatusColor('#1E1E1E', '#555555', 0, '')
  ),
};

function buildPreset(
  approved: StatusColor,
  rejected: StatusColor,
  current: StatusColor,
  skipped: StatusColor,
  transferred: StatusColor,
  pending: StatusColor
): ApprovalStatusColorMap {
  let map: ApprovalStatusColorMap = new ApprovalStatusColorMap();
  map.approved = approved;
  map.rejected = rejected;
  map.current = current;
  map.skipped = skipped;
  map.transferred = transferred;
  map.pending = pending;
  return map;
}
