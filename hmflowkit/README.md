# hmflowkit

鸿蒙原生 BPMN 2.0 流程图组件库。纯 ArkTS + Canvas 2D 实现，零第三方依赖。

## 安装

```bash
ohpm install hmflowkit
```


## 功能

- 🎨 纯 ArkTS Canvas 2D 渲染，无 WebView
- 📋 BPMN 2.0 XML 解析 — 兼容 bpmn.js 导出格式
- 🔷 4 类 Gateway 内部标记 + 10 种 EventDefinition 图标 + 7 种 Task 类型图标
- 🏊 Pool/Lane 泳池泳道 + 3 种 SubProcess 边框（单线/双线/虚线）
- 🔗 SequenceFlow 实线 + MessageFlow 虚线 + Association 关联线
- 🎯 节点/连线/泳道命中检测（HitTest），嵌套元素最小面积优先
- 🌓 系统明暗主题自动适配 + RenderConfig 自定义配色
- 🔲 多平面钻取导航：嵌套子流程展开/折叠 + 面包屑层级跳转
- 📐 自动适配画布（auto-fit）+ 拖拽平移 + 双指缩放 + 浮动缩放按钮
- 🖱️ 点击高亮选中 + 空白取消
- 🏗️ 不可变数据模型 GraphModel + PlaneHierarchy 层级管理
- 🧩 ~30 design token 可配置样式（RenderConfig）
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
| renderConfig | RenderConfig | 默认配置 | 自定义渲染样式 |
| planeHierarchy | PlaneHierarchy \| null | null | 多平面层级（启用钻取导航） |
| onNodeClick | (nodeId: string) => void | — | 节点点击回调 |
| onCanvasReady | () => void | — | 画布就绪回调 |

### BpmnXmlParser

```typescript
BpmnXmlParser.parse(xml: string): GraphModel
BpmnXmlParser.parseBestEffort(xml: string): ParseResult  // { model, warnings, isPartial }
BpmnXmlParser.parseHierarchy(xml: string): PlaneHierarchy  // 多平面层级结构
```

支持元素：startEvent, endEvent, userTask, serviceTask, manualTask, sendTask, receiveTask, scriptTask, businessRuleTask, task, callActivity, subProcess（含 transaction / eventSubProcess）, exclusiveGateway, parallelGateway, inclusiveGateway, eventBasedGateway, intermediateThrowEvent, intermediateCatchEvent, boundaryEvent, sequenceFlow, messageFlow, association, dataAssociation, dataObjectReference, dataStoreReference, textAnnotation, collaboration, participant, laneSet, lane, flowNodeRef, multiInstanceLoopCharacteristics

### PlaneHierarchy

多平面钻取导航模型。管理 BPMNDiagram → Process 层级关系。

```typescript
getPlaneCount(): number
getRootProcessId(): string
getChildren(planeId: string): PlaneDefinition[]
getParent(planeId: string): PlaneDefinition | null
getBreadcrumb(planeId: string): BreadcrumbEntry[]
```

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
// 节点渲染器 + 6 个按类型分发的 Drawer（可单独导出）
NodeRenderer.render(ctx, node, config, offsetX, offsetY, zoom)
TaskDrawer, GatewayDrawer, EventDrawer, SubProcessDrawer, DataDrawer, AnnotationDrawer

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

按类型分色的完整样式配置。所有字段均有默认值。支持 `darkPreset()` 暗色主题。

```typescript
new RenderConfig()
new RenderConfig.darkPreset()  // 暗色主题预设
// 节点通用：nodeWidth, nodeHeight, strokeColor, fillColor, cornerRadiusRatio, textBaseline, ...
// Task 分色：taskFillColor, taskStrokeColor, taskSubtypeStroke（7 种子类型）
// Gateway ：gatewayFillColor, gatewayStrokeColor, gatewayMarkerColor
// Event   ：eventStartFillColor, eventStartStrokeColor, eventEndFillColor, ...
// Pool/Lane：poolFillColor, poolHeaderWidth, laneHeaderIndent, ...
// 连线    ：edgeStrokeColor, arrowSize, messageFlowDashPattern, ...
// 标记    ：gatewayMarkerColor, eventIconColor
// 设计 token：~30 个可配置字段，layerPriorities（Z-order 映射）
// 网格    ：gridSize, gridColor
```

## 协议

Apache-2.0

## 仓库

https://github.com/liz7up/hm_flow_kit

