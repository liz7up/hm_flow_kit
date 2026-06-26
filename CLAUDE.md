# CLAUDE.md — hm-flow-kit

## 项目定位

鸿蒙原生 BPMN 2.0 流程图组件库。纯 ArkTS + Canvas 2D 实现，兼容 OpenHarmony 与 HarmonyOS。目标是成为鸿蒙生态的「bpmn.js / LogicFlow」——开发者通过 `ohpm install` 即可在自己的鸿蒙应用中嵌入 BPMN 流程图渲染与编辑能力。

## 技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| 语言 | ArkTS (TypeScript 超集) | 100% 代码使用 ArkTS，MVP 阶段不使用 C/C++ |
| UI 框架 | ArkUI | 声明式 UI 框架 |
| 渲染 | Canvas 2D (CanvasRenderingContext2D) | 所有节点、连线、画布均通过 Canvas 直绘 |
| 依赖 | 零第三方库 | MVP 阶段不引入任何 ohpm/npm 依赖 |
| 目标平台 | OpenHarmony 5.0+ / HarmonyOS 5.0+ | 优先兼容 OpenHarmony |

## 项目结构

```
hm-flow-kit/
├── entry/                                # Demo 应用（Empty Ability）
│   └── src/main/ets/pages/
│       └── Index.ets                     # 库的演示页面
├── hmflowkit/                            # 核心库（Static Library HAR）
│   ├── src/main/ets/
│   │   ├── model/
│   │   │   ├── GraphModel.ets            # 图数据模型（唯一数据源）
│   │   │   └── PlaneHierarchy.ets        # 多平面层级管理（钻取导航）
│   │   ├── adapter/
│   │   │   ├── ShapeConfig.ets             # 跨格式形状配置（PerimeterKind 注册表 + ShapeDefinition 注册表）
│   │   │   ├── ShapeDefinition.ets         # PerimeterPoint + ShapeRenderKind + PerimeterPath 预置数据
│   │   │   └── PerimeterRouter.ets         # 精确 perimeter 交点计算（椭圆/菱形/矩形连续数学）
│   │   ├── parser/
│   │   │   ├── BpmnXmlParser.ets           # BPMN 2.0 XML 解析器（v2, XmlPullParser）
│   │   │   ├── DrawioXmlParser.ets         # drawio mxGraph XML 解析器
│   │   │   └── DrawioStyleParser.ets       # drawio style 字符串 → shapeType + properties
│   │   ├── renderer/
│   │   │   ├── NodeRenderer.ets            # 节点渲染器（registry 模式）
│   │   │   ├── EdgeRenderer.ets            # 连线渲染器
│   │   │   ├── GridRenderer.ets            # 背景网格渲染器
│   │   │   ├── CanvasManager.ets           # 画布管理（缩放、平移、fitToView）
│   │   │   ├── HitTestManager.ets          # 命中检测
│   │   │   ├── PoolLaneRenderer.ets        # 泳池/泳道渲染器
│   │   │   ├── DrawioNodeDrawer.ets        # drawio 基础形状渲染器
│   │   │   ├── PathRenderer.ets            # 数据驱动外轮廓渲染（ShapeDefinition → Canvas）
│   │   │   ├── TextUtils.ets               # 共享文本工具（sanitizeLabel）
│   │   │   └── RenderConfig.ets            # 渲染配置
│   │   ├── ohosTest/ets/test/              # 单元测试（Hypium 框架）
│   │   │   ├── GraphModel.test.ets         #   44 项
│   │   │   ├── BpmnXmlParser.test.ets      #   37 项
│   │   │   ├── CanvasManager.test.ets      #   17 项
│   │   │   ├── HitTestManager.test.ets     #   13 项
│   │   │   ├── RenderConfig.test.ets       #    5 项
│   │   │   ├── DrawioStyleParser.test.ets  #   47 项
│   │   │   ├── DrawioXmlParser.test.ets    #   19 项
│   │   │   ├── ShapeDefinition.test.ets     #    9 项
│   │   │   └── PerimeterRouter.test.ets     #   10 项
│   │   └── components/
│   │       └── FlowViewer.ets              # 只读流程查看器（BPMN + drawio 双模式）
│   ├── Index.ets                         # 公开 API 导出入口
│   └── oh-package.json5                 # 库的包配置
├── test_all.sh                           # 单元测试编译验证脚本
├── specs/                                # 开发规格文档
│   ├── 01-graph-model.md
│   ├── 02-canvas-renderer.md
│   ├── 03-bpmn-parser.md
│   ├── 06-flowviewer.md
│   └── 07-xml-parser-v2.md               # Spec 03 重写（XmlPullParser）
├── examples/                             # 可运行的示例
│   ├── hello-graph/                      # 最简渲染示例
│   └── bpmn-viewer/                      # BPMN 查看器示例
├── .bitfun/
│   └── build-latest.log                  # 最新编译日志（build.sh 产出）
├── CLAUDE.md                             # 本文件（BitFun 项目记忆）
├── build.sh                              # 编译桥接脚本（DevEco 终端中运行）
└── .mcp.json                             # MCP 服务配置
```

## 架构约束（必须遵守）

### 四层架构

```
┌─────────────────────────────────────────────────┐
│  UI 组件层       FlowViewer / FlowDesigner       │
├─────────────────────────────────────────────────┤
│  Interaction 层  DragController / Connect...     │
├─────────────────────────────────────────────────┤
│  Renderer 层     NodeRenderer / EdgeRenderer     │
├─────────────────────────────────────────────────┤
│  Model 层        GraphModel（唯一数据源）         │
├─────────────────────────────────────────────────┤
│  Parser 层       BpmnXmlParser / Serializer      │
└─────────────────────────────────────────────────┘
```

### 关键规则

1. **Model 层是唯一数据源**。GraphModel 持有所有节点和边的数据，Renderer 只读不写，Interaction 通过 Model 的方法修改数据。任何状态变更都必须经过 GraphModel。

2. **不可跨层调用**。UI 组件层不能直接操作 Canvas（那是 Renderer 层的职责），Renderer 不能直接处理手势（那是 Interaction 层的职责）。

3. **Renderer 单向依赖 Model**。Renderer 接收 GraphModel 的快照进行绘制，不持有 Model 引用。

4. **公开 API 必须通过 Index.ets 导出**。所有 `export` 声明集中在 `hmflowkit/Index.ets`，不允许内部模块被外部直接 import。

5. **接口优先于实现**。每个模块先定义接口（`interface`），再写实现类。便于后续扩展（如插件机制）。

## 参考项目（学习对象，不引入依赖）

| 项目 | 借鉴内容 | 链接 |
|------|---------|------|
| **ofdkit-harmony** | ArkUI Canvas 渲染模式、分层架构、ohpm 发布方式 | gitee.com/notcoder/ofdkit-harmony |
| **LogicFlow** | GraphModel 设计、插件机制、Dagre 布局集成 | github.com/didi/LogicFlow |
| **bpmn.js** | diagram-js 与 bpmn-js 分离模式、BPMN 2.0 XML 解析 | github.com/bpmn-io/bpmn-js |
| **AntV X6** | Canvas 虚拟 DOM、Hit Testing、节点/边渲染管线 | github.com/antvis/X6 |

## 当前开发阶段

**Spec 01 — GraphModel ✅ 已完成**
- 891 行，44 项测试全部通过 — 含 Pool/Lane 数据结构
- 不可变数据模式、序列化、级联删除

**Spec 02 — Canvas 渲染层 ✅ 已完成**
- ✅ NodeRenderer / EdgeRenderer / GridRenderer / CanvasManager / RenderConfig / HitTestManager
- ✅ 视觉 Demo 验证通过 + 14 项单元测试全部通过
- 共约 1350 行渲染层代码

**Spec 03 — BPMN 2.0 XML 解析器 ✅ 已完成** → **v2 重写 (Spec 07) ✅**
- 592 行，37 项测试全部通过 — 含 collaboration/laneSet/eventDefinition/messageFlow 解析 — 基于 @kit.ArkTS xml.XmlPullParser (parseXml 回调 API)
- 支持命名空间前缀剥离、15+ 种节点类型映射、BPMNShape 坐标、BPMNEdge waypoints
- ⚠️ 关键实现细节：tokenValueCallback 在 attributeValueCallback **之前**触发（与官方文档暗示顺序相反），所有业务逻辑必须在 END_TAG 中处理
- ⚠️ ignoreNameSpace: true 实测不剥离 getName() 前缀（返回 "bpmndi:BPMNLabel"），需手动 localName() 做 lastIndexOf(':')
- ⚠️ attributeValueCallback 遇到 `&` 会丢弃属性值 —— 用 `decodeXmlCharacterRefs()` 预处理 XML 字符串

**Spec 06 — FlowViewer 组件 ✅ 已完成**
- 支持 XML 直接输入（`xml` prop）：内部使用 `parseBestEffort()` 宽松解析，解析异常时显示红色错误提示 + 空画布，不崩溃
- 支持预解析 model 输入（`model` prop）：调用方自行 try-catch，错误时传空 model 即可
- `parseBestEffort()` 返回 `ParseResult { model, warnings, isPartial }`，部分成功时保留已解析的节点和边

**Multi-Plane Drill-Down — 嵌套子流程钻取导航 ✅ 已完成**
- `PlaneHierarchy.ets`（101 行）— PlaneHierarchy / PlaneDefinition / BreadcrumbEntry 数据结构
- BpmnXmlParser 新增 `parseHierarchy()` 静态方法：解析多个 `<BPMNDiagram>` → 构建层级平面
- Post-scan 后处理：`_scanDiagramPlanes()` 字符串扫描 diagram→plane 映射 + shape/edge 路由 + isExpanded 捕获；`_scanSubProcessParents()` 扫描 subProcess 嵌套建立父子链
- 回调时序陷阱彻底绕过：所有多平面属性提取+路由在 post-scan 完成，不依赖 START_TAG 时的 `currentAttrs`
- FlowViewer 新增 `@Prop planeHierarchy` + `@Watch` 异步加载支持；面包屑可点击分段导航 `Root > Procure > Charge`
- SubProcessDrawer：expanded（layer 0 背景容器，居中靠上标签）vs collapsed（layer 4 可交互，蓝色 [+] 标记）
- HitTestManager：最小面积命中（内部小元素优先于父容器大包围盒）
- BpmnViewerPage 自动适配：`parseHierarchy()` 多平面则启用钻取，单平面回退 `parse()`
- 单平面 XML（pizza / kitchen-sink）完全向后兼容
- 范例：`examples/bpmn-js-examples/nested-subprocesses.bpmn`（6 平面，4 层钻取深度）

**Pool/Lane — 泳池/泳道 ✅ 已完成**
- 891 行 GraphModel 含 Pool/Lane/PoolBounds 数据类 + 15 个新方法
- 592 行 BpmnXmlParser 含 collaboration/laneSet/participant/flowNodeRef 解析
- 194 行 PoolLaneRenderer 含双朝向标题栏 + canvas rotate(-PI/2) 横排文字 + Lane 边界过滤
- RenderConfig 新增 12 个泳道配色字段（含 laneHeaderIndent 统一缩进）
- HitTestManager 含 POOL/LANE 命中类型，接受 RenderConfig 统一配置
- FlowViewer fitToView 考虑泳池边界，标题栏 Z-order 正确
- 186 行，一行接入 `FlowViewer({ model })`
- 自动适配内容缩放（auto-fit）、点击高亮、点击空白取消高亮
- PanGesture 拖拽平移 + PinchGesture 双指缩放 + 浮动 +/- 缩放按钮（Stack 覆盖层）
- 全屏覆盖层支持

**当前总验收：186/186 自动化单元测试编译通过**

### 自动化测试

| 项目 | 说明 |
|------|------|
| 框架 | @ohos/hypium (describe/it/expect) |
| 位置 | `hmflowkit/src/ohosTest/ets/test/` |
| 覆盖 | GraphModel(44) BpmnXmlParser(37) CanvasManager(17) HitTestManager(13) RenderConfig(5) DrawioStyleParser(47) DrawioXmlParser(19) |
| 运行 | `sh test_all.sh`（编译验证）/ DevEco Studio 右键 ohosTest → Run（真机执行） |
| 原则 | 纯数据/算法测试，不依赖 Canvas mock 或 UI 组件 |

**已实现完整功能：**
- BPMN XML 解析（含泳道）→ 渲染（含 Pool/Lane）→ 点击高亮 → 拖拽平移 + 双指缩放 → 自动缩放适配
- Phase 1 样式系统：按 NodeType 分色 + Task 子类型边框色 + EdgeRenderer 读取 config
- ✅ TODO-3.5 渲染修复：Event 文字移出圆圈显示在下方；Pool/Lane 标题改用 canvas rotate 横排；MessageFlow 虚线+空心箭头+路径中点 label 绘制；XML 字符引用预处理 + label 净化；BoundaryEvent 双层圆（非中断 cancelActivity=false 虚线双圈 / 中断型实线双圈）

**Drawio 文件浏览支持 ✅ 已完成**
- `DrawioXmlParser.ets`（~500 行）— mxGraph XML → GraphModel，含 HTML 净化、两趟构建、perimeter 路由
- `DrawioStyleParser.ets`（~240 行）— style 字符串解析，形状检测 + 属性映射
- `DrawioNodeDrawer.ets`（~340 行）— 基础几何形状渲染 + 降级策略
- `ShapeConfig.ets`（~70 行）— 跨格式配置层：PerimeterKind 注册表，未来接 Visio/UML 只需加映射
- `EdgeRenderer.ets` 扩展：bezier 曲线 + `_endArrow`/`_startArrow` 支持 + per-edge 颜色
- `GraphNode.type: string` — 从 NodeType enum 放宽，registry 注册表模式（`NodeRenderer.register()`）
- **BPMN 2.0 drawio 形状全映射**：Events（8 种 outline→startEvent/endEvent/intermediateEvent/boundaryEvent）、Gateways（data+event-based，新旧两种格式）、Tasks（8 种 taskMarker）、SubProcess/CallActivity、DataObject/DataStore、Annotation、Swimlane/Pool
- `FlowViewer` 新增 `@Prop drawioXml: string` prop + Demo 页面文件选择器
- 测试：DrawioStyleParser(47 项) + DrawioXmlParser(19 项)，总 186 项编译通过
- ⚠️ drawio `<Array as="points">` 只是中间路由点，不连形状边界——parser 自动补 source/target perimeter

**Data-Driven Shape Geometry — 数据驱动形状几何系统 ✅ 已完成**
- `ShapeDefinition.ets`（100 行）— PerimeterPoint + ShapeRenderKind(NATIVE_ELLIPSE/NATIVE_RHOMBUS/POLYLINE) + 4 种 canon 路径(SIMPLE_RECT/EVENT_PERIMETER/GATEWAY_PERIMETER/TASK_PERIMETER)
- `PerimeterRouter.ets`（85 行）— 椭圆/菱形/矩形连续数学 perimeter 交点，替换 DrawioXmlParser 中 3 个旧 `_perimeter*` 方法
- `PathRenderer.ets`（135 行）— 根据 ShapeDefinition 的 renderKind 分发：NATIVE_ELLIPSE→ctx.ellipse()，NATIVE_RHOMBUS→四边中点菱形，POLYLINE→4 点矩形 + arcTo 圆角
- `ShapeConfig.ets` 扩展 — registerShape()/getShapeDefinition() 注册表 + module init 时从 `_perimeterMap` 预填充全部 22 种类型
- `TextUtils.ets` — 提取 5 个 Drawer 中重复的 sanitizeLabel()
- 6 个 Drawer 全部切换轮廓绘制至 PathRenderer，图标/标记代码完整保留
- `DrawioNodeDrawer` 对 ELLIPSE/RHOMBUS/rect 类型走 PathRenderer，三角形/平行四边形/文本保留原 switch
- RECT 类型用 4 点 SIMPLE_RECT + cornerRadiusRatio 0.133 → 与 BPMN 1.0 一致的细腻圆角
- 测试：ShapeDefinition(9 项) + PerimeterRouter(10 项)，**总 216 项编译通过**
- **TODO: 图标标准化注册表（IconDefinition）** — 内部图标/标记也声明化
- **TODO: EdgeRenderer 接入 PerimeterRouter** — BPMN XML 连线 perimeter 计算切换到新路由

**已推迟：Spec 04 交互编辑、Spec 05 Dagre 布局**

## 禁止事项

- 禁止使用 WebView 加载 bpmn.js（这违背原生渲染的初衷）
- 禁止在 Renderer 中直接修改 GraphModel 数据
- 禁止引入任何 npm/ohpm 第三方依赖（MVP 阶段保持零依赖）
- 禁止节点位置硬编码——所有坐标来自 GraphModel 或 BPMN XML
- 禁止在单个文件中超过 500 行代码（保持模块粒度）

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 接口 | `I` 前缀 | `IGraphModel`, `INodeRenderer` |
| 类 | PascalCase | `GraphModel`, `NodeRenderer` |
| 方法 | camelCase | `addNode()`, `moveNode()` |
| 常量 | UPPER_SNAKE_CASE | `DEFAULT_NODE_WIDTH` |
| 文件 | PascalCase (类文件) | `GraphModel.ets` |
| 私有成员 | `_` 前缀 | `_nodes`, `_edges` |
| ⚠️ 组件Prop | 避免与 ArkUI 内置属性重名 | `height`→`canvasHeight`, `width`→`canvasWidth` |

## 已实现 API 参考（精确签名，禁止猜测）

### 构造器
```
new GraphNode(id: string, type: NodeType, x: number, y: number, width: number, height: number, label: string, properties: Record<string,string>)
new GraphEdge(id: string, sourceId: string, targetId: string, waypoints: Waypoint[], style: EdgeStyle, label: string, properties: Record<string,string>)
new Waypoint(x: number, y: number)
new Viewport(x: number, y: number, zoom: number)
new NodeRect(x: number, y: number, w: number, h: number)
new RenderConfig()  // 无参，所有颜色/样式字段均有默认值
new PoolBounds(x: number, y: number, width: number, height: number)
new Lane(id: string, name: string, bounds: PoolBounds, childLanes: Lane[], flowNodeRefs: string[])
new Pool(id: string, name: string, isHorizontal: boolean, bounds: PoolBounds, lanes: Lane[])
new CanvasManager(minZoom?: number, maxZoom?: number, initialZoom?: number) // 默认 0.1 / 5.0 / 1.0
new HitTestManager() // 无参
new GridConfig(type?: GridType)  // 默认 DOT
GraphModel.createEmpty() // 静态工厂，无参

// 多平面钻取导航
new PlaneHierarchy(planes: PlaneDefinition[], rootProcessId: string)
new PlaneDefinition(diagramId: string, processId: string, model: GraphModel, label: string, parentProcessId: string)
new BreadcrumbEntry(processId: string, label: string)
```

### GraphModel 方法
```
getNodeCount(): number
getEdgeCount(): number
getNodes(): GraphNode[]
getEdges(): GraphEdge[]
getNode(id: string): GraphNode | null   // 注意返回 null 不是 undefined
getEdge(id: string): GraphEdge | null
hasNode(id: string): boolean
hasEdge(id: string): boolean
getOutgoingEdges(nodeId: string): GraphEdge[]
getIncomingEdges(nodeId: string): GraphEdge[]
getConnectedEdges(nodeId: string): GraphEdge[]
getViewport(): Viewport
addNode(node: GraphNode): GraphModel    // 不可变，返回新实例
addEdge(edge: GraphEdge): GraphModel
addNodes(nodes: GraphNode[]): GraphModel
addEdges(edges: GraphEdge[]): GraphModel
removeNode(id: string): GraphModel      // 级联删边
removeEdge(id: string): GraphModel
moveNode(id: string, x: number, y: number): GraphModel
updateNode(id: string, replacement: GraphNode): GraphModel
updateEdge(id: string, replacement: GraphEdge): GraphModel
setViewport(viewport: Viewport): GraphModel
clear(): GraphModel
toJSON(): GraphModelSnapshot
static fromJSON(snapshot: GraphModelSnapshot): GraphModel
getPoolCount(): number
getPools(): Pool[]
getPool(id: string): Pool | null
hasPool(id: string): boolean
getLaneByNode(nodeId: string): Lane | null        // 递归查找节点所属 Lane
addPool(pool: Pool): GraphModel
removePool(id: string): GraphModel
updatePool(id: string, replacement: Pool): GraphModel
updatePoolBounds(id: string, bounds: PoolBounds): GraphModel
addLane(poolId: string, lane: Lane, parentLaneId?: string): GraphModel
removeLane(poolId: string, laneId: string): GraphModel   // 级联删子 Lane
updateLane(poolId: string, replacement: Lane): GraphModel
```

### CanvasManager 方法
```
new CanvasManager(minZoom?, maxZoom?, initialZoom?)  // 默认 0.1 / 5.0 / 1.0
zoom: number                            // getter，只读
offsetX: number                         // getter，只读
offsetY: number                         // getter，只读
applyTransform(ctx: CanvasRenderingContext2D): void
pan(dx: number, dy: number): void
zoomAt(cx: number, cy: number, delta: number): void  // delta>0 放大
zoomTo(cx: number, cy: number, targetZoom: number): void
zoomIn(canvasWidth: number, canvasHeight: number): void
zoomOut(canvasWidth: number, canvasHeight: number): void
screenToCanvas(sx: number, sy: number): CanvasPoint  // 返回 .x .y
canvasToScreen(cx: number, cy: number): ScreenPoint   // 返回 .x .y
getViewport(): ViewportState            // 返回 { zoom, offsetX, offsetY }
setViewport(state: ViewportState): void
setZoomRange(min: number, max: number): void
fitToView(contentW, contentH, canvasW, canvasH, padding?): void
reset(): void
```

### 渲染器（全部静态方法）
```
NodeRenderer.render(ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig, offsetX: number, offsetY: number, zoom: number): void
EdgeRenderer.render(ctx: CanvasRenderingContext2D, edge: GraphEdge, getNodePosition: (id: string) => NodeRect, offsetX: number, offsetY: number, zoom: number, config: RenderConfig = new RenderConfig()): void
GridRenderer.render(ctx: CanvasRenderingContext2D, width: number, height: number, offsetX: number, offsetY: number, zoom: number, gridConfig: GridConfig): void
PoolLaneRenderer.render(ctx: CanvasRenderingContext2D, pools: Pool[], config: RenderConfig, offsetX: number, offsetY: number, zoom: number): void
```

### RenderConfig 字段（Phase 1 补全）

```
// 通用字段
nodeWidth: number = 120
nodeHeight: number = 60
// ── 通用 ──
nodeWidth: number = 120
nodeHeight: number = 60
strokeColor: string = '#333333'
strokeWidth: number = 2
fillColor: string = '#FFFFFF'
activeStrokeColor: string = '#1890FF'
activeFillColor: string = '#E6F7FF'
textColor: string = '#333333'
fontSize: number = 12
fontFamily: string = 'HarmonyOS Sans, sans-serif'
fontSizeMin: number = 12

// ── 节点度量（design tokens）──
cornerRadiusRatio: number = 0.133     // r = min(w,h)*0.133 (60→8)
nodePadding: number = 4

// ── Task 标记 ──
taskIconSize: number = 12
taskIconOffset: number = 4
loopMarkerSize: number = 5
loopMarkerSpacing: number = 4
loopMarkerOffset: number = 5

// ── CallActivity ──
callActivityBorderRatio: number = 2.5
callActivityMarkerSize: number = 5
callActivityMarkerOffset: number = 10

// ── 按 NodeType 分色 ──
taskFillColor: string = '#FFFFFF'
taskStrokeColor: string = '#616161'
taskTextColor: string = '#333333'
taskSubtypeStroke: Record<string,string> = { 'userTask':'#1976D2', 'serviceTask':'#00897B', 'scriptTask':'#7B1FA2', 'manualTask':'#795548', 'sendTask':'#F57C00', 'receiveTask':'#3949AB', 'businessRuleTask':'#C62828' }

gatewayFillColor: string = '#FFFDE7'
gatewayStrokeColor: string = '#FFB300'
gatewayTextColor: string = '#333333'
gatewayMarkerScale: Record<string,number> = {
  'exclusiveGateway': 0.16, 'parallelGateway': 0.28,
  'inclusiveGateway': 0.28, 'complexGateway': 0.42, 'eventBasedGateway': 0.42
}

eventStartFillColor: string = '#FFFFFF'
eventStartStrokeColor: string = '#43A047'
eventStartStrokeWidth: number = 2
eventEndFillColor: string = '#424242'
eventEndStrokeColor: string = '#424242'
eventEndStrokeWidth: number = 4
eventIconScale: number = 0.55
eventLabelGap: number = 4
eventInnerRingScale: number = 0.82

// ── SubProcess ──
subProcessInset: number = 3
subProcessExpandMarkerSize: number = 12
subProcessDashPattern: number[] = [6, 3]

// ── Pool/Lane 泳道 ──
poolFillColor: string = '#FAFAFA'
poolStrokeColor: string = '#BDBDBD'
poolStrokeWidth: number = 2
poolHeaderWidth: number = 30
poolHeaderFillColor: string = '#E0E0E0'
poolHeaderTextColor: string = '#424242'
poolHeaderFontSize: number = 12
laneFillColor: string = '#F5F5F5'
laneStrokeColor: string = '#E0E0E0'
laneStrokeWidth: number = 1
laneHeaderWidth: number = 20
laneHeaderIndent: number = 6
laneHeaderFillColor: string = '#EEEEEE'
laneHeaderTextColor: string = '#616161'
laneHeaderFontSize: number = 11

// ── Data ──
dataObjectFoldSize: number = 12

// ── Annotation ──
annotationBracketWidth: number = 8
annotationFontScale: number = 1.4

// ── 连线 ──
edgeStrokeColor: string = '#5E5E5E'
edgeStrokeWidth: number = 1.5
arrowSize: number = 12
edgeLabelOffset: number = 12
edgeLabelPadding: number = 3

// ── 标记/图标 ──
gatewayMarkerColor: string = '#333333'
eventIconColor: string = '#333333'

// ── 网格 ──
gridSize: number = 20
gridColor: string = '#E8E8E8'
// ⚠️ 点阵性能：可见点数 > MAX_VISIBLE_DOTS(5000) 时跳过点阵渲染，避免缩放时帧率崩溃

// ── HitTest ──
edgeHitTolerance: number = 12

// ── 视口 ──
fitToViewPadding: number = 40
fitToViewMinZoom: number = 0.1
fitToViewMaxZoom: number = 3.0
renderThrottleMs: number = 16

// ── 高亮 ──
highlightColor: string = 'rgba(24, 144, 255, 0.35)'
highlightPadding: number = 4

// ── 绘制层序 ──
layerPriorities: Record<string,number> = {
  'poolLane': 0, 'subProcess': 1,
  'dataObject': 4, 'dataStore': 4, 'textAnnotation': 4,
  'edge': 3,
  'task': 4, 'callActivity': 4, 'gateway': 4,
  'eventBasedGateway': 4, 'complexGateway': 4,
  'startEvent': 5, 'endEvent': 5, 'intermediateEvent': 5,
  'boundaryEvent': 6
}
defaultLayerPriority: number = 3
```

### HitTestManager 方法
```
rebuild(model: GraphModel, canvasManager: CanvasManager, config?: RenderConfig): void
hitTest(screenX: number, screenY: number, canvasManager: CanvasManager): HitResult
// HitResult 有: type: HitType (NODE/EDGE/CANVAS/POOL/LANE), nodeId: string, edgeId: string, poolId: string, laneId: string, canvasX: number, canvasY: number
```

### BPMN Parser
```
BpmnXmlParser.parse(xml: string): GraphModel        // 严格模式，遇错抛 Error
BpmnXmlParser.parseBestEffort(xml: string): ParseResult  // 宽松模式，遇错返回部分结果 + 警告
BpmnXmlParser.parseHierarchy(xml: string): PlaneHierarchy  // 多平面解析，遇错抛 Error
```
`ParseResult` 字段：`model: GraphModel`、`warnings: string[]`、`isPartial: boolean`
元素覆盖：startEvent, endEvent, task, userTask, serviceTask, scriptTask, manualTask, sendTask, receiveTask, businessRuleTask, callActivity, subProcess, exclusiveGateway, parallelGateway, inclusiveGateway, eventBasedGateway, intermediateThrowEvent, intermediateCatchEvent, boundaryEvent, sequenceFlow
注意：textAnnotation, dataObjectReference, dataStoreReference, group 有意丢弃（非核心视觉元素）
- participant/lane 现已解析：`<collaboration>` → Pool，`<laneSet>`/`<lane>` → Lane（含嵌套 childLaneSet），`<flowNodeRef>` → node-to-lane 关联
- ⚠️ 多 Pool 共享同一 Process 时，每个 Pool 复制全部 Lane；渲染时通过边界检查过滤不重叠的 Lane
- ⚠️ 多平面解析（parseHierarchy）：通过 `_scanDiagramPlanes()` post-scan 字符串扫描完成 diagram→plane 映射 + shape/edge 路由，完全绕过 START_TAG attr 读取时序陷阱

### PlaneHierarchy（多平面钻取导航）
```
PlaneHierarchy.getPlane(processId: string): PlaneDefinition | null
PlaneHierarchy.hasPlane(processId: string): boolean
PlaneHierarchy.getRootModel(): GraphModel
PlaneHierarchy.getRootProcessId(): string
PlaneHierarchy.getBreadcrumbs(processId: string): BreadcrumbEntry[]  // 父链到根
PlaneHierarchy.getPlaneCount(): number
```

⚠️ **节点 properties**：
- 解析后每个节点 `properties['bpmnElement']` 存储原始 BPMN 标签名（如 `'userTask'`、`'serviceTask'`）
- NodeRenderer 据此查 `RenderConfig.taskSubtypeStroke` 取不同的边框颜色
- 未识别的标签名 fallback 到 `taskStrokeColor`

⚠️ **parseXml() 回调时序陷阱（已验证）**：
- tokenValueCallback(START_TAG) 在 attributeValueCallback **之前**触发（与官方文档暗示顺序相反）
- 因此 START_TAG 只设状态标记+重置累积器，**禁止**从中读取属性
- 所有业务逻辑必须在 END_TAG 中处理
- ignoreNameSpace: true 不会剥离 getName() 返回的命名空间前缀，需手动 `localName()` 处理
- ArkTS 闭包捕获对象引用（非变量绑定），禁止对 `currentAttrs` 整体重赋值（`= {}`），否则闭包写入旧对象、逻辑读取新对象，导致属性全部丢失

### FlowViewer 组件
```
@Component struct FlowViewer {
  @Prop model: GraphModel            // 模型数据
  @Prop xml: string                  // BPMN XML 字符串（自动解析到 model）
  @Prop canvasHeight: number         // 画布高度（默认 600）
  @Prop showGrid: boolean            // 是否显示背景网格
  @Prop gridType: GridType           // 网格类型（DOT/LINE/NONE）
  @Prop highlightNodeId: string      // 外部控制高亮节点 ID
  @Prop readonly: boolean            // 只读模式
  @Prop planeHierarchy: PlaneHierarchy | null  // 多平面层级（启用钻取导航）
  @Prop renderConfig: RenderConfig   // 渲染配置（含明暗主题跟随）
  @Watch('onPlaneHierarchyChange')   // 异步加载后自动初始化导航
  onNodeClick?: (nodeId: string) => void
  onCanvasReady?: () => void
}
// 用法: FlowViewer({ model: this.model, canvasHeight: 400 })
// 或:   FlowViewer({ xml: this.bpmnXmlStr })
// 钻取: FlowViewer({ model: rootModel, planeHierarchy: hierarchy })
```

### 禁止使用的 API（不存在）
```
❌ FlowViewer.fromModel() — 不存在
❌ CanvasManager.getCanvas() — 不存在
❌ NodeRenderer.render 不带 config/offsetX/offsetY/zoom — 签名错误
❌ EdgeRenderer.render 不带 getNodePosition/offsetX/offsetY/zoom — 签名错误（config 有默认值，可省略）
❌ hitTest(x, y) 两参数 — 实际需 3 参数: (x, y, canvasManager)
❌ HitResult.targetType — 实际字段是 .type
❌ getNode() 返回 undefined — 实际返回 null
❌ BpmnXmlParser 使用 parser.parse() + next() 命令式循环 — API 14 中已废弃，应使用 parseXml()
```

## DevOps

### 编译桥接流程（BitFun ↔ DevEco Studio）

无法直接编译鸿蒙项目。通过 `build.sh` 后台监听 + `.bitfun/build-flag` 触发编译：

```
                    ┌──────────────────────────┐
                    │   你的 DevEco Studio       │
                    │                          │
                    │  1. 打开 Terminal         │
                    │  2. sh build.sh &         │
                    │     (后台持续监听)         │
                    │     └→ 检测 build-flag=1  │
                    │        → sync → build    │
                    │        → 写入 build-      │
                    │          latest.log       │
                    │        → 重置 flag=0      │
                    └──────────┬───────────────┘
                               │ 共享文件系统
                    ┌──────────▼───────────────┐
                    │      BitFun 沙箱          │
                    │                          │
                    │  3. echo 1 > build-flag  │
                    │  4. 轮询 flag 变回 0      │
                    │  5. 读取 build-latest.log │
                    │  6. 分析错误 → 修复代码    │
                    └──────────────────────────┘
```

**操作步骤（一次性启动）：**

在 DevEco Studio 中：
1. `File → Sync Project` 同步项目
2. 打开底部 Terminal 面板
3. 启动后台监听：`sh build.sh`
4. 保持 Terminal 打开（或 `nohup sh build.sh &`）

**Claude 触发编译：**

```bash
echo "1" > .bitfun/build-flag
# 等待 flag 变回 0（编译完成信号），最多等待 120s
until [ "$(cat .bitfun/build-flag 2>/dev/null)" = "0" ]; do sleep 2; done
cat .bitfun/build-latest.log
```

**build.sh 模式：**
| 命令 | 用途 |
|------|------|
| `sh build.sh` | 后台监听模式，轮询 build-flag |
| `sh build.sh --once` | 单次编译（手动触发） |
| `sh build.sh --sync` | 仅 ohpm install |

**编译流程（每次）：**
- Step 0: `ohpm install --all`（刷新依赖 + 文件变更）
- Step 1: `hvigorw assembleHar`（库模块）
- Step 2: `hvigorw assembleHap`（Demo 应用）
- Step 3: `hvigorw genOnDeviceTestHap`（ohosTest 单元测试编译）
- 写入 `.bitfun/build-latest.log` + 重置 build-flag=0

### 测试

测试编译已集成到 `build.sh` Step 3，无需单独运行。`build.sh` 一次触发即可完成 HAR + HAP + Test 全部编译。

### 其他操作

- 发布：`ohpm publish` 到 OHPM 三方库中心仓
- 版本号：遵循 SemVer（当前 0.1.0）