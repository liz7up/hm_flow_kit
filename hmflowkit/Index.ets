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
  Viewport
} from './src/main/ets/model/GraphModel'

// ── Renderer 层 ──
export { NodeRenderer } from './src/main/ets/renderer/NodeRenderer'
export { EdgeRenderer, NodeRect } from './src/main/ets/renderer/EdgeRenderer'
export { GridRenderer, GridType, GridConfig } from './src/main/ets/renderer/GridRenderer'
export { CanvasManager, ViewportState, CanvasPoint, ScreenPoint } from './src/main/ets/renderer/CanvasManager'
export { HitTestManager, HitResult, HitType } from './src/main/ets/renderer/HitTestManager'
export { RenderConfig, NodeShape } from './src/main/ets/renderer/RenderConfig'

// ── Parser 层 ──
export { BpmnXmlParser, ParseResult } from './src/main/ets/parser/BpmnXmlParser'

// ── UI 组件层 ──
export { FlowViewer } from './src/main/ets/components/FlowViewer'