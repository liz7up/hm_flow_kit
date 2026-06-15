# Spec 03 — BPMN Parser

> 状态：✅ 完成
> 实现文件：`hmflowkit/src/main/ets/parser/BpmnXmlParser.ets`
> 最后更新：2026-06-15

---

## 目标

将 BPMN 2.0 XML 字符串解析为 `GraphModel` 实例。

兼容 **bpmn.js / Camunda Modeler** 导出的标准 BPMN 2.0 XML。

---

## 输入 / 输出

```
输入：string（BPMN 2.0 XML 全文，含命名空间）
输出：GraphModel（节点 + 连线 + 坐标）
     失败抛出 Error，包含具体原因
```

---

## API Anchor（写死，不可改）

```typescript
// 位于 hmflowkit/src/main/ets/parser/BpmnXmlParser.ets

export class BpmnXmlParser {
  // 构造：必须传入完整的 BPMN XML 字符串
  constructor(xml: string)

  // 解析：返回 GraphModel
  //   自动处理 BPMNDiagram 坐标 ← BPMNShape + BPMNEdge
  //   无 BPMNDiagram 时使用默认坐标依次排列
  parse(): GraphModel
}
```

---

## 解析规则

### 支持的 BPMN 元素

| XML 元素 | NodeType | 默认宽高 |
|---------|----------|---------|
| `bpmn:startEvent` | START_EVENT | 36×36 |
| `bpmn:endEvent` | END_EVENT | 36×36 |
| `bpmn:task` / `bpmn:userTask` / `bpmn:serviceTask` / `bpmn:scriptTask` | TASK | 120×60 |
| `bpmn:exclusiveGateway` / `bpmn:parallelGateway` / `bpmn:inclusiveGateway` | GATEWAY | 50×50 |

### 支持的连线

| XML 元素 | EdgeStyle |
|---------|-----------|
| `bpmn:sequenceFlow` | POLYLINE |

### 坐标来源

1. 解析 `<bpmndi:BPMNDiagram>` → `<bpmndi:BPMNShape>` → `<dc:Bounds>`（自闭合标签，属性 x/y/width/height）
2. 解析 `<bpmndi:BPMNEdge>` → `<omgdi:waypoint>`（多个 waypoint）
3. 无 BPMNDiagram 时使用默认坐标：垂直等距排列（每节点 y += 120）

### 标签提取

- 节点标签：`bpmn:startEvent` 的 `name` 属性
- 连线标签：`bpmn:sequenceFlow` 的 `name` 属性

### 特殊字符处理

- XML 转义 `&gt;` `&lt;` `&amp;` `&quot;` → 解码

---

## 边界情况

| 情况 | 处理 |
|------|------|
| 空 XML | Error |
| 无效 XML | Error |
| 含 BPMN 命名空间（`xmlns:bpmn="..."`） | 自动识别 |
| `dc:Bounds` 自闭合标签 | 直接从属性读取 x/y/width/height |
| 无 BPMNDiagram | 默认坐标（垂直排列，间距 120） |
| 连线无 waypoint | 默认两端点（源中心 → 目标中心） |
| 节点无 name 属性 | label 为空字符串 `""` |
| 属性值含空格 | trim() |
| 属性值含引号 | 自动去除引号 |
| 空属性值 | 回退到默认值（如 width=100） |

---

## 验收标准

| 测试项 | 预期 | 实际 |
|--------|------|------|
| 解析节点数 | 6 | ✅ 6 |
| 解析连线数 | 6 | ✅ 6 |
| 开始事件 | 1 | ✅ 1 |
| 任务节点 | 3 | ✅ 3 |
| 网关节点 | 1 | ✅ 1 |
| 结束事件 | 1 | ✅ 1 |
| Gate1 坐标 x | 400 | ✅ |
| Gate1 坐标 y | 190 | ✅ |
| Start 坐标 x | 100 | ✅ |
| 连线标签 | "提交" | ✅ |
| waypoints 数量 | >0 | ✅ |
| 无条件边标签为空 | "" | ✅ |
| 无DI解析节点 | 2 | ✅ |
| 无DI解析连线 | 1 | ✅ |