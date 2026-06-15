# Spec 01 — GraphModel 数据层

**版本**: 1.1  
**状态**: ✅ 已实现（文件：hmflowkit/src/main/ets/model/GraphModel.ets）  
**关联**: CLAUDE.md、scripts/build-log.sh

---

## 目标

实现图编辑器的核心数据模型，作为整个项目的唯一数据源（Single Source of Truth）。

---

## 输入 / 输出

| 方向 | 描述 |
|------|------|
| 输入 | 无（空图初始化）或 JSON 快照 |
| 输出 | `GraphModel` 实例，供 Renderer / Interaction 层读取 |
| 序列化 | `toJSON() → GraphModelSnapshot`、`fromJSON(snapshot)` |

---

## 数据结构（必须严格遵循）

```typescript
enum NodeType {
  RECT = 'rect',           // 通用矩形（任务节点）
  ROUNDED_RECT = 'rounded', // 圆角矩形（开始/结束事件）
  DIAMOND = 'diamond',      // 菱形（网关）
  CIRCLE = 'circle'         // 圆形
}

enum EdgeStyle {
  POLYLINE = 'polyline',
  BEZIER = 'bezier'
}

interface Viewport {
  offsetX: number;  // 画布偏移（视口左上角在画布坐标中的位置）
  offsetY: number;
  zoom: number;     // 缩放比例（1.0 = 100%）
}

interface GraphNode {
  id: string;
  type: NodeType;
  x: number;            // 画布坐标（左上角）
  y: number;
  width: number;
  height: number;
  label: string;
  properties: Record<string, string>;  // 扩展属性（BPMN 的 taskType 等）
}

interface GraphEdge {
  id: string;
  sourceId: string;
  targetId: string;
  label: string;
  style: EdgeStyle;
  waypoints: Array<{ x: number; y: number }>;  // 路径点（含起终点）
  properties: Record<string, string>;
}

interface GraphModelSnapshot {
  nodes: GraphNode[];
  edges: GraphEdge[];
  viewport: Viewport;
}
```

---

## 行为约束

- **纯数据类**：不依赖任何 UI 框架、ArkUI、Canvas API
- **不可变修改**：所有修改方法返回新的 `GraphModel` 实例，不修改原实例
- **级联删除**：`removeNode(id)` 必须同步删除所有关联的边
- **ID 唯一**：`addNode` / `addEdge` 遇到重复 ID 时抛出错误
- **边完整性**：`addEdge` 时验证 `sourceId` 和 `targetId` 对应的节点存在

---

## 公开 API

### 构造函数
```
new GraphModel(nodes?, edges?, viewport?)
```

### 查询方法（11个）
```
get nodes(): GraphNode[]
get edges(): GraphEdge[]
get viewport(): Viewport
getNode(id): GraphNode | undefined
getEdge(id): GraphEdge | undefined
hasNode(id): boolean
hasEdge(id): boolean
get nodeCount(): number
get edgeCount(): number
getOutgoingEdges(nodeId): GraphEdge[]
getIncomingEdges(nodeId): GraphEdge[]
getConnectedEdges(nodeId): GraphEdge[]
```

### 修改方法（10个，全不可变）
```
addNode(node): GraphModel
addEdges(edges): GraphModel
updateNode(id, patch): GraphModel
moveNode(id, x, y): GraphModel
removeNode(id): GraphModel
addEdge(edge): GraphModel
addEdges(edges): GraphModel
updateEdge(id, patch): GraphModel
removeEdge(id): GraphModel
setViewport(viewport): GraphModel
clear(): GraphModel
```

### 序列化
```
toJSON(): GraphModelSnapshot
static fromJSON(snapshot): GraphModel
```

---

## 禁止事项

- ❌ 不涉及 Canvas 绘制
- ❌ 不涉及 BPMN XML 解析（那是 Parser 层的事）
- ❌ 不涉及手势交互（那是 Interaction 层的事）
- ❌ 不依赖任何 ohpm 三方包
- ❌ 不修改入参数组/对象（不可变模式）

---

## 可参考的开源项目

| 项目 | 参考点 |
|------|--------|
| LogicFlow GraphModel | 数据驱动、不可变模式、插件系统 |
| bpmn.js diagram-js | 图模型与 BPMN 模型的分离 |
| AntV X6 Model | 节点/边/视口的统一管理 |

---

## 变更记录

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 初始 | 创建 Spec |
| 1.1 | 2025-01 | 补充编译桥接说明（scripts/build-log.sh），状态更新为已实现 |