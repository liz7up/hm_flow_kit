# hmflowkit

鸿蒙原生 BPMN 2.0 流程图组件库。纯 ArkTS + Canvas 2D 实现，零第三方依赖。

## 安装

```bash
ohpm install hmflowkit
```


## 功能

- 🎨 纯 ArkTS Canvas 2D 渲染，无 WebView
- 📋 BPMN 2.0 XML 解析 — 兼容 bpmn.js 导出格式
- 🔷 4 类 Gateway（Exclusive / Parallel / Inclusive / Event-Based）各具独立内部标记
- ⭕ 5 种 EventDefinition 图标（Timer / Message / Error / Signal / Terminate）
- 🏊 Pool/Lane 泳池泳道完整支持（含嵌套 Lane、横向/纵向标题栏）
- 🔗 SequenceFlow 实线实心箭头 + MessageFlow 虚线空心箭头
- 🎯 节点/连线/泳道命中检测（HitTest）
- 📐 自动适配画布（auto-fit）+ 拖拽平移 + 双指缩放
- 🖱️ 点击高亮选中 + 空白取消
- 🎨 Phase 1 样式系统：按节点类型分色，Task 子类型不同边框色
- 🏗️ 不可变数据模型 GraphModel（所有修改返回新实例）
- 📦 120 项自动化单元测试
- 💻 鸿蒙 PC + 移动端通用

## 快速开始

```typescript
import { FlowViewer, BpmnXmlParser } from 'hmflowkit'

// 方式一：从 BPMN XML 渲染
FlowViewer({ xml: this.bpmnXmlString })

// 方式二：从 GraphModel 渲染
let model: GraphModel = BpmnXmlParser.parse(bpmnXmlString)
FlowViewer({ model: model, canvasHeight: 600 })
```

## 核心 API

### FlowViewer

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| model | GraphModel | 空模型 | 图数据模型 |
| xml | string | '' | BPMN XML 字符串（自动解析） |
| canvasHeight | number | 600 | 画布高度 |
| showGrid | boolean | true | 是否显示背景网格 |
| gridType | GridType | DOT | 网格类型（DOT / LINE / NONE） |
| highlightNodeId | string | '' | 外部控制高亮节点 |
| readonly | boolean | true | 只读模式 |
| onNodeClick | (nodeId: string) => void | — | 节点点击回调 |
| onCanvasReady | () => void | — | 画布就绪回调 |

### BpmnXmlParser

```typescript
BpmnXmlParser.parse(xml: string): GraphModel
```

支持元素：startEvent, endEvent, userTask, serviceTask, manualTask, sendTask, receiveTask, scriptTask, businessRuleTask, task, callActivity, subProcess, exclusiveGateway, parallelGateway, inclusiveGateway, eventBasedGateway, intermediateThrowEvent, intermediateCatchEvent, boundaryEvent, sequenceFlow, messageFlow, collaboration, participant, laneSet, lane, flowNodeRef

### GraphModel

不可变图数据模型。所有修改操作返回新实例。

```typescript
// 创建
GraphModel.createEmpty(): GraphModel

// 节点
addNode(node: GraphNode): GraphModel
addNodes(nodes: GraphNode[]): GraphModel
removeNode(id: string): GraphModel        // 级联删边
moveNode(id: string, x: number, y: number): GraphModel
updateNode(id: string, replacement: GraphNode): GraphModel
getNode(id: string): GraphNode | null
getNodes(): GraphNode[]

// 边
addEdge(edge: GraphEdge): GraphModel
addEdges(edges: GraphEdge[]): GraphModel
removeEdge(id: string): GraphModel
updateEdge(id: string, replacement: GraphEdge): GraphModel
getEdge(id: string): GraphEdge | null
getEdges(): GraphEdge[]
getOutgoingEdges(nodeId: string): GraphEdge[]
getIncomingEdges(nodeId: string): GraphEdge[]
getConnectedEdges(nodeId: string): GraphEdge[]

// Pool / Lane
getPools(): Pool[]
getPool(id: string): Pool | null
getLaneByNode(nodeId: string): Lane | null
addPool(pool: Pool): GraphModel
removePool(id: string): GraphModel
addLane(poolId: string, lane: Lane, parentLaneId?: string): GraphModel
removeLane(poolId: string, laneId: string): GraphModel

// 序列化
toJSON(): GraphModelSnapshot
static fromJSON(snapshot: GraphModelSnapshot): GraphModel
```

### 渲染器

```typescript
// 节点渲染（自动识别 TASK / GATEWAY / START_EVENT / END_EVENT）
NodeRenderer.render(ctx, node, config, offsetX, offsetY, zoom)

// 连线渲染（自动区分 SequenceFlow / MessageFlow）
EdgeRenderer.render(ctx, edge, getNodePosition, offsetX, offsetY, zoom, config)

// 泳池/泳道渲染
PoolLaneRenderer.render(ctx, pools, config, offsetX, offsetY, zoom)

// 背景网格渲染
GridRenderer.render(ctx, width, height, offsetX, offsetY, zoom, gridConfig)
```

### CanvasManager

画布视口管理：缩放、平移、坐标转换。

```typescript
new CanvasManager(minZoom?, maxZoom?, initialZoom?)  // 默认 0.1 / 5.0 / 1.0
pan(dx: number, dy: number): void
zoomAt(cx: number, cy: number, delta: number): void
zoomIn(canvasWidth, canvasHeight): void
zoomOut(canvasWidth, canvasHeight): void
screenToCanvas(sx, sy): { x, y }
canvasToScreen(cx, cy): { x, y }
fitToView(contentW, contentH, canvasW, canvasH, padding?): void
reset(): void
```

### HitTestManager

画布坐标 → 元素命中检测。

```typescript
rebuild(model, canvasManager, config?): void
hitTest(screenX, screenY, canvasManager): HitResult
// HitResult.type: NODE / EDGE / POOL / LANE / CANVAS
```

### RenderConfig

按类型分色的完整样式配置。所有字段均有默认值。

```typescript
new RenderConfig()
// 节点通用：nodeWidth, nodeHeight, strokeColor, fillColor, cornerRadius, ...
// Task 分色：taskFillColor, taskStrokeColor, taskSubtypeStroke（7 种子类型）
// Gateway ：gatewayFillColor, gatewayStrokeColor, gatewayMarkerColor
// Event   ：eventStartFillColor, eventStartStrokeColor, eventEndFillColor, ...
// Pool/Lane：poolFillColor, poolHeaderWidth, laneHeaderIndent, ...
// 连线    ：edgeStrokeColor, arrowSize, messageFlowDashPattern, ...
// 标记    ：gatewayMarkerColor, eventIconColor
// 网格    ：gridSize, gridColor
```

## 协议

Apache-2.0

