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
  // ═══ Node metrics ═══
  cornerRadiusRatio: number = 0.133;    // r = min(w,h) * ratio (replaces cornerRadius=8)
  nodePadding: number = 4;

  // ═══ Task markers ═══
  taskIconSize: number = 12;
  taskIconOffset: number = 4;
  loopMarkerSize: number = 5;
  loopMarkerSpacing: number = 4;
  loopMarkerOffset: number = 5;

  // ═══ CallActivity ═══
  callActivityBorderRatio: number = 2.5;
  callActivityMarkerSize: number = 5;
  callActivityMarkerOffset: number = 10;

  // ═══ Event ═══
  eventIconScale: number = 0.55;
  eventLabelGap: number = 4;
  eventInnerRingScale: number = 0.82;

  // ═══ SubProcess ═══
  subProcessInset: number = 3;
  subProcessExpandMarkerSize: number = 12;
  subProcessDashPattern: number[] = [6, 3];

  // ═══ Gateway markers ═══
  gatewayMarkerScale: Record<string, number> = {
    'exclusiveGateway': 0.16, 'parallelGateway': 0.28,
    'inclusiveGateway': 0.28, 'complexGateway': 0.42, 'eventBasedGateway': 0.42
  };

  // ═══ Data ═══
  dataObjectFoldSize: number = 12;

  // ═══ Annotation ═══
  annotationBracketWidth: number = 8;
  annotationFontScale: number = 1.4;

  // ═══ Edge ═══
  edgeLabelOffset: number = 12;
  edgeLabelPadding: number = 3;

  // ═══ HitTest ═══
  edgeHitTolerance: number = 12;

  // ═══ Viewport ═══
  fitToViewPadding: number = 40;
  fitToViewMinZoom: number = 0.1;
  fitToViewMaxZoom: number = 3.0;
  renderThrottleMs: number = 16;

  // ═══ Highlight ═══
  highlightColor: string = 'rgba(24, 144, 255, 0.35)';
  highlightPadding: number = 4;

  // ═══ Font ═══
  fontSizeMin: number = 12;

  // ═══ Layer order ═══
  layerPriorities: Record<string, number> = {
    'poolLane': 0,
    'subProcess': 1,
    'dataObject': 2, 'dataStore': 2, 'textAnnotation': 2,
    'edge': 3,
    'task': 4, 'callActivity': 4, 'gateway': 4,
    'eventBasedGateway': 4, 'complexGateway': 4,
    'startEvent': 5, 'endEvent': 5, 'intermediateEvent': 5,
    'boundaryEvent': 6
  };
  defaultLayerPriority: number = 3;

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

  // ── Pool/Lane 泳道样式 ──
  poolFillColor: string = '#FAFAFA';
  poolStrokeColor: string = '#BDBDBD';
  poolStrokeWidth: number = 2;
  poolHeaderWidth: number = 30;
  poolHeaderFillColor: string = '#E0E0E0';
  poolHeaderTextColor: string = '#424242';
  poolHeaderFontSize: number = 12;

  laneFillColor: string = '#F5F5F5';
  laneStrokeColor: string = '#E0E0E0';
  laneStrokeWidth: number = 1;
  laneHeaderWidth: number = 20;
  laneHeaderIndent: number = 6;
  laneHeaderFillColor: string = '#EEEEEE';
  laneHeaderTextColor: string = '#616161';
  laneHeaderFontSize: number = 11;

  // ── 连线样式 ──
  edgeStrokeColor: string = '#5E5E5E';
  edgeStrokeWidth: number = 1.5;
  arrowSize: number = 12;

  // ── MessageFlow 样式 ──
  messageFlowStrokeColor: string = '#5E5E5E';
  messageFlowStrokeWidth: number = 1.2;
  messageFlowDashPattern: number[] = [6, 4];

  // ── 标记/图标样式 ──
  gatewayMarkerColor: string = '#333333';
  eventIconColor: string = '#333333';

  // ── 网格样式 ──
  gridSize: number = 20;
  gridColor: string = '#E8E8E8';

  constructor() {
  }
}