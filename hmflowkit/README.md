# hmflowkit

鸿蒙原生 BPMN 2.0 流程图组件库。纯 ArkTS + Canvas 2D 实现，零第三方依赖。

## 功能

- 🎨 纯 ArkTS Canvas 2D 渲染，无 WebView
- 📋 BPMN 2.0 XML 解析（兼容 bpmn.js 导出格式）
- 🔍 节点/连线/网关/泳道完整支持
- 📐 自动适配画布（auto-fit viewport）
- 🖱️ 点击节点高亮选中
- 🏗️ 不可变数据模型 GraphModel
- 💻 鸿蒙 PC + 移动端通用

## 快速开始

```typescript
import { FlowViewer, BpmnXmlParser } from 'hmflowkit'

// 1. 解析 BPMN XML
let model: GraphModel = BpmnXmlParser.parse(bpmnXmlString)

// 2. 一行渲染
FlowViewer({ model: model })
```

## 核心 API

### FlowViewer

BPMN 流程查看器组件。一行代码在 Canvas 上渲染完整流程图。

| 参数 | 类型 | 说明 |
|------|------|------|
| model | GraphModel | 图数据模型 |
| highlightNodeId | string | 高亮节点 ID（可选） |

### BpmnXmlParser

BPMN 2.0 XML 解析器，将标准 BPMN XML 转换为 GraphModel。

- `BpmnXmlParser.parse(xml: string): GraphModel`

### GraphModel

不可变图数据模型。所有修改操作返回新实例。

- `GraphModel.createEmpty(): GraphModel`
- `addNode(node: GraphNode): GraphModel`
- `addEdge(edge: GraphEdge): GraphModel`
- `removeNode(id: string): GraphModel`
- `removeEdge(id: string): GraphModel`
- `getNode(id: string): GraphNode`
- `getEdge(id: string): GraphEdge`
- `getNodes(): GraphNode[]`
- `getEdges(): GraphEdge[]`

### CanvasManager

画布视口管理。缩放、平移、坐标转换。

- `screenToCanvas(screenX, screenY): { x, y }`
- `canvasToScreen(canvasX, canvasY): { x, y }`
- `zoom: number`
- `panX: number`
- `panY: number`

### HitTestManager

Canvas 坐标→元素命中检测。

- `hitTest(canvasX, canvasY, model): HitResult`

## 节点类型

- StartEvent — 开始事件（实心圆）
- EndEvent — 结束事件（空心粗圆）
- Task — 用户任务（矩形）
- Gateway — 网关（菱形）

## 协议

Apache-2.0

## 仓库

https://gitee.com/yourname/hm-flow-kit