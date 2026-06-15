# Spec 06 — FlowViewer 组件层

> **状态：已完成 ✅**
> **依赖：Spec 01 ✅、Spec 02 ✅、Spec 03 ✅**
> **目标：给开发者一个一行代码可用的 BPMN 查看组件**

---

## 一、目标

封装现有三层（Parser → Model → Renderer），对外暴露两个组件：

| 组件 | 用途 |
|------|------|
| `FlowViewer` | 只读 BPMN 流程图查看器（嵌入 OA 页面） |
| `FlowMiniMap` | 缩略图导航（可选，独立组件） |

---

## 二、精确 API 签名（从现有代码提取）

### 2.1 GraphModel（来自 Spec 01 — 已完成，不可改）

```typescript
// 构造器
static createEmpty(): GraphModel

// 查询（全部无副作用）
getNodes(): GraphNode[]
getNode(id: string): GraphNode | null
hasNode(id: string): boolean
getNodeCount(): number
getEdges(): GraphEdge[]
getEdge(id: string): GraphEdge | null
hasEdge(id: string): boolean
getEdgeCount(): number
getOutgoingEdges(nodeId: string): GraphEdge[]
getIncomingEdges(nodeId: string): GraphEdge[]
getConnectedEdges(nodeId: string): GraphEdge[]

// 修改（全部返回新实例，不可变）
addNode(node: GraphNode): GraphModel
addNodes(nodes: GraphNode[]): GraphModel
addEdge(edge: GraphEdge): GraphModel
addEdges(edges: GraphEdge[]): GraphModel
removeNode(nodeId: string): GraphModel   // 级联删除关联边
removeEdge(edgeId: string): GraphModel
moveNode(nodeId: string, x: number, y: number): GraphModel
updateNode(nodeId: string, updates: Record<string, string>): GraphModel
updateEdge(edgeId: string, updates: Record<string, string>): GraphModel

// 视口（不可变）
setViewport(viewport: Viewport): GraphModel
getViewport(): Viewport

// 序列化
toSnapshot(): GraphModelSnapshot
static fromSnapshot(snapshot: GraphModelSnapshot): GraphModel
```

### 2.2 数据类型（全部以 class 定义）

```typescript
class GraphNode {
  id: string
  type: NodeType
  x: number       // 画布坐标，左上角
  y: number
  width: number
  height: number
  label: string
  properties: Record<string, string>
  
  constructor(id: string, type: NodeType, x: number, y: number,
              width: number, height: number, label: string,
              properties: Record<string, string>)
}

enum NodeType {
  START_EVENT = 'startEvent',
  END_EVENT = 'endEvent',
  TASK = 'task',
  GATEWAY = 'gateway'
}

class GraphEdge {
  id: string
  sourceId: string
  targetId: string
  waypoints: Waypoint[]
  style: EdgeStyle
  label: string
  properties: Record<string, string>
  
  constructor(id: string, sourceId: string, targetId: string,
              waypoints: Waypoint[], style: EdgeStyle, label: string,
              properties: Record<string, string>)
}

class Waypoint {
  x: number
  y: number
  constructor(x: number, y: number)
}

enum EdgeStyle { STRAIGHT = 'straight', POLYLINE = 'polyline' }

class Viewport {
  x: number     // 视口左上角在画布中的x坐标
  y: number
  zoom: number  // >0, 1.0 = 100%
  constructor(x: number, y: number, zoom: number)
}

class GraphModelSnapshot {
  nodes: GraphNode[]
  edges: GraphEdge[]
  viewportX: number
  viewportY: number
  viewportZoom: number
  
  constructor(nodes: GraphNode[], edges: GraphEdge[],
              viewportX: number, viewportY: number, viewportZoom: number)
}
```

### 2.3 BpmnXmlParser（来自 Spec 03 — 已完成，不可改）

```typescript
class BpmnXmlParser {
  parse(xmlString: string): GraphModel  // 解析失败抛出 Error
}
```

### 2.4 Renderer（来自 Spec 02 — 已完成，不可改）

```typescript
// 全部是静态方法，接收 CanvasRenderingContext2D
class NodeRenderer {
  static render(ctx: CanvasRenderingContext2D, node: GraphNode): void
  static renderAll(ctx: CanvasRenderingContext2D, nodes: GraphNode[]): void
}

class EdgeRenderer {
  static render(ctx: CanvasRenderingContext2D, edge: GraphEdge,
                sourceNode: GraphNode, targetNode: GraphNode): void
  static renderAll(ctx: CanvasRenderingContext2D, edges: GraphEdge[],
                   getNodeById: (id: string) => GraphNode | null): void
}

class GridRenderer {
  static render(ctx: CanvasRenderingContext2D, width: number,
                height: number, config: GridConfig): void
}

class GridConfig {
  gridType: GridType
  gridSize: number
  gridColor: string
  constructor(gridType: GridType, gridSize: number, gridColor: string)
}

enum GridType { DOTS = 'dots', LINES = 'lines', NONE = 'none' }

class CanvasManager {
  zoom: number
  offsetX: number
  offsetY: number
  
  constructor(canvasWidth: number, canvasHeight: number)
  applyTransform(ctx: CanvasRenderingContext2D): void
  screenToCanvas(screenX: number, screenY: number): {x: number, y: number}
  canvasToScreen(canvasX: number, canvasY: number): {x: number, y: number}
  setViewport(viewport: Viewport): void
  setCanvasSize(width: number, height: number): void
}

class HitTestManager {
  updateNodes(nodes: GraphNode[]): void
  hitTest(screenX: number, screenY: number, canvasManager: CanvasManager): HitResult
}

class HitResult {
  type: HitType
  nodeId: string
  edgeId: string
  constructor(type: HitType, nodeId: string, edgeId: string)
}

enum HitType { NONE = 'none', NODE = 'node', EDGE = 'edge' }

class NodeRect {
  x: number; y: number; width: number; height: number
  constructor(x: number, y: number, width: number, height: number)
}

class RenderConfig {
  static NODE_MIN_WIDTH: number = 80
  static NODE_MIN_HEIGHT: number = 40
  static DIAMOND_SIZE: number = 50
  static CIRCLE_RADIUS: number = 18
  static ARROW_SIZE: number = 8
  static NODE_COLORS: Record<string, Record<string, string>>
  static getNodeRect(node: GraphNode): NodeRect
  static getCenter(node: GraphNode): {x: number, y: number}
}
```

---

## 三、FlowViewer 组件

### 3.1 构造参数

```typescript
@Component
export struct FlowViewer {
  // 必填（三选一）
  @Prop model?: GraphModel           // 已有 model（调用方已 parse）
  @Prop xml?: string                  // BPMN XML 字符串（组件内部 parse）
  
  // 选填
  @Prop height: number = 600          // 组件高度（vp）
  @Prop showGrid: boolean = true      // 是否显示网格背景
  @Prop gridType: GridType = GridType.DOTS
  @Prop fitOnLoad: boolean = true     // 首次加载自动缩放适配
  @Prop highlightNodeId: string = ''  // 高亮节点 ID（OA 查看进度用）
  @Prop readonly: boolean = true      // 只读模式（true）
  
  // 事件回调
  onNodeClick?: (nodeId: string) => void
  onCanvasReady?: () => void
}
```

### 3.2 内部行为

```
aboutToAppear():
  1. 如果传入 xml → 调用 BpmnXmlParser.parse(xml) → 得到 GraphModel
  2. 如果传入 model → 直接使用
  3. 如果 fitOnLoad=true → 计算所有节点的包围盒 → 调整 Viewport 让整张图居中适配
  4. 初始化 CanvasManager

build():
  Canvas 组件：
    ├── onReady 回调中获取 CanvasRenderingContext2D
    ├── 调用 CanvasManager.applyTransform()
    ├── 如果 showGrid → GridRenderer.render()
    ├── EdgeRenderer.renderAll()
    ├── NodeRenderer.renderAll()
    └── 如果 highlightNodeId 不为空 → 叠加高亮层（半透明蓝色遮罩）

onPageShow(): 触发重绘
```

### 3.3 高亮节点逻辑

```typescript
// highlightNodeId 对应的节点上叠加一个半透明蓝色矩形
if (highlightNodeId.length > 0) {
  let node = this._model!.getNode(highlightNodeId)
  if (node) {
    ctx.fillStyle = 'rgba(24, 144, 255, 0.3)'
    ctx.fillRect(node.x - 4, node.y - 4, node.width + 8, node.height + 8)
  }
}
```

### 3.4 自动适配算法

```typescript
calculateFitViewport(model: GraphModel, canvasW: number, canvasH: number): Viewport {
  let nodes = model.getNodes()
  if (nodes.length == 0) return new Viewport(0, 0, 1.0)
  
  let minX = nodes[0].x; let minY = nodes[0].y
  let maxX = nodes[0].x + nodes[0].width
  let maxY = nodes[0].y + nodes[0].height
  for (let node of nodes) {
    if (node.x < minX) minX = node.x
    if (node.y < minY) minY = node.y
    if (node.x + node.width > maxX) maxX = node.x + node.width
    if (node.y + node.height > maxY) maxY = node.y + node.height
  }
  
  let graphW = maxX - minX + 100   // padding 50
  let graphH = maxY - minY + 100
  let zoomX = canvasW / graphW
  let zoomY = canvasH / graphH
  let zoom = Math.min(zoomX, zoomY, 1.5) // 不超过 150%
  
  return new Viewport(minX - 50, minY - 50, zoom)
}
```

---

## 四、FlowMiniMap 组件（可选）

```typescript
@Component
export struct FlowMiniMap {
  @Prop model: GraphModel
  @Prop width: number = 150
  @Prop height: number = 120
  @Prop viewport: Viewport = new Viewport(0, 0, 1.0)
  @Prop canvasWidth: number = 800
  @Prop canvasHeight: number = 600
}
```

绘制逻辑：所有节点缩略渲染 + 当前视口矩形框。

---

## 五、导出清单（Index.ets）

从 `hmflowkit` 导出的公开 API：

```typescript
// 组件
export { FlowViewer } from './src/main/ets/components/FlowViewer'
export { FlowMiniMap } from './src/main/ets/components/FlowMiniMap'

// Model 层
export { GraphModel } from './src/main/ets/model/GraphModel'
export { GraphNode } from './src/main/ets/model/GraphModel'
export { GraphEdge } from './src/main/ets/model/GraphModel'
export { Waypoint } from './src/main/ets/model/GraphModel'
export { Viewport } from './src/main/ets/model/GraphModel'
export { GraphModelSnapshot } from './src/main/ets/model/GraphModel'
export { NodeType } from './src/main/ets/model/GraphModel'
export { EdgeStyle } from './src/main/ets/model/GraphModel'

// Parser 层
export { BpmnXmlParser } from './src/main/ets/parser/BpmnXmlParser'

// Renderer 层
export { NodeRenderer } from './src/main/ets/renderer/NodeRenderer'
export { EdgeRenderer } from './src/main/ets/renderer/EdgeRenderer'
export { GridRenderer } from './src/main/ets/renderer/GridRenderer'
export { GridConfig } from './src/main/ets/renderer/GridRenderer'
export { GridType } from './src/main/ets/renderer/GridRenderer'
export { CanvasManager } from './src/main/ets/renderer/CanvasManager'
export { HitTestManager } from './src/main/ets/renderer/HitTestManager'
export { HitResult } from './src/main/ets/renderer/HitTestManager'
export { HitType } from './src/main/ets/renderer/HitTestManager'
export { NodeRect } from './src/main/ets/renderer/NodeRenderer'
export { RenderConfig } from './src/main/ets/renderer/RenderConfig'
```

---

## 六、验收 Demo

在 `entry/.../pages/Index.ets` 中加入 Spec 06 验收区域：

```typescript
// Spec 06 验收区域（嵌入现有的 Scroll+Column 中）
Text('─── Spec 06: FlowViewer ───').fontSize(16).fontWeight(FontWeight.Bold)
FlowViewer({
  xml: SPEC06_TEST_XML,
  height: 400,
  fitOnLoad: true,
  showGrid: true,
  highlightNodeId: 'Task2',
  onNodeClick: (id: string) => {
    this.spec06NodeClicked = id
  }
})
Text('点击节点: ' + this.spec06NodeClicked).fontSize(14)
```

### SPEC06_TEST_XML（比 Spec 03 更复杂）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  id="Definitions_1">

  <bpmn:process id="Process_1" isExecutable="false">
    <bpmn:startEvent id="Start" name="开始">
      <bpmn:outgoing>Flow_Start_Apply</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:userTask id="Apply" name="提交申请">
      <bpmn:incoming>Flow_Start_Apply</bpmn:incoming>
      <bpmn:outgoing>Flow_Apply_Approve</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:userTask id="Approve" name="领导审批">
      <bpmn:incoming>Flow_Apply_Approve</bpmn:incoming>
      <bpmn:outgoing>Flow_Approve_Gate</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:exclusiveGateway id="Gate" name="通过？">
      <bpmn:incoming>Flow_Approve_Gate</bpmn:incoming>
      <bpmn:outgoing>Flow_Gate_Finance</bpmn:outgoing>
      <bpmn:outgoing>Flow_Gate_Reject</bpmn:outgoing>
    </bpmn:exclusiveGateway>
    <bpmn:userTask id="Finance" name="财务审核">
      <bpmn:incoming>Flow_Gate_Finance</bpmn:incoming>
      <bpmn:outgoing>Flow_Finance_End</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:endEvent id="RejectEnd" name="驳回结束">
      <bpmn:incoming>Flow_Gate_Reject</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:endEvent id="End" name="通过结束">
      <bpmn:incoming>Flow_Finance_End</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_Start_Apply" sourceRef="Start" targetRef="Apply"/>
    <bpmn:sequenceFlow id="Flow_Apply_Approve" sourceRef="Apply" targetRef="Approve"/>
    <bpmn:sequenceFlow id="Flow_Approve_Gate" sourceRef="Approve" targetRef="Gate"/>
    <bpmn:sequenceFlow id="Flow_Gate_Finance" sourceRef="Gate" targetRef="Finance">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">通过</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_Gate_Reject" sourceRef="Gate" targetRef="RejectEnd">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">驳回</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_Finance_End" sourceRef="Finance" targetRef="End"/>
  </bpmn:process>

  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="Shape_Start" bpmnElement="Start">
        <dc:Bounds x="100" y="200" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Shape_Apply" bpmnElement="Apply">
        <dc:Bounds x="200" y="178" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Shape_Approve" bpmnElement="Approve">
        <dc:Bounds x="400" y="178" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Shape_Gate" bpmnElement="Gate">
        <dc:Bounds x="600" y="183" width="50" height="50"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Shape_Finance" bpmnElement="Finance">
        <dc:Bounds x="750" y="178" width="120" height="60"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Shape_RejectEnd" bpmnElement="RejectEnd">
        <dc:Bounds x="650" y="300" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Shape_End" bpmnElement="End">
        <dc:Bounds x="950" y="190" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Edge_Start_Apply" bpmnElement="Flow_Start_Apply">
        <di:waypoint x="136" y="218"/>
        <di:waypoint x="200" y="208"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Edge_Apply_Approve" bpmnElement="Flow_Apply_Approve">
        <di:waypoint x="320" y="208"/>
        <di:waypoint x="400" y="208"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Edge_Approve_Gate" bpmnElement="Flow_Approve_Gate">
        <di:waypoint x="520" y="208"/>
        <di:waypoint x="600" y="208"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Edge_Gate_Finance" bpmnElement="Flow_Gate_Finance">
        <di:waypoint x="650" y="208"/>
        <di:waypoint x="750" y="208"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Edge_Gate_Reject" bpmnElement="Flow_Gate_Reject">
        <di:waypoint x="625" y="233"/>
        <di:waypoint x="668" y="300"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Edge_Finance_End" bpmnElement="Flow_Finance_End">
        <di:waypoint x="870" y="208"/>
        <di:waypoint x="950" y="208"/>
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
```

### Spec 06 验收逻辑（写在 Demo 页面中）

| # | 测试项 | 验证方式 |
|---|--------|---------|
| 1 | FlowViewer 从 XML 渲染 | 肉眼确认 Canvas 上 7 节点 6 连线 |
| 2 | fitOnLoad 自动适配 | 肉眼确认所有节点可见 |
| 3 | highlightNodeId 高亮 | 肉眼确认 Finance 节点有蓝色高亮遮罩 |
| 4 | onNodeClick 回调 | 点击任意节点，Text 显示 "点击节点: xxx" |
| 5 | 从 model 渲染 | 传入 BpmnXmlParser.parse() 的结果，渲染一致 |

---

## 七、交付物

```
hmflowkit/src/main/ets/components/
├── FlowViewer.ets       ← 新建，FlowViewer @Component
└── FlowMiniMap.ets      ← 新建，FlowMiniMap @Component

更新：
└── hmflowkit/Index.ets  加 export { FlowViewer, FlowMiniMap }
```

---

## 八、完成标准

```
验收清单（5 项，全部肉眼+可交互验证）：

  ✅ FlowViewer 从 XML 渲染正确（7 节点 6 连线）
  ✅ fitOnLoad 自动适配（所有节点可见）
  ✅ highlightNodeId 高亮生效
  ✅ onNodeClick 回调触发
  ✅ 从 model 属性渲染正确
```

## 九、更新 SPEC_API.md

验收通过后执行：将 FlowViewer 构造参数和 FlowMiniMap 参数写入 SPEC_API.md。