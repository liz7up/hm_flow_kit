export enum NodeShape {
  RECTANGLE,
  ROUNDED_RECT,
  DIAMOND,
  CIRCLE
}

export class RenderConfig {
  nodeWidth: number = 120;
  nodeHeight: number = 60;
  strokeColor: string = '#333333';
  strokeWidth: number = 2;
  fillColor: string = '#FFFFFF';
  activeStrokeColor: string = '#1890FF';
  activeFillColor: string = '#E6F7FF';
  textColor: string = '#333333';
  fontSize: number = 12;
  fontFamily: string = 'HarmonyOS Sans, sans-serif';
  cornerRadius: number = 8;

  // ── 按 NodeType 分色（优先于通用字段）──

  // Task 节点（白底 + 深灰边框，不抢高亮蓝色）
  taskFillColor: string = '#FFFFFF';
  taskStrokeColor: string = '#616161';
  taskTextColor: string = '#333333';

  // 按 Task 子类型（BPMN 标签名）的边框色
  taskSubtypeStroke: Record<string, string> = {
    'userTask': '#1976D2',
    'serviceTask': '#00897B',
    'scriptTask': '#7B1FA2',
    'manualTask': '#795548',
    'sendTask': '#F57C00',
    'receiveTask': '#3949AB',
    'businessRuleTask': '#C62828',
  };

  // Gateway 节点（浅黄底 + 琥珀边框）
  gatewayFillColor: string = '#FFFDE7';
  gatewayStrokeColor: string = '#FFB300';
  gatewayTextColor: string = '#333333';

  // StartEvent（白底 + 绿边框，细线空心圆）
  eventStartFillColor: string = '#FFFFFF';
  eventStartStrokeColor: string = '#43A047';
  eventStartStrokeWidth: number = 2;

  // EndEvent（深灰实心 + 粗边框）
  eventEndFillColor: string = '#424242';
  eventEndStrokeColor: string = '#424242';
  eventEndStrokeWidth: number = 4;

  // ── 连线样式 ──
  edgeStrokeColor: string = '#5E5E5E';
  edgeStrokeWidth: number = 1.5;
  arrowSize: number = 12;

  // ── 网格样式 ──
  gridSize: number = 20;
  gridColor: string = '#E8E8E8';

  constructor() {
  }
}