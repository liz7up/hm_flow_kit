/**
 * hello-graph — hm-flow-kit 最简渲染示例
 *
 * 演示如何用代码构建一个 GraphModel，然后用 FlowViewer 渲染。
 * 复制本文件到你的 entry/src/main/ets/pages/Index.ets 即可运行。
 */

import { GraphModel, GraphNode, NodeType, GraphEdge, EdgeStyle, Waypoint, FlowViewer } from 'hmflowkit'

function buildModel(): GraphModel {
  let model = GraphModel.createEmpty()

  // 创建 5 种不同类型的节点
  let start = new GraphNode('start', NodeType.START_EVENT, 100, 200, 40, 40, '开始', {})
  let task = new GraphNode('task1', NodeType.TASK, 200, 180, 120, 60, '审批', { 'bpmnElement': 'userTask' })
  let gateway = new GraphNode('gw1', NodeType.GATEWAY, 400, 190, 50, 50, '通过?', {})
  let task2 = new GraphNode('task2', NodeType.TASK, 530, 180, 120, 60, '执行', { 'bpmnElement': 'serviceTask' })
  let end = new GraphNode('end', NodeType.END_EVENT, 730, 200, 40, 40, '结束', {})

  model = model.addNodes([start, task, gateway, task2, end])

  // 创建连线
  model = model.addEdge(new GraphEdge('e1', 'start', 'task1',
    [new Waypoint(140, 220), new Waypoint(200, 210)], EdgeStyle.POLYLINE, '', {}))
  model = model.addEdge(new GraphEdge('e2', 'task1', 'gw1',
    [new Waypoint(320, 210), new Waypoint(400, 215)], EdgeStyle.POLYLINE, '', {}))
  model = model.addEdge(new GraphEdge('e3', 'gw1', 'task2',
    [new Waypoint(450, 215), new Waypoint(530, 210)], EdgeStyle.POLYLINE, '同意', {}))
  model = model.addEdge(new GraphEdge('e4', 'task2', 'end',
    [new Waypoint(650, 210), new Waypoint(730, 220)], EdgeStyle.POLYLINE, '', {}))

  return model
}

@Entry
@Component
struct MainPage {
  @State model: GraphModel = buildModel()

  build() {
    FlowViewer({ model: this.model, canvasHeight: 400, showGrid: true,
      onNodeClick: (id: string) => {
        console.info('Node clicked: ' + id)
      }
    })
  }
}
