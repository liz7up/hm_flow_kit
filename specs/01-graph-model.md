# Spec 01: GraphModel 数据模型

**版本**: 1.0 — 锁定  
**状态**: ✅ 完成  
**验收**: 7/7 通过（27 项总回归测试中）

---

## 目标

实现图编辑器的核心数据层，作为整个项目唯一的数据源。

所有修改通过不可变方法进行，返回新实例。配合 ArkUI `@State` 触发 UI 更新。

---

## 导出的公开 API

### 枚举

```typescript
export enum NodeType {
  START_EVENT = 'startEvent',
  END_EVENT = 'endEvent',
  TASK = 'task',
  GATEWAY = 'gateway'
}

export enum EdgeStyle {
  STRAIGHT = 'straight',
  POLYLINE = 'polyline'
}
```

### 类

```typescript
export class Waypoint {
  public x: number;
  public y: number;
  constructor(x: number, y: number);
  clone(): Waypoint;
  toJSON(): Record<string, number>;
}
```

```typescript
export class GraphNode {
  public id: string;
  public type: NodeType;
  public x: number;
  public y: number;
  public width: number;
  public height: number;
  public label: string;
  public properties: Record<string, string>;

  constructor(
    id: string,
    type: NodeType,
    x: number,
    y: number,
    width: number,
    height: number,
    label: string,
    properties: Record<string, string>
  );

  clone(): GraphNode;
  toJSON(): Record<string, Object>;
}
```

```typescript
export class GraphEdge {
  public id: string;
  public sourceId: string;
  public targetId: string;
  public waypoints: Waypoint[];
  public style: EdgeStyle;
  public label: string;
  public properties: Record<string, string>;

  constructor(
    id: string,
    sourceId: string,
    targetId: string,
    waypoints: Waypoint[],
    style: EdgeStyle,
    label: string,
    properties: Record<string, string>
  );

  clone(): GraphEdge;
  toJSON(): Record<string, Object>;
}
```

```typescript
export class Viewport {
  public x: number;
  public y: number;
  public zoom: number;

  constructor(x: number, y: number, zoom: number);
  clone(): Viewport;
  toJSON(): Record<string, Object>;
}
```

```typescript
export class GraphModelSnapshot {
  public nodes: GraphNode[];
  public edges: GraphEdge[];
  public viewport: Viewport;

  constructor(nodes: GraphNode[], edges: GraphEdge[], viewport: Viewport);
}
```

```typescript
export class GraphModel {
  constructor();
  static createEmpty(): GraphModel;
  static fromJSON(snapshot: GraphModelSnapshot): GraphModel;

  // 查询
  getNodes(): GraphNode[];
  getEdges(): GraphEdge[];
  getNode(id: string): GraphNode | null;
  getEdge(id: string): GraphEdge | null;
  hasNode(id: string): boolean;
  hasEdge(id: string): boolean;
  getNodeCount(): number;
  getEdgeCount(): number;
  getOutgoingEdges(nodeId: string): GraphEdge[];
  getIncomingEdges(nodeId: string): GraphEdge[];
  getConnectedEdges(nodeId: string): GraphEdge[];
  getViewport(): Viewport;

  // 不可变修改（全部返回新 GraphModel 实例）
  addNode(node: GraphNode): GraphModel;
  addNodes(nodes: GraphNode[]): GraphModel;
  addEdge(edge: GraphEdge): GraphModel;
  addEdges(edges: GraphEdge[]): GraphModel;
  moveNode(id: string, x: number, y: number): GraphModel;
  removeNode(id: string): GraphModel;  // 级联删除关联边
  removeEdge(id: string): GraphModel;
  setViewport(viewport: Viewport): GraphModel;
  clear(): GraphModel;

  // 序列化
  toJSON(): GraphModelSnapshot;
}
```

> **注意**: `GraphModel` 是无参构造，初始为空图。通过不可变方法逐步构建。

---

## 实现清单

| 功能 | 描述 | Spec02 引用 |
|------|------|-------------|
| 空模型 | `GraphModel()` 或 `createEmpty()` 生成 nodes=0, edges=0 | — |
| 添加节点 | `model = model.addNode(node)` | Renderer 使用 `GraphNode.x/y/w/h/type/label` |
| 添加连线 | `model = model.addEdge(edge)` | Renderer 使用 `GraphEdge.sourceId/targetId/waypoints/style` |
| 移动节点 | `model = model.moveNode(id, x, y)` | — |
| 删除节点 | 级联删除所有关联的入边/出边 | — |
| 删除连线 | `model = model.removeEdge(id)` | — |
| 序列化 | `GraphModel.toJSON()` → `GraphModelSnapshot`，`GraphModel.fromJSON(snapshot)` → 新实例 | — |
| 不可变 | 每次修改返回新实例，原实例不变 | — |
| 视口 | `Viewport` 管理 x/y/zoom | CanvasManager 使用 |
| 关联查询 | `getOutgoingEdges` / `getIncomingEdges` / `getConnectedEdges` | — |

---

## 验收清单（Demo 中已实现）

```
✅ 空模型 nodeCount=0
✅ 添加节点 nodeCount=2
✅ 添加连线 edgeCount=1
✅ 不可变-原实例不变
✅ 不可变-新实例包含节点
✅ 删除节点+级联删边
✅ 序列化 roundtrip
```

---

## 技术约束

- 纯数据类，不依赖任何 UI 框架
- 所有属性公开但通过构造器初始化
- `clone()` 方法用于不可变更新：`newNode = oldNode.clone(); newNode.x = val; model.addNode(newNode)`
- 不直接使用对象展开（ArkTS 限制）
- `toJSON()` 返回的是显式构造的对象，不是裸字面量

---

## 相关文件

- 实现: `hmflowkit/src/main/ets/model/GraphModel.ets` (~460 行)
- 导出: `hmflowkit/Index.ets`
- 测试: `entry/src/main/ets/pages/Index.ets` (Spec01 验收部分)