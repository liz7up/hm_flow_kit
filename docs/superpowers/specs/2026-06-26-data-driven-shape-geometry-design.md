# Data-Driven Shape Geometry System — Design Spec

**Status:** Approved
**Date:** 2026-06-26
**Scope:** New perimeter-path-based shape geometry system, coexisting with BPMN 1.0 rendering

## Motivation

drawio 官方 BPMN 2.0 shape 使用 `points` 数组描述 shape 外轮廓路径。每个点 `[xFraction, yFraction, arcFlag]` 定义归一化几何坐标（相对 shape 宽高的 0..1 比例）。这套数据可以驱动：外轮廓渲染 + 连线 perimeter 交点计算。目标是将形状几何从硬编码 Drawer 中剥离为数据层，统一服务 BPMN XML 和 drawio 两种格式。

## Architecture Overview

```
adapter/ShapeDefinition.ets      [NEW]  PerimeterPoint + ShapeDefinition + ShapeRenderKind
adapter/PerimeterRouter.ets      [NEW]  精确 perimeter 交点（连续椭圆 / 菱形 / 折线）
renderer/PathRenderer.ets        [NEW]  根据 ShapeDefinition 绘制外轮廓

adapter/ShapeConfig.ets          [MOD]  新增 registerShape() + getShapeDefinition()
renderer/TaskDrawer.ets          [MOD]  轮廓改用 PathRenderer，图标保留
renderer/EventDrawer.ets         [MOD]  同上
renderer/GatewayDrawer.ets       [MOD]  同上
renderer/SubProcessDrawer.ets    [MOD]  同上
renderer/DataDrawer.ets          [MOD]  同上
renderer/AnnotationDrawer.ets    [MOD]  同上
renderer/DrawioNodeDrawer.ets    [MOD]  BPMN-mapped 形状改用 PathRenderer
parser/DrawioXmlParser.ets       [MOD]  _perimeterPoint() 改用 PerimeterRouter
```

### Data Flow

```
          ShapeDefinition registry (adapter)
         /                              \
  PathRenderer                     PerimeterRouter
  "画外轮廓"                        "求连线交点"
       ↑                                  ↑
  TaskDrawer.ets                    DrawioXmlParser.ets
  EventDrawer.ets                   EdgeRenderer（未来）
  ...
```

## Data Structures

### PerimeterPoint

```typescript
interface PerimeterPoint {
  xFraction: number;  // 0.0 ~ 1.0，相对 shape 宽度
  yFraction: number;  // 0.0 ~ 1.0，相对 shape 高度
}
```

Canvas 实际坐标换算在 PathRenderer 中完成：

```
canvasX = nodeX + point.xFraction * nodeWidth * zoom + offsetX
canvasY = nodeY + point.yFraction * nodeHeight * zoom + offsetY
```

### ShapeRenderKind

```typescript
enum ShapeRenderKind {
  NATIVE_ELLIPSE,  // 用 Canvas ctx.ellipse() 绘制，保证任意缩放级别为完美圆
  NATIVE_RHOMBUS,  // 直接用菱形四点坐标（w/2,0 → w, h/2 → w/2, h → 0, h/2）
  POLYLINE,        // 按 perimeterPath 逐点 lineTo；cornerRadiusRatio > 0 时调用 arcTo
}
```

### ShapeDefinition

```typescript
class ShapeDefinition {
  readonly shapeId: string;              // e.g. "bpmn.task2", "bpmn.event", "bpmn.gateway2"
  readonly renderKind: ShapeRenderKind;  // 视觉绘制策略
  readonly perimeterKind: PerimeterKind; // 路由数学方法（ELLIPSE / RHOMBUS / RECT）
  readonly perimeterPath: PerimeterPoint[]; // 归一化外轮廓点
  readonly cornerRadiusRatio: number;    // POLYLINE 时的默认圆角比

  // TODO: iconSet?: IconDefinition[]    // 内部图标声明（后续标准化）
}
```

`renderKind` 与 `perimeterKind` 独立：EVENT 的 `renderKind` 为 `NATIVE_ELLIPSE`（保证视觉完美），`perimeterKind` 为 `ELLIPSE`（路由用连续椭圆方程）。

### 预置 Shape Definition

从 drawio 官方 BPMN 文件中提取：

**TASK_PERIMETER** — 12 点圆角矩形 (bpmn.task2)：
```
[0.25,0] [0.5,0] [0.75,0] [1,0.25] [1,0.5] [1,0.75]
[0.75,1] [0.5,1] [0.25,1] [0,0.75] [0,0.5] [0,0.25]
```
renderKind: POLYLINE, perimeterKind: RECT, cornerRadiusRatio: 0.133

**EVENT_PERIMETER** — 8 点 octagon (bpmn.event)：
```
[0.145,0.145] [0.5,0] [0.855,0.145] [1,0.5]
[0.855,0.855] [0.5,1] [0.145,0.855] [0,0.5]
```
renderKind: NATIVE_ELLIPSE, perimeterKind: ELLIPSE

**GATEWAY_PERIMETER** — 8 点菱形 (bpmn.gateway2)：
```
[0.25,0.25] [0.5,0] [0.75,0.25] [1,0.5]
[0.75,0.75] [0.5,1] [0.25,0.75] [0,0.5]
```
renderKind: NATIVE_RHOMBUS, perimeterKind: RHOMBUS

### 注册 & Fallback

```typescript
ShapeConfig.registerShape('bpmn.task2', ShapeRenderKind.POLYLINE, PerimeterKind.RECT,
  TASK_PERIMETER, 0.133);
ShapeConfig.registerShape('bpmn.event', ShapeRenderKind.NATIVE_ELLIPSE, PerimeterKind.ELLIPSE,
  EVENT_PERIMETER);
ShapeConfig.registerShape('bpmn.gateway2', ShapeRenderKind.NATIVE_RHOMBUS, PerimeterKind.RHOMBUS,
  GATEWAY_PERIMETER);

// 未知 shapeId 返回 default RECT
ShapeConfig.getShapeDefinition('unknown-type') !== null  // always true
```

## PathRenderer

```typescript
class PathRenderer {
  static render(
    ctx: CanvasRenderingContext2D,
    shapeDef: ShapeDefinition,
    x: number, y: number, w: number, h: number,
    fillColor: string,
    strokeColor: string,
    strokeWidth: number,
    cornerRadiusOverride?: number
  ): void;
}
```

颜色由调用方（Drawer）从 RenderConfig / node properties 解析后传入，PathRenderer 不自推断。

### 绘制逻辑

1. `renderKind === NATIVE_ELLIPSE`: `ctx.ellipse(cx, cy, w/2, h/2, 0, 0, 2*PI)`
2. `renderKind === NATIVE_RHOMBUS`: `moveTo(midTop) → lineTo(rightMid) → lineTo(midBottom) → lineTo(leftMid) → closePath()`
3. `renderKind === POLYLINE`: 遍历 perimeterPath，`lineTo(px, py)` 逐点连接；若 cornerRadiusRatio > 0 或 override，用 `arcTo()` 处理转角

## PerimeterRouter

```typescript
class PerimeterRouter {
  static intersect(
    shapeDef: ShapeDefinition,
    nodeRect: NodeRect,
    fromX: number, fromY: number,
    toX: number, toY: number
  ): { x: number, y: number } | null;
}
```

`fromX, fromY` = 远端参考点（另一端点或方向），`toX, toY` = 当前 shape 中心。计算 from→to 射线与 shape perimeter 的第一个交点。

### 路由逻辑

1. `perimeterKind === ELLIPSE`: 射线-椭圆连续方程，精确解
2. `perimeterKind === RHOMBUS`: 4 条菱形边分别做射线-线段交点
3. `perimeterKind === RECT`: 射线-矩形交点（连续公式，保精度）

`perimeterPath` 点暂不用于 POLYLINE 路由求交（弧线段求交待后续支持）。用 `perimeterKind` 分发到连续数学公式保证现有精度不退化。

### 已知限制

- **TASK 圆角矩形路由近似**：`perimeterKind=RECT` 使用锐角矩形公式求交。视觉上是圆角，路由交点在锐角矩形边界上，偏差约 `cornerRadiusRatio * min(w,h)` 像素。与当前 BPMN 1.0 行为一致（`_perimeterRect` 同样忽略圆角）。后续可加弧线段求交消除此偏差。
- 8 点 octagon 不用于路由（EVENT 用连续椭圆方程，保证精确）

## 共存策略

- `ShapeDefinition` 和 `PathRenderer` 是**纯增量**，不删除任何现有代码
- BPMN 1.0 的 6 个 Drawer 渐进式改造：
  - Phase 2.1: 在 Drawer 中**新增** `PathRenderer.render()` 调用，输出旧轮廓代码**之后**（双层绘制）
  - Phase 2.2: 视觉对比验证后，**删除**旧轮廓代码
  - 图标/标记绘制代码**完全不动**
- `PerimeterRouter` 先在 `DrawioXmlParser._perimeterPoint()` 接入（drawio 路径），稳定后再考虑用于 BPMN XML 的 EdgeRenderer
- `ShapeConfig.perimeterKind()` 保留，不删除 —— 作为 PerimeterRouter 的 fallback

## Drawer 集成清单

每个 Drawer 改造时：轮廓 → PathRenderer，图标保留。

| Drawer | 轮廓 | 保留的图标/标记 |
|--------|------|---------------|
| TaskDrawer | 圆角矩形（12-point POLYLINE） | taskMarker (abstract/user/service/script/manual/send/receive/businessRule) + loopMarker (standard/sub/multiSeq/multiParallel/comp) + AdHoc 标记 |
| EventDrawer | 圆/椭圆（NATIVE_ELLIPSE） | symbol 图标 (message/timer/escalation/error/compensation/conditional/link/signal/multiple/parallelMultiple/cancel/terminate/terminate2) + BoundaryEvent 虚线双圈/实线双圈 |
| GatewayDrawer | 菱形（NATIVE_RHOMBUS） | gwType 标记 (X/+/ */star) + outline 事件轮廓 |
| SubProcessDrawer | 圆角矩形（12-point POLYLINE） | expanded（layer 0 容器）/ collapsed（layer 4 [+]) / transaction 双线边框 |
| DataDrawer | 折角页 / 圆柱（POLYLINE） | collection 标记 |
| AnnotationDrawer | L 括号（POLYLINE） | 无内部图标 |

## 测试策略

### 新增测试

| 测试文件 | 内容 | 预估项数 |
|---------|------|---------|
| `ShapeDefinition.test.ets` | registerShape / getShapeDefinition / fallback 默认 RECT / PerimeterPoint 换算 / PerimeterKind 分发 | ~12 |
| `PathRenderer.test.ets` | 三种 renderKind 路径点 / fill/stroke/dash 参数传递 | ~8 |
| `PerimeterRouter.test.ets` | 射线-椭圆交点 / 射线-菱形交点 / 射线-矩形交点 / 边界（射线过顶点、射线从内部发出、近水平射线） | ~10 |

增量：~30 项。总目标：186 + 30 = **216 项编译通过**。

### 视觉验收

- 5 个 `drawio-bpmn20-*.drawio` 文件渲染无肉眼退化
- `kitchen-sink.bpmn` 渲染与当前版本一致
- drawio 连线 perimeter 交点不穿透 shape 内部
- 缩放级别 0.1x ~ 5.0x 无断线

### 不纳入当前 spec

- 图标标准化注册表（`IconDefinition`）→ 后续 TODO
- Conversation / Message 两个新 shape → 留作 ShapeDefinition 扩展性验证
- `sanitizeLabel` 提取 → Phase 2 顺手重构

## Rollout Plan

### Phase 1: 基础设施（不影响 BPMN 1.0）
1. 新增 `ShapeDefinition.ets`、`PerimeterRouter.ets`、`PathRenderer.ets`
2. 在 `ShapeConfig.ets` 中新增 `registerShape()` / `getShapeDefinition()`
3. 预置 TASK / EVENT / GATEWAY 三个 canon 定义
4. 在 `DrawioXmlParser._perimeterPoint()` 中切换调用 `PerimeterRouter.intersect()`
5. **验收：drawio 路径的 perimeter 计算正确**

### Phase 2: Drawer 逐一切换
1. TaskDrawer → PathRenderer + 图标保留 → 视觉验证
2. EventDrawer → PathRenderer + 图标保留 → 视觉验证
3. GatewayDrawer → PathRenderer + 图标保留 → 视觉验证
4. SubProcessDrawer → PathRenderer + 图标保留 → 视觉验证
5. DataDrawer → PathRenderer 无图标变更 → 视觉验证
6. AnnotationDrawer → PathRenderer 无图标变更 → 视觉验证
7. **验收：kitchen-sink.bpmn + 5 个 drawio 文件全绿**

### Phase 3: 收编 & 清理
1. DrawioNodeDrawer 中 BPMN-mapped 形状改为 PathRenderer
2. 顺手提取 `sanitizeLabel` 为共用
3. `test_all.sh` 最终编译验证

## Future Work

- **图标标准化**：`IconDefinition { iconId, drawFunc, position, scale }` 注册表，使图标也数据驱动
- **新 shape 扩展**：Conversation (hexagon)、Message (envelope) 作为 ShapeDefinition 首次扩展
- **EdgeRenderer 接入**：BPMN XML 的连线 perimeter 计算切换到 PerimeterRouter
