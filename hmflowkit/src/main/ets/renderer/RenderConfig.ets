export enum NodeShape {
  RECTANGLE,
  ROUNDED_RECT,
  DIAMOND,
  CIRCLE
}

export class RenderConfig {
  nodeWidth: number = 120;
  nodeHeight: number = 60;
  strokeColor: string = '#000000';
  strokeWidth: number = 1.4;
  fillColor: string = '#FFFFFF';
  activeStrokeColor: string = '#000000';
  activeFillColor: string = '#E0E0E0';
  textColor: string = '#000000';
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

  // ═══ HitTest ═══
  edgeHitTolerance: number = 12;

  // ═══ Viewport ═══
  fitToViewPadding: number = 40;
  fitToViewMinZoom: number = 0.1;
  fitToViewMaxZoom: number = 3.0;
  renderThrottleMs: number = 16;

  // ═══ Highlight ═══
  highlightColor: string = '#1890FF';
  highlightPadding: number = 3;
  highlightLineWidth: number = 3;

  // ═══ Font ═══
  fontSizeMin: number = 12;

  // ═══ Layer order ═══
  layerPriorities: Record<string, number> = {
    'poolLane': 0,
    'subProcess': 1,
    'dataObject': 4, 'dataStore': 4, 'textAnnotation': 4,
    'edge': 3,
    'task': 4, 'callActivity': 4, 'gateway': 4,
    'eventBasedGateway': 4, 'complexGateway': 4,
    'startEvent': 5, 'endEvent': 5, 'intermediateEvent': 5,
    'boundaryEvent': 6
  };
  defaultLayerPriority: number = 3;

  // ── 按 NodeType 分色（黑白配色）──

  // Task 节点（白底 + 黑边框）
  taskFillColor: string = '#FFFFFF';
  taskStrokeColor: string = '#000000';
  taskTextColor: string = '#000000';

  // Task 子类型边框色（统一黑色）
  taskSubtypeStroke: Record<string, string> = {
    'userTask': '#000000',
    'serviceTask': '#000000',
    'scriptTask': '#000000',
    'manualTask': '#000000',
    'sendTask': '#000000',
    'receiveTask': '#000000',
    'businessRuleTask': '#000000',
  };

  // Gateway 节点（白底 + 黑边框）
  gatewayFillColor: string = '#FFFFFF';
  gatewayStrokeColor: string = '#000000';
  gatewayTextColor: string = '#000000';

  // StartEvent（白底 + 黑边框，细线空心圆）
  eventStartFillColor: string = '#FFFFFF';
  eventStartStrokeColor: string = '#000000';
  eventStartStrokeWidth: number = 1.4;

  // EndEvent（纯黑实心 + 粗边框）
  eventEndFillColor: string = '#000000';
  eventEndStrokeColor: string = '#000000';
  eventEndStrokeWidth: number = 2.8;

  // ── Pool/Lane 泳道样式 ──
  poolFillColor: string = '#FAFAFA';
  poolStrokeColor: string = '#999999';
  poolStrokeWidth: number = 1.4;
  poolHeaderWidth: number = 30;
  poolHeaderFillColor: string = '#E0E0E0';
  poolHeaderTextColor: string = '#000000';
  poolHeaderFontSize: number = 12;

  laneFillColor: string = '#FAFAFA';
  laneStrokeColor: string = '#CCCCCC';
  laneStrokeWidth: number = 0.7;
  laneHeaderWidth: number = 20;
  laneHeaderIndent: number = 6;
  laneHeaderFillColor: string = '#EEEEEE';
  laneHeaderTextColor: string = '#000000';
  laneHeaderFontSize: number = 11;

  // ── 连线样式 ──
  edgeStrokeColor: string = '#000000';
  edgeStrokeWidth: number = 1.05;
  arrowSize: number = 12;

  // ── MessageFlow 样式 ──
  messageFlowStrokeColor: string = '#000000';
  messageFlowStrokeWidth: number = 0.84;
  messageFlowDashPattern: number[] = [6, 4];

  // ── 标记/图标样式 ──
  gatewayMarkerColor: string = '#000000';
  eventIconColor: string = '#000000';

  // ── 网格样式 ──
  gridSize: number = 20;
  gridColor: string = '#E0E0E0';

  constructor() {
  }

  /** 暗色主题预设：白字白线 + 深色底 */
  static darkPreset(): RenderConfig {
    let c: RenderConfig = new RenderConfig();
    // 通用
    c.strokeColor = '#FFFFFF';
    c.fillColor = '#1E1E1E';
    c.activeStrokeColor = '#FFFFFF';
    c.activeFillColor = '#333333';
    c.textColor = '#FFFFFF';
    // Task
    c.taskFillColor = '#1E1E1E';
    c.taskStrokeColor = '#FFFFFF';
    c.taskTextColor = '#FFFFFF';
    c.taskSubtypeStroke = {
      'userTask': '#FFFFFF', 'serviceTask': '#FFFFFF', 'scriptTask': '#FFFFFF',
      'manualTask': '#FFFFFF', 'sendTask': '#FFFFFF', 'receiveTask': '#FFFFFF',
      'businessRuleTask': '#FFFFFF'
    };
    // Gateway
    c.gatewayFillColor = '#1E1E1E';
    c.gatewayStrokeColor = '#FFFFFF';
    c.gatewayTextColor = '#FFFFFF';
    // Event
    c.eventStartFillColor = '#1E1E1E';
    c.eventStartStrokeColor = '#FFFFFF';
    c.eventEndFillColor = '#FFFFFF';
    c.eventEndStrokeColor = '#FFFFFF';
    // Pool/Lane
    c.poolFillColor = '#252525';
    c.poolStrokeColor = '#666666';
    c.poolHeaderFillColor = '#333333';
    c.poolHeaderTextColor = '#FFFFFF';
    c.laneFillColor = '#252525';
    c.laneStrokeColor = '#444444';
    c.laneHeaderFillColor = '#2A2A2A';
    c.laneHeaderTextColor = '#FFFFFF';
    // Edge
    c.edgeStrokeColor = '#FFFFFF';
    c.messageFlowStrokeColor = '#FFFFFF';
    // Marker/icon
    c.gatewayMarkerColor = '#FFFFFF';
    c.eventIconColor = '#FFFFFF';
    // Highlight
    c.highlightColor = '#FFC107';
    c.highlightLineWidth = 3;
    // Grid
    c.gridColor = '#333333';
    return c;
  }
}