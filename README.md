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

### FlowViewer

一行渲染的流程查看器组件。

```typescript
@Prop model?: GraphModel  // 要渲染的图模型
```

### BpmnXmlParser

BPMN 2.0 XML 解析器。

| 方法 | 说明 |
|------|------|
| `parse(xml: string): GraphModel` | 解析 BPMN 2.0 XML 字符串 |

### GraphModel

不可变图数据模型。所有修改方法返回新实例，原实例不变。

| 方法 | 说明 |
|------|------|
| `getNodes(): GraphNode[]` | 获取所有节点 |
| `getEdges(): GraphEdge[]` | 获取所有连线 |
| `addNode(n: GraphNode): GraphModel` | 添加节点（返回新实例）|
| `addEdge(e: GraphEdge): GraphModel` | 添加连线（返回新实例）|
| `removeNode(id: string): GraphModel` | 删除节点及关联连线 |
| `toJSON(): string` | 序列化为 JSON |
| `fromJSON(json: string): GraphModel` | 从 JSON 反序列化 |

### CanvasManager

视口管理（缩放、平移、坐标转换）。

| 方法 | 说明 |
|------|------|
| `screenToCanvas(sx, sy): {x, y}` | 屏幕坐标 → 画布坐标 |
| `canvasToScreen(cx, cy): {x, y}` | 画布坐标 → 屏幕坐标 |
| `applyTransform(ctx)` | 应用当前变换到 Canvas 上下文 |

## 已完成功能

- [x] 4 种 BPMN 节点渲染（开始/结束事件、用户任务、网关）
- [x] 连线渲染（折线 + 箭头）
- [x] BPMN 2.0 XML 完整解析（兼容 bpmn.js 导出格式）
- [x] 审批流程自动着色（完成态=绿、进行中=蓝、驳回=红）
- [x] 泳道（Pool/Lane）渲染
- [x] 网格背景
- [x] 缩放与平移（鼠标滚轮 + 拖拽）
- [x] 自适应视口
- [x] 节点点击高亮
- [x] 31 项自动化验收测试

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