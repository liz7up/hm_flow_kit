# Spec 07 — BPMN 2.0 XML 解析器 v2（弃用手搓 indexOf，改用 @kit.ArkTS XML API）

## 状态

- **开始**: 2025-07-18
- **完成**: 2025-07-18
- **验收**: 全部通过（cplx1.bpmn 渲染正常，3 个 Demo 流程均正确显示）

## 动机

- Spec 03 的第一版解析器使用手搓 `indexOf`/字符串分割方式解析 XML，健壮性差，无法处理命名空间、注释、CDATA 等边界情况。
- 鸿蒙官方提供了 `@kit.ArkTS` 中的 `xml.XmlPullParser`，支持 SAX 风格的 XML 解析（API 14+）。
- 目标：使用官方 XML API 完全重写解析器，同时整理代码架构使其易于维护。

## API 选型

参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/xml-parsing

使用的 API：

| API | 作用 |
|-----|------|
| `xml.XmlPullParser(arrBuffer, 'UTF-8')` | 构造解析器 |
| `parser.parseXml(options)` | 回调形式驱动解析（API 14+，已取代废弃的 `parse()` + `next()` 命令式循环） |
| `options.ignoreNameSpace = true` | 去除命名空间 |
| `options.tokenValueCallbackFunction` | 回调：(EventType, ParseInfo) => boolean |
| `options.attributeValueCallbackFunction` | 回调：(attrName, attrValue) => boolean |

## 关键发现：回调时序

官方文档及示例暗示 `attributeValueCallback` 先于 `tokenValueCallback(START_TAG)` 触发，即：

```
attributeValueCallback → tokenValueCallback(START_TAG)
```

**但在 HarmonyOS 5.0 / API 14 的实际运行时中，回调顺序是相反的**：

```
tokenValueCallback(START_TAG) → attributeValueCallback → tokenValueCallback(END_TAG)
```

这意味着在 `tokenValueCallback(START_TAG)` 中读取属性会得到空值（attribute callback 尚未触发）。

### 正确的实现策略

**所有业务逻辑全部在 `tokenValueCallback(END_TAG)` 中处理**，此时 `attributeValueCallback` 已完成对本元素所有属性的填充。

**`tokenValueCallback(START_TAG)` 只做两件事**：
1. 设置作用域标记（`inShape`、`inLabel`、`inEdge`）
2. 重置数据累积器（`shapeX = 0; shapeY = 0; ...`、`waypointBuf = ''`）

不做任何属性读取。

### ArkTS 闭包限制：禁止对 `currentAttrs` 整体赋值

`attrCb` 闭包捕获 `currentAttrs` 的**对象引用**（非变量绑定）。在 ArkTS strict mode 中，对 `currentAttrs = {}` 整体重赋值后，闭包仍写入旧对象，新 `currentAttrs` 始终为空。

**正确做法**：永不调用 `currentAttrs = {}`。每个新元素的 `attributeValueCallback` 自然用新属性覆盖旧值，无需手动清空。

> 曾尝试在 `START_TAG` 加 `currentAttrs = {}` 导致属性全部丢失（闭包写入旧对象、逻辑读取新对象），已验证回退。

## `ignoreNameSpace` 的行为

经实测，`ignoreNameSpace: true` 的效果是：
- `ParseInfo.getName()` 返回的标签名**保留原始命名空间前缀**（如 `bpmndi:BPMNShape`）
- 所有属性（无论属于哪个命名空间）的 `attributeValueCallback` **均被正常触发**

因此在代码中需要手动剥离命名空间前缀：

```typescript
let fullName: string = info.getName();
let colon: number = fullName.lastIndexOf(':');
let tagName: string = colon !== -1 ? fullName.substring(colon + 1) : fullName;
```

## 架构

```
parse(xmlStr: string): GraphModel    // 公开静态方法
  ├── TextEncoder 编码 → Uint8Array → ArrayBuffer
  ├── xml.XmlPullParser + parseXml({
  │     ignoreNameSpace: true,
  │     attributeValueCallbackFunction → 收集属性到 currentAttrs: Record<string, string>
  │     tagValueCallbackFunction       → （暂未使用）
  │     tokenValueCallbackFunction     → 状态机驱动
  │   })
  │   ├── START_TAG: 剥离前缀 → 设作用域标记 + 重置累积器 + 处理 waypoint
  │   ├── END_TAG:   剥离前缀 → 从 currentAttrs 读取属性 → 处理元素
  │   │   ├── BPMNShape → BPMNLabel → Bounds（shape 级别）→ 保存坐标到 collector
  │   │   ├── BPMNEdge  → waypoint[]       → 保存路径到 collector
  │   │   ├── process 内元素 → 保存到 collector.pendingNode
  │   │   └── sequenceFlow     → 保存到 collector.pendingEdge
  │   └── TEXT: 累积 waypoint 坐标文本到 waypointBuf
  └── _Collector.build() → GraphModel
```

## Collector（内部中间数据结构）

不再使用 class，直接使用简单变量 + Record，避免 ArkTS 语法限制。

```
_NodeEntry { id, type: NodeType, label, x, y, w, h }
_EdgeEntry { id, sourceId, targetId, label, waypoints: Waypoint[] }

_Collector {
  nodes: Map<string, _NodeEntry>          // 按 id 索引
  edges: EdgeEntry[]
  shapeCoords: Record<string, {x,y,w,h}>  // BPMNShape 坐标映射
  edgeWaypoints: Record<string, Waypoint[]> // BPMNEdge waypoints 映射
}
```

build() 阶段：
1. 遍历所有 _NodeEntry，查找 shapeCoords 中的坐标补齐 x/y/w/h
2. 遍历所有 EdgeEntry，查找 edgeWaypoints 中的 waypoints
3. 组装 GraphNode[] 和 GraphEdge[]，
4. 调用 `new GraphModel(nodes, edges)` 返回

## 协议适配（cplx1.bpmn）

cplx1.bpmn 包含原版 bpmn.js 导出的完整 XML，包含以下特殊元素，需在解析器中覆盖：

| BPMN 元素 | NodeType 映射 | 备注 |
|-----------|---------------|------|
| `startEvent` | START_EVENT | standard |
| `endEvent` | END_EVENT | standard |
| `userTask`、`task`、`sendTask`、`serviceTask`、`scriptTask`、`manualTask`、`businessRuleTask` | TASK | 任务族 |
| `exclusiveGateway`、`parallelGateway`、`inclusiveGateway`、`eventBasedGateway` | GATEWAY | 网关族 |
| `intermediateThrowEvent`、`intermediateCatchEvent`、`boundaryEvent` | START_EVENT | 中间/边界事件以事件样式展示 |
| `callActivity` | TASK | 调用活动以 task 样式展示 |
| `subProcess` | TASK | 子流程以 task 样式展示 |
| `sequenceFlow` | EdgeStyle.POLYLINE | 连线 |
| `textAnnotation`、`dataObjectReference`、`dataStoreReference`、`group`、`lane`、`participant` | 丢弃 | 非核心视觉元素 |

## 测试用例更新（待办）

现有 `.test.ets` 针对旧版 indexOf 手搓解析器。v2 需要更新测试：
1. 输入不变：`hello.bpmn`、`sample.bpmn`、`cplx1.bpmn`
2. 预期输出不变：GraphModel 结构校验、节点数、边数、坐标正确性
3. 边界：格式错误的 XML → 抛出预期异常
4. 边界：空 XML → 空 GraphModel

## 禁止事项

- 禁止使用 `parser.parse()` + `next()` 命令式循环（API 14 中已废弃）
- 禁止在 START_TAG 中从 currentAttrs 读取属性（回调时序保证此时为空）
- 禁止引入任何 npm/ohpm 第三方 XML 库
- 禁止使用 `util.TextEncoder` 不同的编码（仅允许 UTF-8）

## 参考项目

| 项目 | 借鉴内容 |
|------|---------| 
| bpmn-js (bpmn-moddle) | BPMN 2.0 XSD 元素→类型映射规则 |
| LogicFlow (BpmnAdapter) | DI 段 BPMNShape/BPMNEdge 与 Model 的转换模式 |

## 沉淀档案

- 时间：2025-07-18
- 上下文：回调时序与文档相反的实际发现，verify 修复后 3 个 Demo 均正确渲染
- 相关文件：
  - `hmflowkit/src/main/ets/parser/BpmnXmlParser.ets`（363 → 295 行，重写）
  - `specs/07-xml-parser-v2.md`（本文件，根据实测结果更新）
- 关键教训：
  - HarmonyOS `parseXml()` 的 `tokenValueCallback` 在 `attributeValueCallback` **之前**触发（与官方文档暗示顺序相反）
  - `ignoreNameSpace: true` 不会剥离 `getName()` 返回的前缀，需手动 `lastIndexOf(':')` 剥离
  - 所有业务逻辑应放在 `END_TAG` 中处理，`START_TAG` 仅设标记和重置累积器
  - ArkTS 闭包捕获对象引用而非变量绑定——禁止对 `currentAttrs` 整体重赋值（`currentAttrs = {}`），否则闭包与逻辑读取分离