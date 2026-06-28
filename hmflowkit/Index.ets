/**
 * hm-flow-kit — 鸿蒙原生流程图组件库
 *
 * 公开 API 入口。只导出外部开发者需要使用的类型和类。
 */

// ── Model 层 ──
export {
  NodeType,
  EdgeStyle,
  GraphModel,
  GraphModelSnapshot,
  GraphNode,
  GraphEdge,
  Waypoint,
  Viewport,
  Pool,
  Lane,
  PoolBounds
} from './src/main/ets/model/GraphModel'

// ── Renderer 层 ──
export { NodeRenderer, INodeDrawer } from './src/main/ets/renderer/NodeRenderer'
export { EdgeRenderer, NodeRect } from './src/main/ets/renderer/EdgeRenderer'
export { GridRenderer, GridType, GridConfig } from './src/main/ets/renderer/GridRenderer'
export { CanvasManager, ViewportState, CanvasPoint, ScreenPoint } from './src/main/ets/renderer/CanvasManager'
export { HitTestManager, HitResult, HitType } from './src/main/ets/renderer/HitTestManager'
export { RenderConfig, NodeShape } from './src/main/ets/renderer/RenderConfig'
export { PoolLaneRenderer } from './src/main/ets/renderer/PoolLaneRenderer'
export { TaskDrawer } from './src/main/ets/renderer/TaskDrawer'
export { GatewayDrawer } from './src/main/ets/renderer/GatewayDrawer'
export { EventDrawer } from './src/main/ets/renderer/EventDrawer'
export { SubProcessDrawer } from './src/main/ets/renderer/SubProcessDrawer'
export { DataDrawer } from './src/main/ets/renderer/DataDrawer'
export { AnnotationDrawer } from './src/main/ets/renderer/AnnotationDrawer'
export { DrawioNodeDrawer } from './src/main/ets/renderer/DrawioNodeDrawer'

// ── Adapter 层（跨格式配置）──
export { ShapeConfig, PerimeterKind } from './src/main/ets/adapter/ShapeConfig'

// ── Plane 层级 ──
export { PlaneHierarchy, PlaneDefinition, BreadcrumbEntry } from './src/main/ets/model/PlaneHierarchy'

// ── Parser 层 ──
export { BpmnXmlParser, ParseResult } from './src/main/ets/parser/BpmnXmlParser'
export { DrawioXmlParser, DrawioParseResult, DrawioParseMeta, DiagramInfo } from './src/main/ets/parser/DrawioXmlParser'
export { DrawioStyleParser, DrawioStyle } from './src/main/ets/parser/DrawioStyleParser'

// ── UI 组件层 ──
export { FlowViewer } from './src/main/ets/components/FlowViewer'

// ── Approval 审批流状态层 ──
export {
  ApprovalStatus, ApprovalStatusColorMap,
  ApprovalOverlayConfig, BadgePosition,
  EdgeTrail, EdgeTrailKind,
  MultiInstanceStatus, NodeDrawRect,
  NodeStatus, NodeStatusMap,
  OnNodeDecorator, StatusColor
} from './src/main/ets/approval/ApprovalTypes'

export { ApprovalColorPresets, PresetId } from './src/main/ets/approval/ApprovalPresets'
export { StatusOverlayRenderer } from './src/main/ets/approval/StatusOverlayRenderer'
export { IApprovalAdapter } from './src/main/ets/approval/IApprovalAdapter'
export {
  FlowableHistoryAdapter,
  FlowableActivity
} from './src/main/ets/approval/FlowableHistoryAdapter'

// 新 UI 组件
export { ApprovalInfoPanel } from './src/main/ets/components/ApprovalInfoPanel'
