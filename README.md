# hm-flow-kit

鸿蒙原生 BPMN 流程图组件库。纯 ArkTS + Canvas 2D，零第三方依赖。

## 特性

- **纯原生渲染** — ArkUI Canvas 2D 直绘，不依赖 WebView
- **零学习成本** — 解析 BPMN 2.0 XML 字符串即可渲染，兼容 bpmn.js 导出格式
- **不可变数据模型** — GraphModel 每次修改返回新实例，天然适配 ArkUI @State
- **扩展友好** — 分层架构（Parser → Model → Renderer → Component），每层独立
- **PC 端优先** — 针对鸿蒙 PC 大屏交互设计
- **兼容 OpenHarmony** — 无 HarmonyOS 专有 API 依赖

## 快速开始

```typescript
import { FlowViewer, BpmnXmlParser } from 'hmflowkit'

let model = BpmnXmlParser.parse(bpmnXmlString)

// 在 ArkUI 组件中一行渲染：
FlowViewer({ model: model })
```

## 安装

```bash
ohpm install hmflowkit
```

在 DevEco Studio 中，`entry/oh-package.json5` 添加：

```json5
{
  "dependencies": {
    "hmflowkit": "^0.1.0"
  }
}
```

## 核心 API

### FlowViewer 组件

```typescript
@Component
struct FlowViewer {
  @Prop model: GraphModel
  @Prop xml: string            // BPMN XML 字符串（自动解析到 model）
  @Prop canvasHeight: number   // 画布高度（默认 600）
  @Prop showGrid: boolean      // 是否显示背景网格
  @Prop gridType: GridType     // 网格类型（DOT / LINE / NONE）
  @Prop highlightNodeId: string // 外部控制高亮节点 ID
  @Prop readonly: boolean      // 只读模式
  onNodeClick?: (nodeId: string) => void
  onCanvasReady?: () => void
}
```

### BpmnXmlParser

```typescript
BpmnXmlParser.parse(xml: string): GraphModel  // 静态方法
```

### GraphModel（不可变数据模型）

| 方法 | 说明 |
|------|------|
| `getNodes(): GraphNode[]` | 获取所有节点 |
| `getEdges(): GraphEdge[]` | 获取所有连线 |
| `getNode(id: string): GraphNode \| null` | 按 ID 查找节点 |
| `addNode(n: GraphNode): GraphModel` | 添加节点（返回新实例）|
| `addEdge(e: GraphEdge): GraphModel` | 添加连线（返回新实例）|
| `removeNode(id: string): GraphModel` | 删除节点及关联连线 |
| `moveNode(id, x, y): GraphModel` | 移动节点位置 |
| `toJSON(): GraphModelSnapshot` | 序列化 |
| `static fromJSON(s: GraphModelSnapshot): GraphModel` | 反序列化 |

### RenderConfig（样式配置）

`new RenderConfig()` 无参构造，所有字段有默认值。详见 [CLAUDE.md](./CLAUDE.md) 完整字段表。

### CanvasManager

| 方法 | 说明 |
|------|------|
| `screenToCanvas(sx, sy): CanvasPoint` | 屏幕坐标 → 画布坐标 |
| `canvasToScreen(cx, cy): ScreenPoint` | 画布坐标 → 屏幕坐标 |
| `applyTransform(ctx)` | 应用当前变换到 Canvas 上下文 |
| `pan(dx, dy)` | 平移视口 |
| `zoomAt(cx, cy, delta)` | 以某点为中心缩放 |
| `fitToView(cw, ch, canvasW, canvasH)` | 自适应适配 |

## 已完成功能

### BPMN 2.0 元素覆盖

| 元素类型 | 解析 | 渲染 | 说明 |
|---------|------|------|------|
| StartEvent / EndEvent | ✅ | ✅ | 空心圆 / 实心圆 |
| Task（含 7 种子类型） | ✅ | ✅ | userTask/serviceTask/scriptTask/manualTask/sendTask/receiveTask/businessRuleTask，按子类型分色 |
| ExclusiveGateway / ParallelGateway / InclusiveGateway | ✅ | ✅ | 菱形渲染 |
| SequenceFlow | ✅ | ✅ | 折线 + 实心箭头 |
| BPMNShape (坐标) / BPMNEdge (waypoints) | ✅ | ✅ | 完整 DI 支持 |
| IntermediateThrowEvent / IntermediateCatchEvent | ✅ | ⚠️ | 按 startEvent 样式渲染 |
| BoundaryEvent | ✅ | ⚠️ | 按 startEvent 样式渲染 |

### 组件能力

- [x] FlowViewer 一行渲染（`FlowViewer({ model })` / `FlowViewer({ xml })`）
- [x] 网格背景（点阵/线网格/无）
- [x] 缩放与平移（PanGesture 拖拽）
- [x] 自适应视口（auto-fit）
- [x] 节点点击高亮
- [x] 全屏覆盖层
- [x] 按 NodeType + 子类型差异化配色

### 尚未支持

- 泳道（Pool / Lane）
- 中间事件图标（Timer/Message/Error 等）
- BoundaryEvent 附着渲染
- MessageFlow / ConditionalFlow
- 交互编辑 / 拖拽

## 架构

```
UI 组件层  →  FlowViewer / FlowDesigner
Renderer 层 →  NodeRenderer / EdgeRenderer / GridRenderer
Manager 层  →  CanvasManager / HitTestManager
Model 层    →  GraphModel (唯一数据源)
Parser 层   →  BpmnXmlParser
```

## 许可

Apache-2.0

## 作者

lizhen