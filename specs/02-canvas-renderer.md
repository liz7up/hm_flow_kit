# Spec 02: Canvas 渲染层

## 状态：部分完成 ⚠️

### 已完成 ✅
- [x] NodeRenderer — 节点渲染（矩形/菱形/圆形/圆角矩形 + 居中文字）
- [x] EdgeRenderer — 连线渲染（折线 + 箭头） + NodeRect
- [x] GridRenderer — 背景网格（点阵/线网格）
- [x] CanvasManager — 视口管理（zoom/pan/坐标转换/applyTransform）
- [x] RenderConfig — 渲染配置
- [x] 视觉 Demo — Canvas 上实际渲染审批流图，肉眼验证通过

### 未完成 ❌
- [ ] HitTestManager — 坐标→元素命中检测（交互层前置依赖）
- [ ] 缩放/平移交互验证（无手势测试）
- [ ] 箭头渲染视觉确认
- [ ] 各 NodeType 形状差异确认

### 下一 Spec 前必须补
- HitTestManager

实现 hmgraph-kit 的 Canvas 渲染层。该层从 GraphModel 读取数据，在 ArkUI Canvas 上绘制节点、连线和相关视觉元素。

## 前提

- Spec 01 (GraphModel) 已完成并验证通过
- 所有数据从 GraphModel 读取，渲染层只做展示

## 范围：MVP 只读渲染

### Sprint 2-1（本 Spec）：基础渲染

```
✅ 节点渲染
   ├── 矩形节点（任务节点）  ← 最常见的节点类型
   ├── 圆角矩形（开始/结束事件）
   ├── 菱形（网关）
   ├── 填充色（浅蓝/浅绿/浅橙/浅红 对应不同状态）
   ├── 边框色（比填充深 2 档）
   ├── 边框宽度 1.5px
   ├── 文字居中绘制（label）
   └── 最小尺寸 80x40（小于此尺寸的节点不会出现）

✅ 连线渲染
   ├── 直线（EdgeStyle.STRAIGHT）
   ├── 折线（EdgeStyle.POLYLINE，走 waypoints）
   ├── 贝塞尔曲线（EdgeStyle.CURVED，仅起点→终点 无 waypoints 时用二次贝塞尔）
   ├── 终点箭头（实心三角填充）
   ├── 连线宽度 2px
   ├── 颜色 #666（默认）或节点状态色（如果连线继承源节点颜色）
   └── label 标签（位置：折线的中间 waypoint 附近）

✅ 画布管理
   ├── CanvasManager 负责画布的 transform 变换
   ├── 缩放（鼠标滚轮，0.2x ~ 5x 范围）
   ├── 平移（空白区域拖拽）
   ├── viewport 同步到 GraphModel（或从 GraphModel 恢复）
   └── 使用 Canvas 的 translate + scale 变换矩阵

✅ 编辑器背景
   ├── 浅灰背景 #F5F5F5
   ├── 点阵网格（可选，每 20px 一个淡灰点）
   └── 网格点颜色 #E0E0E0，半径 1px
```

### 明确不做（留给 Spec 03 / 04）

```
❌ 交互编辑（拖拽、连线、选择、删除）→ Spec 04
❌ 节点详情面板 → Spec 06
❌ 缩略图（MiniMap）→ Spec 06
❌ 撤销/重做 → Spec 06
❌ 导出图片/PDF → 后续版本
```

## 架构设计

```
hmflowkit/src/main/ets/renderer/
├── CanvasManager.ets       # 画布变换矩阵 + 缩放/平移 + 坐标转换
├── NodeRenderer.ets        # 节点绘制函数集
├── EdgeRenderer.ets        # 连线绘制函数集
└── GridRenderer.ets        # 背景网格绘制
```

### 层间关系

```
CanvasManager
├── 维护 zoom / offsetX / offsetY
├── 应用到 Canvas 的 transform
├── 提供 screenToWorld() / worldToScreen()
└── 被外部组件（FlowViewer）操作

NodeRenderer
├── 接收 Context2D + GraphNode + CanvasManager
├── 根据 node.type 选择绘制函数
└── 纯函数，不持有状态

EdgeRenderer
├── 接收 Context2D + GraphEdge + GraphNode[] + CanvasManager
├── 需要 GraphNode[] 来查找源/目标节点的中心锚点
└── 纯函数，不持有状态

GridRenderer
├── 接收 Context2D + CanvasManager
├── 根据 viewport 决定可见区域的网格范围
└── 纯函数，不持有状态
```

## 组件层对接

外部使用方（entry Demo / 最终用户）会这样用：

```typescript
@Entry
@Component
struct DemoRenderer {
  @State model: GraphModel = GraphModel.createEmpty()
  private canvasManager = new CanvasManager()

  build() {
    Canvas(this.canvasManager.renderContext)  // 伪代码，待 API 确认
      .width('100%')
      .height('100%')
      .onReady((canvas: CanvasRenderingContext2D) => {
        this.render(canvas)
      })
  }

  private render(ctx: CanvasRenderingContext2D) {
    const vp = this.model.viewport
    // 1. 背景
    GridRenderer.draw(ctx, vp)

    // 2. 连线（先画，让节点盖住连线端点）
    for (const edge of this.model.edges) {
      EdgeRenderer.draw(ctx, edge, this.model.nodes, this.canvasManager)
    }

    // 3. 节点
    for (const node of this.model.nodes) {
      NodeRenderer.draw(ctx, node, this.canvasManager)
    }
  }
}
```

**注意**：上面的 `onReady` 回调是 ArkUI Canvas 组件的实际 API，需要验证具体签名。ofdkit 作者的文章中用了 Canvas 组件，可以参考他的做法。

## 约束

1. **渲染层只读 Model** — NodeRenderer / EdgeRenderer / GridRenderer 是纯函数，不修改 GraphModel
2. **CanvasManager 可以在渲染循环外被修改**（由未来的手势交互控制器操作 zoom/offset）
3. **所有坐标是画布坐标** — GraphModel 中的 x/y 就是画布像素坐标，缩放通过 Canvas transform 实现
4. **不引入新依赖** — 只使用 ArkUI 的 `CanvasRenderingContext2D` API
5. **性能** — MVP 阶段不做脏矩形优化，每次都全量重绘。节点数 < 200 时性能足够

## 参考

- ofdkit-harmony：ArkUI Canvas 在鸿蒙上的实际可用 API 和 pattern
- LogicFlow 的 NodeView / EdgeView：节点和连线的渲染模式
- AntV X6 的 View 层：Canvas 2D 坐标系转换
- bpmn.js 的 diagram-js Draw 模块

## 验收标准

```
在 entry Demo 中显示：

  ✅ 空模型：只看到灰色背景 + 点阵网格
  ✅ 单个矩形节点：蓝色矩形 + 白色文字 "开始" + 居中对齐
  ✅ 单个菱形节点：橙色菱形 + 文字 "审批"
  ✅ 一条直线连线：从节点 A 右边缘 → 节点 B 左边缘，终点有箭头
  ✅ 一条折线连线：按 waypoints 绘制，label "通过" 在中间 waypoint 附近
  ✅ 缩放：鼠标滚轮缩放，节点和连线同比例放大/缩小
  ✅ 平移：拖拽空白区域，整个画面平移
  ✅ 多个节点 + 连线：完整的简单流程图（4 节点 3 边）
  ✅ 验证 GraphModel 在渲染期间未被修改（断言 getNode().x 不变）
```

## 任务拆分

| 子任务 | 预估行数 | 优先级 |
|--------|---------|--------|
| 2-1-1 CanvasManager | ~80 行 | P0 |
| 2-1-2 GridRenderer | ~50 行 | P1 |
| 2-1-3 NodeRenderer | ~150 行 | P0 |
| 2-1-4 EdgeRenderer | ~180 行 | P0 |
| 2-1-5 Demo 页面更新 | ~100 行 | P0 |

预计总代码量：~560 行 ArkTS + Demo 页面更新