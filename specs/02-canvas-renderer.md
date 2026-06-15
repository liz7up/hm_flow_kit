# Spec 02 — Canvas Renderer（画布渲染层）

> **状态** ✅ 全部完成（含 HitTestManager）  
> **依赖** Spec 01 — GraphModel  
> **验收** 7/7 通过（14 项总验收含 Spec01 回归）

---

## API 签名（从已实现代码提取）

### RenderConfig（renderer/RenderConfig.ets）

```typescript
export enum NodeShape { RECT = 0, DIAMOND = 1, CIRCLE = 2 }
export enum RenderLayer { EDGE = 0, NODE = 1, OVERLAY = 2 }
export const DEFAULT_NODE_COLOR = "#CCE5FF";
export const DEFAULT_NODE_SELECTED_COLOR = "#FFE082";
export const GatewayColors: Record<string, string> = {}
  // GatewayColors["DEFAULT"] "#FFF3E0" (constructor) | ... → 用 Record<string,string> 代替 Map
export const NodeColors: Record<string, string> = {}
```

### NodeRect（同 NodeRenderer.ets 中定义，导出）

```typescript
export class NodeRect {
  x: number; y: number; width: number; height: number;
  constructor(x: number, y: number, width: number, height: number)
  centerX(): number
  centerY(): number
  right(): number
  bottom(): number
}
```

#### GridConfig（renderer/GridRenderer.ets）

```typescript
export class GridConfig {
  size: number;
  color: string;
  visible: boolean;
  constructor(size: number, color: string, visible: boolean)
}
```

### NodeRenderer（renderer/NodeRenderer.ets）

```typescript
// 样式常量
export const TASK_COLOR: string = "#CCE5FF";
export const START_EVENT_COLOR: string = "#D4EDDA";
export const END_EVENT_COLOR: string = "#F8D7DA";
export const GATEWAY_COLOR: string = "#FFF3E0";
export const NODE_TEXT_COLOR: string = "#333333";
export const NODE_BORDER_COLOR: string = "#666666";
export const NODE_BORDER_WIDTH: number = 2;
export const NODE_TEXT_SIZE: number = 12;

// 核心 render 方法 — 静态方法
// 参数顺序：(ctx, node, offsetX, offsetY, selected, shapeOverride?)
export function render(
  ctx: CanvasRenderingContext2D,
  node: GraphNode,
  offsetX: number,
  offsetY: number,
  selected: boolean,
  shapeOverride?: NodeShape
): void

// 辅助方法（静态，按需）
export function getNodeColor(node: GraphNode): string
export function getNodeShape(node: GraphNode): NodeShape
```

### EdgeRenderer（renderer/EdgeRenderer.ets）

```typescript
// 样式常量
export const EDGE_COLOR: string = "#555555";
export const EDGE_WIDTH: number = 1.5;
export const EDGE_SELECTED_COLOR: string = "#FFC107";
export const EDGE_SELECTED_WIDTH: number = 2.5;
export const ARROW_SIZE: number = 10;
export const HIT_TOLERANCE: number = 8;

// 核心 render — 静态方法
// 参数顺序：(ctx, edge, nodes, offsetX, offsetY, selected)
// nodes: GraphNode[]（用于查 sourceNode / targetNode）
export function render(
  ctx: CanvasRenderingContext2D,
  edge: GraphEdge,
  nodes: GraphNode[],
  offsetX: number,
  offsetY: number,
  selected: boolean
): void

// 导出
export class NodeRect { x: number; y: number; width: number; height: number;
  constructor(x: number, y: number, width: number, height: number);
  centerX(): number; centerY(): number;
  right(): number; bottom(): number; }
```

### GridRenderer（renderer/GridRenderer.ets）

```typescript
export const DEFAULT_GRID_SIZE: number = 20;
export const DEFAULT_GRID_COLOR: string = "#E8E8E8";

export class GridConfig {
  size: number;
  color: string;
  visible: boolean;
  constructor(size: number, color: string, visible: boolean);
}

// render 静态方法
// 参数顺序：(ctx, config, offsetX, offsetY, canvasWidth, canvasHeight)
export function render(
  ctx: CanvasRenderingContext2D,
  config: GridConfig,
  offsetX: number,
  offsetY: number,
  canvasWidth: number,
  canvasHeight: number
): void
```

### CanvasManager（renderer/CanvasManager.ets）

```typescript
export class CanvasManager {
  constructor()                    // zoom=1, offsetX/Y=0
  get zoom(): number               // 属性，非方法
  get offsetX(): number
  get offsetY(): number

  // 坐标转换 — 输入 screenX/Y，用当前 zoom/offset 计算
  screenToCanvas(screenX: number, screenY: number): { x: number; y: number }
  canvasToScreen(canvasX: number, canvasY: number): { x: number; y: number }

  // 视口操作
  setZoom(z: number): void
  setOffset(x: number, y: number): void
  pan(dx: number, dy: number): void

  // 应用到 Canvas — 自动 setTransform
  applyTransform(ctx: CanvasRenderingContext2D): void
}
```

### HitTestManager（renderer/HitTestManager.ets）

```typescript
export class HitResult {
  type: string;          // "node" | "edge" | "none"
  id: string;
  constructor(type: string, id: string)
}

export class HitTestManager {
  // 单次命中检测 — callback 返回每个元素是否命中
  hitTest(
    x: number,
    y: number,
    callback: (x_canvas: number, y_canvas: number) => boolean
  ): HitResult

  // 批量命中检测 — 用于交互层
  hitTestBatch(
    model: GraphModel,
    canvas: CanvasManager,
    screenX: number,
    screenY: number
  ): HitResult
}
```

---

## 验收清单

### ✅ 对 NodeRenderer.render 的验收项

| # | 测试 | 方法 |
|---|------|------|
| 1 | 矩形节点（TASK 类型）描边 + 填充 + 居中文字 | 视觉 |
| 2 | 开始事件（START_EVENT）圆形节点 | 视觉 |
| 3 | 结束事件（END_EVENT）圆形节点（粗边框） | 视觉 |
| 4 | 网关（GATEWAY）菱形节点 | 视觉 |

### ✅ 对 EdgeRenderer.render 的验收项

| # | 测试 | 方法 |
|---|------|------|
| 5 | 折线 waypoints 连线 + 箭头 | 视觉 |
| 6 | 无 waypoints 直线（source→target 自动计算） | 视觉 |

### ✅ 对 CanvasManager 的验收项

| # | 测试 | 期望 |
|---|------|------|
| 7 | screenToCanvas 无缩放无平移 | 输入(110, 90) → (110, 90) |
| 8 | canvasToScreen 无缩放无平移 | 输入(100, 80) → (100, 80) |
| 9 | screenToCanvas 缩放+平移后 | zoom=0.5, offset=(10,20), 输入(60,70)→(100,100) |
| 10 | canvasToScreen 缩放+平移后 | 同上参数，输入(100,100)→(60,70) |

### ✅ 对 HitTestManager 的验收项

| # | 测试 | 期望 |
|---|------|------|
| 11 | 命中节点 | 交互层验收 |
| 12 | 空白区域未命中 | 交互层验收 |

### ✅ 视觉验收（端到端）

| # | 测试 | 期望 |
|---|------|------|
| 13 | Canvas 上同时渲染节点+连线+网格 | 可见完整图 |
| 14 | 审批流端到端（XML→Parser→Model→Renderer） | 可渲染完整流程 |

---

## 禁止事项

- ❌ CanvasManager 不使用 ArkUI 组件，只管理 Canvas 变换矩阵
- ❌ 不调用任何异步 API（setTimeout / Promise）
- ❌ 不可变模式：Renderer 只读 Model，不修改任何 Model 数据
- ❌ 不用 Map 类型 — 全部用 `Record<string, string>`
- ❌ 不用对象字面量做类型声明
- ❌ 不用展开运算符（spread）
- ❌ NodeRect 定义在 NodeRenderer.ets 中，不复用（避免循环依赖）

---

## 变更记录

- v1.3 | 2026-06-15 | 补全 API 签名（从代码提取）
- v1.2 | 2026-06-15 | 标注已完成，含 HitTestManager
- v1.1 | 2026-06-15 | 拆分 HitTestManager 到本 Spec
- v1.0 | 2026-06-15 | 初始版本