/*
 * Copyright (c) 2025 hm-flow-kit Contributors.
 * Licensed under the MIT License.
 * See LICENSE file in the project root for full license information.
 */

/**
 * hm-flow-kit 公开 API 入口
 *
 * 所有对外暴露的模块必须在此集中导出，
 * 内部模块不允许被外部直接 import。
 */

// ── Model 层 ──
export { GraphModel, GraphNode, GraphEdge, Waypoint, Viewport, NodeType, EdgeStyle } from './model/GraphModel'

// ── Renderer 层 ──
export { RenderConfig, NodeShape } from './renderer/RenderConfig'
export { NodeRenderer } from './renderer/NodeRenderer'
export { EdgeRenderer } from './renderer/EdgeRenderer'
export { CanvasManager } from './renderer/CanvasManager'
export { GridRenderer } from './renderer/GridRenderer'