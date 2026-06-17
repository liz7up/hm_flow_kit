# hm-flow-kit — 项目覆盖场景与不足待办清单

> 创建日期：2025-07-17
> 基于：对项目代码、spec 文档、README 声明和已实现功能的全面巡视

---

## 一、当前实现状态总览

### ✅ 已完成（4 个 Spec，31/31 测试通过）

| Spec | 模块 | 规模 | 状态 |
|------|------|------|------|
| Spec 01 | GraphModel（图数据模型） | 268 行，7 项测试 | ✅ 完成 |
| Spec 02 | Canvas 渲染层（NodeRenderer / EdgeRenderer / GridRenderer / CanvasManager / HitTestManager） | ~1350 行，14 项测试 | ✅ 完成 |
| Spec 03 | BpmnXmlParser（BPMN 2.0 XML 解析器） | 507 行，12 项测试 | ✅ 完成 |
| Spec 06 | FlowViewer 组件 | 186 行 | ✅ 完成 |

### ⏳ 已推迟

| Spec | 内容 | 原因 |
|------|------|------|
| Spec 04 | 交互编辑层（DragController / ConnectController / SelectController） | 优先级调整 |
| Spec 05 | Dagre 自动布局 | 优先级调整 |
| FlowDesigner | 可编辑流程设计器组件 | 依赖 Spec 04 |

---

## 二、声明 vs 实际的 Gap

### 2.1 README 不实声明

**问题：README.md 第 23 行**

> "✅ Supported: StartEvent, EndEvent, Task, UserTask, ServiceTask, ScriptTask, ManualTask, BusinessRuleTask, SendTask, ReceiveTask, **CallActivity**, **SubProcess**, ExclusiveGateway, ParallelGateway, InclusiveGateway, SequenceFlow"

**事实：**

- `CallActivity` → BpmnXmlParser 中 **未注册**。代码第 53-58 行只有 6 种 typeMapping：`userTask/scriptTask/serviceTask/sendTask/receiveTask/manualTask` + 默认 fallback `task`。没有 `callActivity`。
- `SubProcess` → BpmnXmlParser 中 **未注册**。当前解析器只处理顶层的 `process/task/startEvent/endEvent/*Gateway/sequenceFlow`，没有任何子流程（nested subProcess）解析逻辑。
- `BusinessRuleTask` → README 声称支持，但 typeMapping 中没有。fallback 到普通 `task` 可渲染但丢失了类型差异。

### 2.2 BPMN 2.0 覆盖缺口

**A. 泳道 / Lane / Pool（覆盖场景：跨部门流程、组织架构图）**

- 严重性：高
- 当前状态：完全未实现
- GraphModel 没有 Lane/Pool 数据结构
- BpmnXmlParser 不解析 `laneSet`、`lane`、`participant`、`collaboration` 标签
- 渲染层无泳道绘制逻辑
- 用户痛点：这是企业 BPMN 图最常用的特性之一，无泳道意味着无法表示"谁做什么"

**B. BoundaryEvent（覆盖场景：超时、错误、补偿、信号等边界事件）**

- 严重性：高
- 当前状态：完全未实现
- typeMapping 中无 `boundaryEvent`
- 无 attachToRef 解析逻辑
- 渲染层无边界事件绘制（通常附着在 Activity 边缘）
- 用户痛点：超时自动取消、错误回退等常见流程模式无法表达

**C. IntermediateThrowEvent / IntermediateCatchEvent（覆盖场景：消息、定时器、信号中间事件）**

- 严重性：中高
- 当前状态：完全未实现
- 用户痛点：无法表示"等待消息""发送通知"等中间事件节点

**D. 连线类型单一**

- 当前：仅支持 `SequenceFlow`（实线箭头）
- 缺失：
  - `MessageFlow`（消息流，虚线 + 空心箭头）— 常见于泳道间通信
  - `Association`（关联，虚线）— 用于注释/数据关联
  - `ConditionalFlow` / `DefaultFlow` — 条件流 / 默认流（视觉标记差异）
  - `DataAssociation` / `DataInputAssociation` / `DataOutputAssociation`

**E. BPMNDiagram / Collaboration / Choreography**

- 当前只解析单一 `process` 元素
- 不解析顶层的 `BPMNDiagram` 包装
- 不解析 `Collaboration`（多参与者）
- 不解析 `Choreography`

**F. DataObject / DataStore / DataInput / DataOutput（覆盖场景：数据驱动流程图）**

- 严重性：中
- 当前状态：完全未实现
- 用户痛点：数据流向可视化是 BPMN 的重要子集

**G. TextAnnotation / Group（覆盖场景：流程注释、分组标记）**

- 严重性：低
- 当前状态：完全未实现

**H. 事件定义（EventDefinition）**

- 当前：所有 Event 渲染为通用空心/实心圆
- 缺失：
  - TimerEventDefinition（时钟图标）
  - MessageEventDefinition（信封图标）
  - ErrorEventDefinition（闪电图标）
  - SignalEventDefinition（三角图标）
  - EscalationEventDefinition（上箭头图标）
  - ConditionalEventDefinition
  - CompensationEventDefinition

---

## 三、功能 Bug 与代码问题

### 3.1 RenderConfig + NodeRenderer 硬编码清理 ✅ 已修复 (2026-06-17)

**修复内容：**
- RenderConfig 新增 12 个按 NodeType 分色字段 + `taskSubtypeStroke` 子类型边框色映射
- NodeRenderer 7 处硬编码替换为 config 读取
- EdgeRenderer 新增 `config: RenderConfig` 参数，5 处硬编码替换
- BpmnXmlParser 存储原始标签名到 `properties['bpmnElement']`
- 颜色方案不与高亮蓝色冲突（Task 默认白底+灰边框）

### 3.2 FlowViewer 的 highlightNodeId 可能被错误清理

**文件：** `hmflowkit/src/main/ets/components/FlowViewer.ets`

**问题：** 点击高亮逻辑中，每次重绘前都执行 `this.highlightNodeId = ''`，但如果此前通过外部手段设置了 `highlightNodeId`，有可能被清掉，造成状态不一致。

**建议：** 明确区分"用户点击高亮"和"外部 API 高亮"，或使用 `@State highlightNodeId: string` 作为内部状态，新增 `@Prop externalHighlightId` 分离外部控制。

### 3.3 BpmnXmlParser 无错误恢复能力

**当前行为：** 遇到任何 XML 结构错误直接抛异常，整个解析失败。

**建议：**
- 增加宽松解析模式（best-effort）：未知元素跳过并记录警告，继续解析剩余内容
- 增加诊断信息收集：记录每个跳过的元素及其行号，供上层展示

### 3.4 hardcoded 节点尺寸

**位置：** BpmnXmlParser 第 ~180 行

```typescript
const width = 120;  // 硬编码
const height = 60;  // 硬编码
```

**问题：** 当 BPMN XML 的 BPMNShape 未提供宽高时使用 hardcoded 默认值。不同节点类型（Gateway 菱形 vs Task 矩形）应有不同的默认尺寸。

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

- 当前测试：纯手写单元测试（31 项）
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

### 5.3 无 example 代码更新

- `examples/hello-graph/` 和 `examples/bpmn-viewer/` 目录存在但内容为空
- 用户无法通过示例快速上手

### 5.4 无插件/扩展机制

- 当前所有节点类型硬编码在 Renderer 中
- 用户无法注册自定义节点类型（如行业特定图标）
- 对标 LogicFlow 的 `register` 机制完全缺失

---

## 六、代码质量 / 架构债务

### 6.1 NodeRenderer 可扩展性不足

**当前：** `NodeRenderer.render()` 中用一个大的 `switch (node.type)` 处理所有节点类型的绘制逻辑。每增加一种节点类型就需要修改这个 switch。

**建议：** 策略模式 / 注册表模式：

```typescript
// 建议架构
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

### 6.4 无主题系统

- 所有颜色/样式硬编码在 RenderConfig 中
- 用户无法一键切换深色模式或品牌色
- 对标 bpmn.js 的 theming 能力有差距

### 6.5 文件规模

- NodeRenderer.ets 随节点类型线性增长，未来会成为单片巨石
- 建议拆分为 `renderers/TaskRenderer.ets`、`renderers/GatewayRenderer.ets`、`renderers/EventRenderer.ets` 等

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
| BusinessRuleTask | ⚠️ | ✅(fallback) | ❌ | 无类型映射，fallback 为普通 Task |
| CallActivity | ❌ | ❌ | ❌ | README 声称支持 |
| SubProcess | ❌ | ❌ | ❌ | README 声称支持 |
| AdHocSubProcess | ❌ | ❌ | ❌ | |
| Transaction | ❌ | ❌ | ❌ | |
| CallableElement | ❌ | ❌ | ❌ | |
| **Events** |||||
| StartEvent (None) | ✅ | ✅ | ❌ | 仅空心圆 |
| EndEvent (None) | ✅ | ✅ | ❌ | 仅实心圆 |
| StartEvent (Timer) | ❌ | ❌ | ❌ | |
| StartEvent (Message) | ❌ | ❌ | ❌ | |
| StartEvent (Signal) | ❌ | ❌ | ❌ | |
| StartEvent (Error) | ❌ | ❌ | ❌ | |
| StartEvent (Conditional) | ❌ | ❌ | ❌ | |
| EndEvent (Error) | ❌ | ❌ | ❌ | |
| EndEvent (Message) | ❌ | ❌ | ❌ | |
| EndEvent (Signal) | ❌ | ❌ | ❌ | |
| EndEvent (Terminate) | ❌ | ❌ | ❌ | |
| EndEvent (Escalation) | ❌ | ❌ | ❌ | |
| EndEvent (Compensation) | ❌ | ❌ | ❌ | |
| IntermediateThrowEvent | ❌ | ❌ | ❌ | |
| IntermediateCatchEvent | ❌ | ❌ | ❌ | |
| BoundaryEvent | ❌ | ❌ | ❌ | 高优先级缺失 |
| **Gateways** |||||
| ExclusiveGateway | ✅ | ✅ | ❌ | 菱形 + X |
| ParallelGateway | ✅ | ✅ | ❌ | 菱形 + + |
| InclusiveGateway | ✅ | ✅ | ❌ | 菱形 + O |
| ComplexGateway | ❌ | ❌ | ❌ | |
| EventBasedGateway | ❌ | ❌ | ❌ | |
| **Flows** |||||
| SequenceFlow | ✅ | ✅ | ❌ | 仅直线，无 Waypoint 曲线 |
| ConditionalFlow | ❌ | ❌ | ❌ | |
| DefaultFlow | ❌ | ❌ | ❌ | |
| MessageFlow | ❌ | ❌ | ❌ | |
| Association | ❌ | ❌ | ❌ | |
| DataAssociation | ❌ | ❌ | ❌ | |
| **Swimlanes** |||||
| Pool | ❌ | ❌ | ❌ | |
| Lane | ❌ | ❌ | ❌ | |
| **Data** |||||
| DataObject | ❌ | ❌ | ❌ | |
| DataStore | ❌ | ❌ | ❌ | |
| DataInput | ❌ | ❌ | ❌ | |
| DataOutput | ❌ | ❌ | ❌ | |
| **Artifacts** |||||
| TextAnnotation | ❌ | ❌ | ❌ | |
| Group | ❌ | ❌ | ❌ | |
| **其他** |||||
| Collaboration | ❌ | ❌ | ❌ | |
| Choreography | ❌ | ❌ | ❌ | |
| Conversation | ❌ | ❌ | ❌ | |
| Message | ❌ | ❌ | ❌ | |
| Signal | ❌ | ❌ | ❌ | |
| Error | ❌ | ❌ | ❌ | |
| Escalation | ❌ | ❌ | ❌ | |
| Compensation | ❌ | ❌ | ❌ | |
| BPMNDiagram | ❌ | ❌ | ❌ | 顶层容器 |
| Category / CategoryValue | ❌ | ❌ | ❌ | |
| ExtensionElements | ❌ | ❌ | ❌ | |

---

## 八、优先修复建议

### 🔴 P0 — 立即修复（阻碍基本使用）

1. ~~**RenderConfig 默认颜色字段为空**~~ ✅ **已修复 (2026-06-17)** — NodeRenderer/EdgeRenderer 全部去硬编码，新增 12+7 个按类型分色字段
2. ~~**修正 README 中不实的支持声明**~~ ✅ **已修复 (2026-06-17)** — 移除审批自动着色、泳道等虚假声明，新增准确覆盖矩阵，修正 API 文档
3. ~~**补齐 `examples/` 目录下的可运行示例**~~ ✅ **已修复 (2026-06-17)** — `examples/hello-graph/MainPage.ets` + `examples/bpmn-viewer/MainPage.ets`

### 🟠 P1 — 高优先级（核心功能缺口）

4. **实现泳道（Pool / Lane）** — BPMN 解析 + 数据结构 + 渲染
5. **实现 BoundaryEvent 解析与渲染** — 包括 attachToRef 逻辑
6. **实现 Spec 04 交互编辑层** — DragController、ConnectController、SelectController
7. **实现 FlowDesigner 组件** — 用户可拖拽节点、连线编辑

### 🟡 P2 — 中优先级（完善 BPMN 覆盖）

8. 中间事件（IntermediateThrowEvent / IntermediateCatchEvent）+ 事件定义图标
9. MessageFlow + ConditionalFlow + DefaultFlow
10. DataObject / DataStore
11. 连线 Waypoint 曲线渲染（非直线）

### 🟢 P3 — 低优先级（体验优化）

12. 主题系统（浅色/深色模式切换）
13. 视口裁剪优化（viewport culling）
14. 自定义节点类型注册机制（插件系统）
15. 开发者调试面板（DevTools）
16. CI/CD 自动化流水线

### 🔵 P4 — 远期规划

17. Dagre 自动布局（Spec 05）
18. 性能基准测试套件
19. API 文档自动生成
20. ohpm 正式发布

---

## 九、竞争对比（简要）

| 能力 | bpmn.js | LogicFlow | AntV X6 | hm-flow-kit (当前) |
|------|---------|-----------|---------|-------------------|
| BPMN 2.0 XML 解析 | ✅ 完整 | ✅ 插件 | ❌ | ⚠️ 基础覆盖 |
| 可视化编辑器 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ❌ |
| 泳道支持 | ✅ | ⚠️ 有限 | ⚠️ 有限 | ❌ |
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

**结论：** 当前唯一差异化优势是**鸿蒙原生** + **零依赖**。在 BPMN 功能完整性上与其他成熟方案相比差距很大，但这两个差异化点如果抓住，在鸿蒙生态中是有明确利基市场的。

---

*本文档由项目巡视自动生成，欢迎 PR 补充和修正。*