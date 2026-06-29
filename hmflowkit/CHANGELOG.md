# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-06-29

### Added — 审批流状态可视化 (Spec 09)

- **`ApprovalTypes` 数据模型**: 10 个类型类，含 `NodeStatus`（审批状态/操作人/时间戳/意见）、`EdgeTrail`（流转路径四态染色）、`MultiInstanceStatus`（会签进度）、`ApprovalOverlayConfig`（覆盖层参数）
- **`StatusOverlayRenderer`**: 节点状态内边框 + 角标渲染，连线流转路径着色，脉冲动画（setTimeout 驱动）
- **3 套预设配色**: `CLASSIC`（琥珀蓝）、`GOVERNMENT`（红蓝灰）、`DARK`（暗色适配版）
- **`IApprovalAdapter` 可插拔适配器**: 解耦审批数据源，用户实现 `getNodeStatus()` / `getEdgeTrails()` 即可接入自有审批系统
- **`FlowableHistoryAdapter`**: Flowable 引擎历史数据适配器实现（6 项单元测试）
- **`ApprovalInfoPanel`**: 浮动信息面板，支持节点详情/操作人/意见/时间戳/会签子项展开 + 一键剪贴板复制
- **`ApprovalDemoPage`**: BPMN Kitchen Sink + drawio Swimlane 双格式审批场景全量 mock 演示
- `FlowViewer` 新增 5 个审批 Props: `nodeStatuses`、`edgeTrails`、`approvalConfig`、`approvalColorPreset`、`onNodeDecorator`

### Added — 审批流视觉细节

- 节点内边框（椭圆事件、矩形任务自适应）
- 角标与边框角 1/4 重叠贴合
- `isInterrupting=false` 虚线双层圆（非中断型）vs 实线双层圆（中断型）
- 任务图标左移 2px + taskIconOffset 可配置

### Changed — 工程化

- **Demo 分离**至 `hm_flow_kit_feat` 独立仓库，本项目回归纯库（HAR）
- **SdkVersion 降级**: 6.1.0(23) → 5.0.1(13)，兼容政企 HarmonyOS 5.0 设备
- 调试侧边栏 `debugMode` prop 移除，侧边栏常驻可用
- `showGrid` 默认值改为 `false`

### Added — Public API

- `NodeStatus`, `NodeStatusMap`, `EdgeTrail`, `EdgeTrailKind`, `MultiInstanceStatus`
- `ApprovalOverlayConfig`, `ApprovalStatusColorMap`, `StatusColor`, `BadgePosition`
- `ApprovalColorPresets`, `PresetId`, `StatusOverlayRenderer`
- `IApprovalAdapter`, `FlowableHistoryAdapter`, `FlowableActivity`
- `ApprovalInfoPanel`, `OnNodeDecorator`, `NodeDrawRect`

### Tests

- ApprovalTypes 15 项 + FlowableHistoryAdapter 6 项，总计 255 项编译通过

## [1.1.0] - 2026-06-24

### Added — Drawio Support (Phase 8)

- **`DrawioXmlParser`** (~500 行): mxGraph XML → GraphModel，两趟构建、HTML 净化、perimeter 路由自动补全
- **`DrawioStyleParser`** (~240 行): drawio style 字符串解析，形状检测 + 属性映射
- **`DrawioNodeDrawer`** (~340 行): 基础几何形状渲染（矩形/菱形/椭圆/三角形/圆柱/圆角矩形）+ 多行文本
- **BPMN 2.0 drawio 形状全映射**: 8 种 Event（outline）、2 种 Gateway 格式（新旧）、8 种 Task（taskMarker）、SubProcess/CallActivity、DataObject/DataStore、Annotation、Swimlane/Pool
- **EdgeRenderer 扩展**: bezier 曲线 + `_endArrow`/`_startArrow` 支持 + per-edge 颜色
- **`GraphNode.type` 放宽**: `NodeType` enum → `string`，registry 注册表模式（`NodeRenderer.register()`）
- **`INodeDrawer` 接口导出**: 用户可注册自定义形状 Drawer
- `FlowViewer` 新增 `@Prop drawioXml: string` prop
- Demo 页面文件选择器支持 `.drawio` / `.xml` 文件

### Added — Cross-Format Shape Configuration (Phase 9)

- **`ShapeConfig.ets`** (~70 行): `PerimeterKind` 注册表 + `ShapeDefinition` 注册表，跨格式统一配置层
- 22 种类型预填充：Visio/UML 只需加映射即可接入

### Added — Data-Driven Shape Geometry (Phase 10)

- **`ShapeDefinition.ets`** (100 行): `PerimeterPoint` + `ShapeRenderKind` (NATIVE_ELLIPSE/NATIVE_RHOMBUS/POLYLINE) + 4 canon 路径
- **`PerimeterRouter.ets`** (85 行): 椭圆/菱形/矩形连续数学 perimeter 交点计算
- **`PathRenderer.ets`** (135 行): 按 ShapeDefinition.renderKind 分发渲染
- **`TextUtils.ets`**: 5 个 Drawer 中重复的 `sanitizeLabel()` 提取为共享工具
- 6 个 BPMN Drawer 全部切换轮廓绘制至 PathRenderer
- `DrawioXmlParser` 3 个旧 perimeter 方法替换为 PerimeterRouter

### Added — Drawio Cross-Functional Flowchart (swinlane.drawio)

- `table` > `tableRow` > `swimlane` 嵌套层级坐标累加
- Edge waypoint 坐标累加修复跨 swimlane 连线偏移
- `PerimeterSegmentKind` 枚举（LINE/QUAD）→ `DOCUMENT_PERIMETER` 5 点波浪底边
- `drawio.table` / `drawio.tableRow` 容器头栏渲染
- `drawio.document`（PathRenderer 波浪底）/ `drawio.process`（粗边框）形状识别
- `drawio.swimlane` 默认垂直列布局（CF 流程图）
- Swimlane/tableRow/table 无 label 时跳过 header 背景

### Added — Debug Sidebar

- `debug/DebugTypes.ets` (88 行): 12 个共享调试类型类
- `debug/DebugCollector.ets` (286 行): 数据收集器，13 个查询方法 + 环形计时缓冲
- `components/DebugSidebar.ets` (537 行): 7 区段可折叠面板（概览/节点/边/Pool/统计/时间线/性能）
- `FlowViewer` 新增 `@Prop debugMode: boolean`
- Parser 扩展: `ParseMeta` (BPMN) + `DrawioParseMeta` (drawio) — 解析期间收集元数据
- "i" 按钮（左下角，与侧边栏互斥）

### Added — Public API

- `DrawioXmlParser`, `DrawioParseResult`, `DrawioParseMeta`, `DiagramInfo` exported
- `DrawioStyleParser`, `DrawioStyle`, `DrawioNodeDrawer` exported
- `ShapeConfig`, `PerimeterKind`, `INodeDrawer` exported
- `FlowViewer.@Prop drawioXml`, `FlowViewer.@Prop debugMode`

### Changed

- 66 new tests: DrawioStyleParser(47) + DrawioXmlParser(19), total 186 项编译通过
- Total 234 项编译通过（含 DebugCollector 13 + BpmnXmlParser ParseMeta 5 + ShapeDefinition 9 + PerimeterRouter 10）

## [1.0.0] - 2026-06-22

### Added — Canvas Rotation (Phase 7)

- **Canvas rotation**: 0° / 90° / 180° / 270° clockwise rotate button in FlowViewer
- Rotation transform applied via Canvas context, offset compensated through inverse rotation matrix R⁻¹
- All screen↔canvas coordinate conversions (pan, zoomAt, zoomTo, hit test) corrected for rotation
- Grid rendering, NodeRenderer, EdgeRenderer, PoolLaneRenderer all rotation-aware

### Added — Grid Rendering Optimization

- Dot grid auto-skips rendering when visible dots exceed 5,000 (prevents performance degradation at extreme zoom-out)

### Fixed

- **boundaryEvent**: corrected rendering and hit-test behavior
- Repository URL updated: gitee → GitHub (`https://github.com/liz7up/hm_flow_kit`)

### Changed

- `oh-package.json5` version → `1.0.0`
- README updated with Phase 7 features, README.md as primary documentation

### Milestone

- **Production-ready 1.0** — Published to OHPM central registry. 6 major phases, 120 tests, ~5,000 lines ArkTS. Zero third-party dependencies. Compatible with OpenHarmony 5.0+ / HarmonyOS 5.0+.

## [0.2.0] - 2026-06-20

### Added — BPMN Full Coverage (Phase 3)

- **13 NodeType enum**: TASK, START_EVENT, END_EVENT, GATEWAY, BOUNDARY_EVENT, INTERMEDIATE_THROW_EVENT, INTERMEDIATE_CATCH_EVENT, DATA_OBJECT, DATA_STORE, TEXT_ANNOTATION, DATA_INPUT, DATA_OUTPUT, GROUP
- **7 per-type drawers**: TaskDrawer, GatewayDrawer, EventDrawer, SubProcessDrawer, DataDrawer, AnnotationDrawer (exported, user-extensible)
- **10 event definition icons**: timer (clock), message (envelope), error (lightning), signal (triangle), terminate (filled circle), cancel (X-circle), compensate (double-arrow), escalation (up-arrow), conditional (ruled-page), link (arrow)
- **7 task type icons**: userTask (person), serviceTask (gear), scriptTask (script), manualTask (hand), sendTask (filled envelope), receiveTask (outline envelope), businessRuleTask (table/grid)
- **3 SubProcess border styles**: single-line (default), double-line (transaction), dashed (eventSubProcess)
- **Multi-instance markers**: `≡` sequential, `|||` parallel, `↻` loop (Canvas-drawn inside task)
- **callActivity** with [+] marker below border
- **isInterrupting=false** → dashed border for startEvent / intermediateCatchEvent / boundaryEvent
- **textAnnotation** bracket with pixel-perfect word-wrap, **dataStore** cylinder, **dataObject**
- **Association** + **DataAssociation** dashed edge rendering (deferred dataAssoc capture via TEXT events + post-parse processing)
- **5-layer Z-order**: Pool → SubProcess (bg) → Edges → Regular → Boundary → SubProcess (collapsed)
- 16 new parser + NodeType tests (118 → 120 total)
- `currentAttrs` save/restore stack to prevent cross-element pollution
- 7 visual bugs fixed: gateway markers, textAnnotation, dataStore, task icons, dataAssoc edges

### Added — Style Unification (Phase 4)

- **~30 design tokens** in `RenderConfig` replacing ~50 hardcoded values across all drawers
- `cornerRadiusRatio` replacing absolute `cornerRadius` (pixel-perfect defaults unchanged)
- `textBaseline` unified to `"middle"` across all 6 drawers + EdgeRenderer
- `layerPriorities` config map for customizable Z-order
- All renderers (6 drawers + EdgeRenderer + HitTestManager + FlowViewer) driven by config tokens

### Added — Monochrome + Dark Mode (Phase 5)

- **Default monochrome palette**: all strokes/text `#000`, fills `#FFF`, task subtypes via line weight
- **`RenderConfig.darkPreset()`** static factory for dark theme
- `FlowViewer` **`@StorageProp('currentColorMode')`** + `@Watch` auto-adapt to system theme
- `EntryAbility` AppStorage sync + `onConfigurationUpdate` for live light/dark switch
- `FlowViewer` **`@Prop renderConfig`** for user customization (protected from theme override by `_userConfig` flag)
- Canvas background follows theme, edge label background rect removed

### Added — Multi-Plane Drill-Down (Phase 6)

- **`PlaneHierarchy`** data model: `PlaneDefinition`, `BreadcrumbEntry`, parent-child chains
- **`BpmnXmlParser.parseHierarchy()`** with post-scan for diagram → plane routing + subProcess parent chains
- `FlowViewer` **`@Prop planeHierarchy`** + clickable breadcrumb navigation (`Root > Procure > Charge`)
- Expanded subProcess renders children in-place (layer 0 background container, centered label)
- Collapsed subProcess renders as interactive node (layer 4, blue `[+]` marker)
- **HitTest smallest-area priority** for nested elements (inner icon preferred over parent box)
- `BpmnViewerPage` with file picker for `.bpmn` / `.xml` files
- Demo buttons: Kitchen Sink, Nested Subprocess, Pizza Demo, 打开任意bpmn文件

### Added — Public API

- `TaskDrawer`, `GatewayDrawer`, `EventDrawer`, `SubProcessDrawer`, `DataDrawer`, `AnnotationDrawer` exported
- `PlaneHierarchy`, `PlaneDefinition`, `BreadcrumbEntry`, `ParseResult` exported
- `BpmnXmlParser.parseBestEffort()` → `ParseResult { model, warnings, isPartial }`

### Changed — DevOps

- `build.sh` daemon + flag trigger mode, `test_all.sh` merged into `build.sh` Step 3
- `FlowViewer` `@Prop model` accepts `GraphModel.createEmpty()` default

### Known Limitations

- Interactive editing (drag, connect, select) not yet implemented (deferred to Spec 04)
- Dagre auto-layout not yet implemented (deferred to Spec 05)
- PC wheel zoom blocked by HarmonyOS PC `onMouse`/`onWheel` API instability
- 4 event definition icons pending: Conditional, Escalation, Compensation, Link
- No Choreography / Conversation support
- 120 unit tests (compile-verified), but no visual regression / integration / perf tests

## [0.1.0] - 2026-06-15

### Added
- **GraphModel**: Immutable graph data model with node/edge CRUD, serialization, and viewport management
- **CanvasManager**: Viewport zoom, pan, and coordinate transformation (screen ↔ canvas)
- **NodeRenderer**: Static node rendering for rectangle, diamond, and circle shapes with centered labels
- **EdgeRenderer**: Static edge rendering with polyline waypoints and arrowheads
- **GridRenderer**: Configurable background grid (dots or lines)
- **HitTestManager**: Coordinate-to-element hit detection for nodes and edges
- **BpmnXmlParser**: Full BPMN 2.0 XML parsing with namespace support, BPMNShape/BPMNEdge coordinate extraction, and graceful fallback for missing BPMNDiagram
- **FlowViewer**: One-line embedded flow viewer component with auto-fit, click-to-highlight, and tap-blank-to-deselect
- **RenderConfig**: Centralized render configuration (colors, sizes, typography)
- 31 verification tests covering all core features
- Support for BPMN 2.0 task, startEvent, endEvent, exclusiveGateway, sequenceFlow, and labels
- Graceful fallback for XMLs without BPMNDiagram (auto-assigns default coordinates)

### Known Limitations
- Interactive editing (drag, connect, select) not yet implemented (deferred to Spec 04)
- Dagre auto-layout not yet implemented (deferred to Spec 05)
- Node labels overflow on small nodes (e.g., 36×36 circles)
- No BPMN 2.0 execution engine (rendering only)