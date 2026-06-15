# Spec 03 — BPMN 2.0 XML 解析器

**状态：已完成 ✅**
**依赖：MM0 01（GraphModel 数据层）**
**MVP 里程碑：M1 只读渲染的完结**

---

## 目标

实现 BPMN 2.0 XML 解析器，将 bpmn.js 导出的标准 BPMN XML 转换为 `GraphModel` 实例（节点 + 连线 + 坐标）。

---

## 输入

- `xml: string` — 完整的 BPMN 2.0 XML 字符串，格式兼容 bpmn.js 输出。

## 输出

- 成功：返回包含节点和连线的 `GraphModel` 实例（不可变构造）。
- 失败：抛出 `BpmnParseError`，包含描述信息。

---

## 范围（MVP 支持的元素）

### 支持的 BPMN 语义元素

| BPMN 元素 | 映射到的 NodeType / EdgeStyle | 备注 |
|-----------|-------------------------------|------|
| `startEvent` | `NodeType.START_EVENT` | 圆形节点，label 取自 `name` 属性 |
| `endEvent` | `NodeType.END_EVENT` | 圆形节点（可加粗边框），label 取自 `name` |
| `task` | `NodeType.TASK` | 矩形节点，label 取自 `name` |
| `exclusiveGateway` | `NodeType.GATEWAY` | 菱形节点，label 取自 `name`（常为空） |
| `sequenceFlow` | `EdgeStyle.POLYLINE` | 连线，waypoints 从 DI 部分提取 |

**不支持（MVP 范围外）：**
- `parallelGateway`、`inclusiveGateway`、`eventBasedGateway` — 全部当作 `NodeType.GATEWAY` 处理即可，但不保证语义。
- `lane`、`pool`（泳道）—— 忽略。
- `dataObject`、`dataStore`、`textAnnotation`、`group` — 忽略。
- `messageFlow`、`association` — 忽略。
- 中间事件、边界事件、子流程 — 忽略。
- 扩展属性、条件表达式 — 只读取 `name` 属性。

### 支持的 BPMN Diagram Interchange（DI）

- `BPMNDiagram` > `BPMNPlane` > `BPMNShape`（每个节点一个）
  - `bpmnElement` 属性：对应流程元素的 `id`
  - `Bounds` 子元素：`x`、`y`、`width`、`height`（浮点数）
- `BPMNEdge`（每条 `sequenceFlow` 一个）
  - `bpmnElement` 属性：对应 `sequenceFlow` 的 `id`
  - `waypoint` 子元素（至少 2 个）：`x`、`y` 坐标

---

## API 设计

```typescript
class BpmnXmlParser {
  static parse(xml: string): GraphModel
}

class BpmnParseError extends Error {
  constructor(message: string)
}
```

`BpmnXmlParser.parse()` 是一个静态工厂方法，整体解析过程为：
1. 提取 `<process>` 下的语义节点（获得 id → name 映射）。
2. 提取 `<BPMNDiagram>` 下的布局信息（获得 id → 坐标 / 路径）。
3. 交叉组合，构建 `GraphModel`。

---

## 解析细节

### 第一步：解析流程语义

从 `<process id="..." name="...">` 内部提取：

- `<startEvent id="..." name="...">`
- `<endEvent id="..." name="...">`
- `<task id="..." name="...">`
- `<exclusiveGateway id="..." name="...">`

把所有元素的 `id` 和 `name` 存入 `Map<string, string>`（没有 `name` 则用空字符串）。

### 第二步：解析布局信息（BPMN Diagram）

从 `<BPMNDiagram>` > `<BPMNPlane>` 中提取：

- `<BPMNShape bpmnElement="elementId">`
  - `<Bounds x="..." y="..." width="..." height="...">`
  - 生成节点：`GraphNode`，坐标使用 `Bounds` 中的值，`width`/`height` 取整（`Math.round`）。
- `<BPMNEdge bpmnElement="edgeId">`
  - 内部 `<waypoint x="..." y="...">` 序列，按顺序收集为 `Waypoint[]`。
  - 生成连线：`GraphEdge`，`sourceId` 和 `targetId` 从流程语义中的 `sequenceFlow` 元素获取（见第三步）。

### 第三步：解析 sequenceFlow 语义

从 `<process>` 内部提取：

- `<sequenceFlow id="..." sourceRef="..." targetRef="..." />`
  - 找到对应的 BPMNEdge（通过 `bpmnElement` 匹配 id）获取 waypoints。
  - 如果没有对应的 BPMNEdge，waypoints 为空数组（此时连线由布局算法决定，MVP 阶段暂不处理自动路由，抛出错误或返回空 waypoints 并记录警告）。

### 第四步：构建 GraphModel

1. 遍历 DI 中的所有 `BPMNShape`，根据 `bpmnElement` 查找语义元素的类型（通过标签名）和 name。
2. 创建对应的 `GraphNode`，类型映射见上表。
3. 遍历所有 `sequenceFlow`，找到 `BPMNEdge` 的 waypoints，创建 `GraphEdge`。
4. 使用 `GraphModel.createEmpty()` 并依次 `addNodes()`、`addEdges()` 构造最终不可变模型。

### 坐标处理

- Bounds 的 x/y 可能为 0 或负数，直接使用不做偏移（保持与 bpmn.js 一致）。
- Waypoints 的坐标同样直接使用。

---

## XML 解析策略（硬约束：零外部依赖）

**禁止使用任何第三方 XML 库。** 必须用纯 ArkTS 字符串操作解析 XML。

建议实现一个最小化的基于正则/字符扫描的解析器，专门处理 BPMN 子集：

- 提取标签：匹配 `<startEvent ... />`、`<task ...>...</task>`、`<BPMNShape ...>` 等。
- 提取属性：通过 `([\w]+)="([^"]*)"` 正则。
- 不要实现通用的嵌套解析器，只针对 BPMN 结构的已知层次进行顺序扫描。

例如：

```
// 提取所有 <process> 下的 startEvent 元素
let startRegex = /<startEvent\b[^>]*\/?>/gi;
```

**容错：** 如果 XML 结构不符合预期（例如没有 `<process>` 或没有 `<BPMNDiagram>`），抛出 `BpmnParseError`。

---

## 错误处理

抛出 `BpmnParseError` 的情况：
- XML 为空或未包含 `<process>` 元素。
- 必需的布局信息缺失（例如有 `sequenceFlow` 但没有对应的 `BPMNEdge`）—— MVP 阶段可宽松处理，写出警告到日志，但不阻断解析。
- 坐标值无效（非数字）→ 弃用该节点/连线，并输出警告。

---

## 测试

只写 `hmflowkit/src/test/` 下的单元测试（如果项目结构允许），否则在 Demo 的验收页面增加 BPMN 解析测试：

- 加载一个包含 3 个节点（开始→任务→结束）的最小 BPMN XML。
- 验证 GraphModel 的节点数量、类型、坐标。
- 验证连线数量、sourceId/targetId、waypoints。
- 加载一个缺少 DI 的 XML，验证抛出错误（或不抛出但节点坐标为 0）。

---

## 集成到 Index.ets

解析器实现后，在 `hmflowkit/Index.ets` 中导出 `BpmnXmlParser` 和 `BpmnParseError`。

---

## 参考

- bpmn.js Modeler 导出的 XML 示例（重点关注其 DI 部分结构）。
- 项目内部 GraphModel API（参照 `hmflowkit/src/main/ets/model/GraphModel.ets` 的公开方法）。
- 不使用任何外部 XML 库。

---

## 验收标准

**在 Demo 页面加载一个真实的 bpmn.js 导出的请假审批流程 XML，观察到：**
- 5+ 个节点正确渲染在画布上，位置与 bpmn.js 中一致。
- 节点类型对应正确（圆形开始、菱形网关、矩形任务）。
- 连线从源节点出发到达目标节点，路径经过 waypoints（折线）。
- 单元/验收测试全部通过。

---

## 预计编码量

| 文件 | 预估行数 |
|------|--------|
| `parser/BpmnXmlParser.ets` | 200-300 |
| `parser/BpmnParseError.ets` | 10 |
| 测试/验收代码 | 50 |