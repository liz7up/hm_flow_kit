# hmflowkit

鸿蒙原生 BPMN 2.0 流程图组件库。纯 ArkTS + Canvas 2D 实现，零第三方依赖。

## 安装

```bash
ohpm install hmflowkit
```


## 功能

- 🎨 纯 ArkTS Canvas 2D 渲染，无 WebView
- 📋 BPMN 2.0 XML 解析 — 兼容 bpmn.js 导出格式
- 🔷 4 类 Gateway 内部标记 + 10 种 EventDefinition 图标 + 7 种 Task 类型图标
- 🏊 Pool/Lane 泳池泳道 + 3 种 SubProcess 边框（单线/双线/虚线）
- 🔗 SequenceFlow 实线 + MessageFlow 虚线 + Association 关联线
- 🎯 节点/连线/泳道命中检测（HitTest），嵌套元素最小面积优先
- 🌓 系统明暗主题自动适配 + RenderConfig 自定义配色
- 🔲 多平面钻取导航：嵌套子流程展开/折叠 + 面包屑层级跳转
- 📐 自动适配画布（auto-fit）+ 拖拽平移 + 双指缩放 + 浮动缩放按钮
- 🖱️ 点击高亮选中 + 空白取消
- 🏗️ 不可变数据模型 GraphModel + PlaneHierarchy 层级管理
- 🧩 ~30 design token 可配置样式（RenderConfig）
- 📦 120 项自动化单元测试
- 💻 鸿蒙 PC + 移动端通用

## 快速开始

```typescript
import { FlowViewer } from 'hmflowkit'

// 推荐：直接传入 BPMN XML，自动解析、渲染、多平面钻取检测
FlowViewer({ xml: this.bpmnXmlString })
```

## 核心 API

### FlowViewer

唯一入口组件，一行接入。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| xml | string | '' | BPMN XML 字符串（推荐，自动解析 + 钻取检测） |
| model | GraphModel | 空模型 | 编程构建场景 |
| canvasHeight | number | 600 | 画布高度 |
| showGrid | boolean | true | 背景网格 |
| renderConfig | RenderConfig | 默认配置 | 自定义配色 |
| onNodeClick | (nodeId: string) => void | — | 节点点击回调 |
| onCanvasReady | () => void | — | 画布就绪回调 |

### RenderConfig

所有颜色、字体、间距均可配置。默认跟随系统明暗主题。需在 `EntryAbility` 中写入 AppStorage：

```typescript
// EntryAbility
onCreate(want, launchParam) {
  AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
}
onConfigurationUpdate(newConfig) {
  AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
}
```

传 `renderConfig` 可覆盖默认配色，此时不受系统主题切换影响：

```typescript
let config = new RenderConfig()
config.fillColor = '#F0F0F0'
FlowViewer({ xml: this.bpmnXml, renderConfig: config })
```

### BpmnXmlParser

```typescript
BpmnXmlParser.parse(xml: string): GraphModel                // 严格解析
BpmnXmlParser.parseBestEffort(xml: string): ParseResult      // 宽松解析（遇错保留已有数据）
BpmnXmlParser.parseHierarchy(xml: string): PlaneHierarchy    // 多平面层级
```

### GraphModel

不可变数据模型。所有写操作返回新实例。

```typescript
GraphModel.createEmpty(): GraphModel
// 节点
addNode(node): GraphModel        removeNode(id): GraphModel
moveNode(id, x, y): GraphModel   getNode(id): GraphNode | null
getNodes(): GraphNode[]
// 边
addEdge(edge): GraphModel        removeEdge(id): GraphModel
getEdge(id): GraphEdge | null    getEdges(): GraphEdge[]
// Pool / Lane
addPool(pool): GraphModel        removePool(id): GraphModel
getPools(): Pool[]               getLaneByNode(nodeId): Lane | null
// 序列化
toJSON(): GraphModelSnapshot     static fromJSON(s): GraphModel
```

## 协议

Apache-2.0

## 仓库

https://github.com/liz7up/hm_flow_kit

