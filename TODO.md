# hm-flow-kit — 项目覆盖场景与不足待办清单

> 最后更新：2026-06-20
> 基于：对项目代码、spec 文档、README 声明和已实现功能的全面巡视

---

## 一、当前实现状态总览

### ✅ 已完成

| Spec / Phase | 模块 | 规模 | 状态 |
|------|------|------|------|
| Spec 01 | GraphModel（图数据模型） | 890 行，44 项测试 | ✅ 完成 |
| Spec 02 | Canvas 渲染层 | ~3500 行总计 | ✅ 完成 |
|   | — NodeRenderer | 296 行 | ✅ |
|   | — EdgeRenderer | 226 行 | ✅ |
|   | — PoolLaneRenderer | 180 行 | ✅ |
|   | — CanvasManager | 350 行 | ✅ |
|   | — HitTestManager | 492 行 | ✅ |
|   | — RenderConfig | 120 行 | ✅ |
|   | — GridRenderer | 参考 CLAUDE.md | ✅ |
| Spec 03/v2 | BpmnXmlParser（BPMN 2.0 XML 解析器） | 662 行，39 项测试 | ✅ 完成 |
| Spec 06 | FlowViewer 组件 | 315 行 | ✅ 完成 |
| P1-1 | Pool/Lane 泳池泳道 | 数据模型 + 解析 + 渲染 + HitTest | ✅ 完成 |
| Phase 1 | 按类型分色样式系统 | RenderConfig 12+7 字段，NodeRenderer/EdgeRenderer 去硬编码 | ✅ 完成 |
| Phase 2 | 自动化单元测试 | 120 项测试，build.sh 编译验证 | ✅ 完成 |
| Phase 2 | Parser 错误恢复 + 类型默认尺寸 | parseBestEffort() / defaultNodeSize() | ✅ 完成 |
| Phase 3 | BPMN 全覆盖（Kitchen Sink 验收） | NodeType 4→13，6 新 Drawer，10 事件图标，7 任务图标，3 SubProcess 边框，5 层 Z-order | ✅ 完成 |
| Phase 4 | 风格统一 — RenderConfig design tokens | ~30 测量 token（cornerRadiusRatio, nodePadding, eventIconScale...），6 Drawer + Edge + HitTest + FlowViewer 去硬编码，textBaseline 统一 middle，layerPriorities 配置化绘制顺序 | ✅ 完成 |
| DevOps | build.sh daemon + flag 触发编译 | test_all.sh 合并进 build.sh Step 3，一次触发 HAR+HAP+Test 全部编译 | ✅ 完成 |
| TODO-3.5 | 渲染修复 | 见下方 3.5 详情 | ✅ 完成 |
|   | Gateway 内部标记（X / + / ○ / 五边形） | NodeRenderer 绘制 | ✅ |
|   | EventDefinition 图标（5 种） | 时钟/信封/闪电/三角/实心圆 | ✅ |
|   | Event 文字移出圆圈 | label 渲染在圆圈下方 | ✅ |
|   | Pool/Lane 标题横排 | canvas rotate(-PI/2) 连续横排 | ✅ |
|   | MessageFlow 解析 + 渲染 | 虚线 + 空心箭头 + 路径中点 label | ✅ |
|   | XML 字符引用预处理 | decodeXmlCharacterRefs() + label 净化 | ✅ |
|   | Pinch 双指缩放 + 浮动 +/- 按钮 | GestureGroup + Stack 覆盖层 | ✅ |
|   | FlowViewer fitToView 考虑泳池边界 | 自动适配内容缩放 | ✅ |

**当前总验收：120 项自动化单元测试编译通过**

### ⏳ 已推迟

| Spec | 内容 | 原因 |
|------|------|------|
| Spec 04 | 交互编辑层（DragController / ConnectController / SelectController） | 优先级调整 |
| Spec 05 | Dagre 自动布局 | 优先级调整 |
| FlowDesigner | 可编辑流程设计器组件 | 依赖 Spec 04 |

---

## 二、声明 vs 实际的 Gap

### 2.1 README 声明

**当前 README 声明已更新**，移除了审批自动着色、泳道等之前不实的声明。以下元素通过 fallback 映射支持：

- `businessRuleTask` → 映射到 `NodeType.TASK`，可正常渲染，但无子类型边框色（`taskSubtypeStroke` 中未注册）
- `callActivity` → 映射到 `NodeType.TASK`，使用通用 Task 渲染
- `subProcess` → 映射到 `NodeType.TASK`，使用通用 Task 渲染（无嵌套子流程展开）
- `eventBasedGateway` → 映射到 `NodeType.GATEWAY`，使用通用菱形渲染（无内部五边形标记映射）

### 2.2 BPMN 2.0 覆盖缺口

**A. 泳道 / Lane / Pool** ✅ 已完成

**B. BoundaryEvent attachToRef 逻辑**

- 严重性：高
- 当前状态：解析器支持 `boundaryEvent` 标签映射到 NodeType，但无 `attachedToRef` 属性解析
- 渲染层无边界事件附着逻辑（应绘制在宿主 Activity 边缘）
- 用户痛点：超时自动取消、错误回退等常见流程模式无法正确表达

**C. IntermediateThrowEvent / IntermediateCatchEvent**

- 严重性：中
- 当前状态：解析器已支持标签映射，EventDefinition 图标（timer/message/error/signal/terminate）已渲染
- 剩余缺口：ConditionalEventDefinition / EscalationEventDefinition / CompensationEventDefinition / LinkEventDefinition 图标未实现

**D. 连线类型**

- ✅ `SequenceFlow`（实线箭头）
- ✅ `MessageFlow`（虚线 + 空心箭头）
- 缺失：
  - `Association`（关联，虚线）— 用于注释/数据关联
  - `ConditionalFlow` / `DefaultFlow` — 条件流 / 默认流（视觉标记差异）
  - `DataAssociation` / `DataInputAssociation` / `DataOutputAssociation`

**E. BPMNDiagram / Choreography**

- ✅ `Collaboration`（多参与者）已支持
- 缺失：
  - 顶层 `BPMNDiagram` 包装解析
  - `Choreography` 完全不支持
  - `Conversation` 完全不支持

**F. DataObject / DataStore / DataInput / DataOutput**

- 严重性：中
- 当前状态：有意丢弃（非核心视觉元素）
- 用户痛点：数据流向可视化是 BPMN 的重要子集

**G. TextAnnotation / Group**

- 严重性：低
- 当前状态：有意丢弃

**H. 事件定义（EventDefinition）** ✅ 基本完成

- ✅ TimerEventDefinition（时钟图标）
- ✅ MessageEventDefinition（信封图标）
- ✅ ErrorEventDefinition（闪电图标）
- ✅ SignalEventDefinition（三角图标）
- ✅ TerminateEventDefinition（实心圆图标）
- 缺失：ConditionalEventDefinition / EscalationEventDefinition / CompensationEventDefinition / LinkEventDefinition / CancelEventDefinition

---

## 三、功能 Bug 与代码问题

### 3.1 RenderConfig + NodeRenderer 硬编码清理 ✅ 已修复 (2026-06-17)

### 3.2 FlowViewer 的 highlightNodeId 可能被错误清理 ✅ 已修复 (2026-06-17)

### 3.3 BpmnXmlParser 无错误恢复能力 ✅ 已修复 (2026-06-17)

### 3.4 hardcoded 节点尺寸 ✅ 已修复 (2026-06-17)

### 3.5 与 bpmn.io 对比发现的渲染问题 ✅ 已修复 (2026-06-18)

全部子项已修复：
1. Gateway 内部标记 + EventDefinition 图标
2. Event 文字移出圆圈显示在下方
3. Pool/Lane 标题横排（canvas rotate）
4. MessageFlow 虚线 + 空心箭头 + label
5. XML 字符引用预处理 + label 净化
6. Pinch 双指缩放 + 浮动 +/- 按钮

### 3.6 PC 滚轮缩放

- 现状：PC 端无滚轮缩放、无键盘快捷键缩放
- 期望：`Ctrl+滚轮` 或纯滚轮缩放画布（对标 bpmn.io、LogicFlow）
- 阻塞：HarmonyOS PC 端 ArkUI 的 `onMouse`/`onWheel` 事件 API 不稳定，建议等平台 API 成熟后再补
- 预计 API：`onMouse((event: MouseEvent) => { event.button; event.action; })` 或组件级 `onWheel` 回调

---

## 四、工程化 / DevOps 缺失

### 4.1 无 CI/CD

- 无 GitHub Actions / Gitee CI 配置
- 无自动编译验证流程
- 无自动测试运行流程
- 无代码覆盖率报告

### 4.2 无发布自动化

- 无 `ohpm publish` 脚本
- 无版本号自动递增规则
- 无 CHANGELOG.md
- 无 Release Note 模板

### 4.3 测试基础设施薄弱

- 当前测试：120 项纯手写单元测试
- 缺失：
  - 视觉回归测试（截图对比，确保渲染结果稳定）
  - 集成测试（BPMN XML → 解析 → 渲染 → HitTest 端到端）
  - 性能测试（大型 BPMN 图渲染帧率）
  - 模糊测试（畸形 XML 输入的鲁棒性）
  - 跨版本兼容测试（OpenHarmony 5.0 / HarmonyOS 5.0 不同 API Level）

### 4.4 无 API 文档自动生成

- 无 Typedoc / JSDoc 风格 API 参考
- Index.ets 导出项没有结构化文档
- 无法自动生成 ohpm 包详情页

### 4.5 无基准测试 (benchmark)

- 缺少大规模图（100+ 节点、500+ 连线）渲染性能数据
- 缺少缩放/平移操作帧率数据
- 无法衡量优化效果

---

## 五、开发者体验 (DX) 缺失

### 5.1 无 DevTools / 调试面板

**对标：** bpmn.js 有 bpmn-js-inspector、bpmn-js-properties-panel

**当前：** 零调试辅助。用户调试流程：
1. 无法查看 GraphModel 当前状态（节点数、边数）
2. 无法查看 HitTest 命中区域
3. 无法查看 CanvasManager 变换矩阵
4. 无法查看渲染帧率和重绘次数

### 5.2 错误消息不友好

**当前：**
```typescript
throw new Error(`Unknown element: ${elementName}`);
```

**建议：**
```typescript
throw new BpmnParseError(
  `Unsupported BPMN element '<${elementName}>' at line ${line}. ` +
  `Supported elements: task, userTask, startEvent, endEvent, exclusiveGateway, parallelGateway, sequenceFlow. ` +
  `See https://github.com/xxx/hm-flow-kit/docs/bpmn-coverage for full coverage matrix.`
);
```

### 5.3 Example 代码 ✅ 已修复 (2026-06-17)

- `examples/hello-graph/MainPage.ets` — 代码构建 GraphModel + FlowViewer 渲染
- `examples/bpmn-viewer/MainPage.ets` — BPMN XML 解析 + 渲染

### 5.4 无插件/扩展机制

- 当前所有节点类型硬编码在 Renderer 中
- 用户无法注册自定义节点类型（如行业特定图标）
- 对标 LogicFlow 的 `register` 机制完全缺失

---

## 六、代码质量 / 架构债务

### 6.1 NodeRenderer 可扩展性不足

**当前：** `NodeRenderer.render()` 中通过 `node.type` 分发到不同绘制逻辑。每增加一种节点类型就需要修改 switch / if-else 分支。

**建议：** 策略模式 / 注册表模式：
```typescript
interface INodeDrawer { draw(ctx, node, config): void }
const nodeDrawers = new Map<NodeType, INodeDrawer>()
nodeDrawers.set('task', new TaskDrawer())
nodeDrawers.set('exclusiveGateway', new GatewayDrawer())
// 用户可注册自定义 drawer
```

### 6.2 Zoom 性能

- 当前缩放时**全量重绘**所有节点和边
- 没有脏区域标记（dirty rect）或增量渲染
- 没有视口裁剪（viewport culling）— 视口外的节点仍然参与渲染计算

### 6.3 无内存管理

- `HitTestManager.rebuild()` 每次全量重建空间索引
- 没有对象池（Object Pool）
- 大图场景下可能频繁 GC

### 6.4 主题系统

- ✅ RenderConfig 已有 ~80 个样式/度量字段（含 Phase 4 design tokens），可完整控制颜色、线宽、间距、比例
- ⚠️ 缺失一键切换预设主题（深色模式、品牌色）的便捷 API
- ⚠️ 对标 bpmn.js 的 theming 能力，便捷性有差距

### 6.5 文件规模

- NodeRenderer.ets（296 行）随节点类型线性增长，建议按类型拆分为 `renderers/TaskRenderer.ets`、`renderers/GatewayRenderer.ets`、`renderers/EventRenderer.ets` 等

---

## 七、BPMN 2.0 规范覆盖矩阵

| BPMN 元素 | 解析 | 渲染 | 交互 | 备注 |
|-----------|------|------|------|------|
| **Activities** |||||
| Task | ✅ | ✅ | ❌ | 通用任务 |
| UserTask | ✅ | ✅ | ❌ | |
| ServiceTask | ✅ | ✅ | ❌ | |
| ScriptTask | ✅ | ✅ | ❌ | |
| ManualTask | ✅ | ✅ | ❌ | |
| SendTask | ✅ | ✅ | ❌ | |
| ReceiveTask | ✅ | ✅ | ❌ | |
| BusinessRuleTask | ✅ | ✅(Task) | ❌ | 映射为通用 Task，无专属子类型色 |
| CallActivity | ✅ | ✅(Task) | ❌ | 映射为通用 Task |
| SubProcess | ✅ | ✅(Task) | ❌ | 映射为通用 Task，无嵌套展开 |
| AdHocSubProcess | ❌ | ❌ | ❌ | |
| Transaction | ❌ | ❌ | ❌ | |
| **Events** |||||
| StartEvent (None) | ✅ | ✅ | ❌ | 空心圆 |
| EndEvent (None) | ✅ | ✅ | ❌ | 实心圆 |
| StartEvent (Timer) | ✅ | ✅ | ❌ | 含时钟图标 |
| StartEvent (Message) | ✅ | ✅ | ❌ | 含信封图标 |
| StartEvent (Signal) | ✅ | ✅ | ❌ | 含三角图标 |
| StartEvent (Error) | ✅ | ✅ | ❌ | 含闪电图标 |
| EndEvent (Error) | ✅ | ✅ | ❌ | 含闪电图标 |
| EndEvent (Message) | ✅ | ✅ | ❌ | 含信封图标 |
| EndEvent (Signal) | ✅ | ✅ | ❌ | 含三角图标 |
| EndEvent (Terminate) | ✅ | ✅ | ❌ | 含实心圆图标 |
| EndEvent (Escalation) | ❌ | ❌ | ❌ | |
| EndEvent (Compensation) | ❌ | ❌ | ❌ | |
| IntermediateThrowEvent | ✅ | ✅ | ❌ | 含 EventDefinition 图标 |
| IntermediateCatchEvent | ✅ | ✅ | ❌ | 含 EventDefinition 图标 |
| BoundaryEvent | ⚠️ | ⚠️ | ❌ | 解析标签但不处理 attachedToRef |
| **Gateways** |||||
| ExclusiveGateway | ✅ | ✅ | ❌ | 菱形 + X 标记 |
| ParallelGateway | ✅ | ✅ | ❌ | 菱形 + + 标记 |
| InclusiveGateway | ✅ | ✅ | ❌ | 菱形 + ○ 标记 |
| EventBasedGateway | ✅ | ✅(菱形) | ❌ | 映射为通用 Gateway |
| ComplexGateway | ❌ | ❌ | ❌ | |
| **Flows** |||||
| SequenceFlow | ✅ | ✅ | ❌ | 直线 + 实心箭头，Waypoint 支持 |
| ConditionalFlow | ❌ | ❌ | ❌ | |
| DefaultFlow | ❌ | ❌ | ❌ | |
| MessageFlow | ✅ | ✅ | ❌ | 虚线 + 空心箭头 |
| Association | ❌ | ❌ | ❌ | |
| DataAssociation | ❌ | ❌ | ❌ | |
| **Swimlanes** |||||
| Pool | ✅ | ✅ | ❌ | 含标题栏 |
| Lane | ✅ | ✅ | ❌ | 含嵌套 Lane + 标题栏 |
| **Data** |||||
| DataObject | ❌ | ❌ | ❌ | 有意丢弃 |
| DataStore | ❌ | ❌ | ❌ | 有意丢弃 |
| DataInput | ❌ | ❌ | ❌ | 有意丢弃 |
| DataOutput | ❌ | ❌ | ❌ | 有意丢弃 |
| **Artifacts** |||||
| TextAnnotation | ❌ | ❌ | ❌ | 有意丢弃 |
| Group | ❌ | ❌ | ❌ | 有意丢弃 |
| **其他** |||||
| Collaboration | ✅ | ✅ | ❌ | 多 Pool + 共享 Process |
| Choreography | ❌ | ❌ | ❌ | |
| Conversation | ❌ | ❌ | ❌ | |
| BPMNDiagram | ⚠️ | — | ❌ | 解析但未作为顶层容器 |
| EventDefinition | ✅ | ✅ | ❌ | 5/9 种图标（timer/message/error/signal/terminate）|
| ExtensionElements | ❌ | ❌ | ❌ | |

---

## 八、优先修复建议

### 🔴 P0 — 立即修复（阻碍基本使用）

1. **BoundaryEvent attachToRef** — 解析 `attachedToRef` 属性 + 渲染附着在宿主 Activity 边缘
2. **Spec 04 交互编辑层** — DragController、ConnectController、SelectController
3. **FlowDesigner 组件** — 用户可拖拽节点、连线编辑（依赖 Spec 04）

### 🟡 P2 — 中优先级（完善 BPMN 覆盖）

4. 中间事件缺失的 EventDefinition 图标（Conditional / Escalation / Compensation / Link / Cancel / Multiple / ParallelMultiple）
5. ConditionalFlow + DefaultFlow 视觉标记
6. DataObject / DataStore（如确认非"有意丢弃"）
7. 连线 Waypoint 曲线渲染（非直线）
8. EventBasedGateway 专属五边形套圆标记

### 🟢 P3 — 低优先级（体验优化）

9. 主题系统（浅色/深色模式切换）
10. 视口裁剪优化（viewport culling）
11. 自定义节点类型注册机制（插件系统）
12. 开发者调试面板（DevTools）
13. CI/CD 自动化流水线
14. NodeRenderer 策略模式拆分

### 🔵 P4 — 远期规划

15. Dagre 自动布局（Spec 05）
16. CallActivity / SubProcess 专属渲染（展开/折叠）
17. 性能基准测试套件
18. API 文档自动生成
19. ohpm 正式发布
20. PC 滚轮缩放（等待鸿蒙 API 稳定）

---

## 九、竞争对比（简要）

| 能力 | bpmn.js | LogicFlow | AntV X6 | hm-flow-kit (当前) |
|------|---------|-----------|---------|-------------------|
| BPMN 2.0 XML 解析 | ✅ 完整 | ✅ 插件 | ❌ | ✅ 基础覆盖 + 泳道 |
| 可视化编辑器 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ❌ |
| 泳道支持 | ✅ | ⚠️ 有限 | ⚠️ 有限 | ✅ |
| EventDefinition 图标 | ✅ 完整 | ⚠️ 部分 | ⚠️ 部分 | ✅ 5/9 种 |
| MessageFlow | ✅ | ⚠️ | ⚠️ | ✅ 虚线+空心箭头 |
| 自定义节点 | ✅ | ✅ | ✅ | ❌ |
| 主题系统 | ✅ | ✅ | ✅ | ❌ |
| 插件机制 | ✅ | ✅ | ✅ | ❌ |
| 属性面板 | ✅ | ✅ | ✅ | ❌ |
| 自动布局 | ✅ (elkjs) | ✅ (dagre) | ✅ (dagre) | ❌ |
| 导入/导出 BPMN | ✅ | ✅ 插件 | ❌ | ⚠️ 仅导入 |
| 导出 SVG/PNG | ✅ | ✅ | ✅ | ❌ |
| 协同编辑 | ❌ (需后端) | ❌ | ❌ | ❌ |
| 鸿蒙原生 | ❌ | ❌ | ❌ | ✅ (唯一优势) |
| 零依赖 | ❌ | ❌ | ❌ | ✅ |
| ohpm 安装 | ❌ | ❌ | ❌ | ⚠️ 规划中 |

**结论：** 当前唯一差异化优势是**鸿蒙原生** + **零依赖**。泳道、MessageFlow、EventDefinition 图标已补上关键短板。P0 优先攻克 BoundaryEvent + 交互编辑层。

---

*本文档由项目巡视自动生成，欢迎 PR 补充和修正。*