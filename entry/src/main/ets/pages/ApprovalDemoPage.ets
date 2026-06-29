/**
 * ApprovalDemoPage — Spec 09 审批流全场景覆盖演示
 *
 * 支持两种底图：
 *   Kitchen Sink (BPMN) — 按钮默认
 *   Swimlane (drawio) — CF 跨功能流程图
 */
import {
  BpmnXmlParser, FlowViewer, GraphModel, PlaneHierarchy,
  DrawioXmlParser, DrawioNodeDrawer, DrawioParseResult,
  NodeStatus, MultiInstanceStatus, EdgeTrail, EdgeTrailKind,
  NodeStatusMap, ApprovalOverlayConfig, PresetId
} from 'hmflowkit'
import { resourceManager } from '@kit.LocalizationKit'
import { util } from '@kit.ArkTS'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct ApprovalDemoPage {
  @State model: GraphModel = GraphModel.createEmpty()
  @State loading: boolean = true
  @State errorMsg: string = ''
  @State nodeStatuses: NodeStatusMap = new NodeStatusMap()
  @State edgeTrails: EdgeTrail[] = []
  @State isDrawio: boolean = false
  @State drawioLabel: string = 'Swimlane (drawio)'
  @State dataVersion: number = 0

  aboutToAppear(): void {
    this.loadKitchenSink()
  }

  async loadKitchenSink(): Promise<void> {
    try {
      let context = getContext(this)
      let rawData: Uint8Array = await context.resourceManager.getRawFileContent('kitchen-sink.bpmn')
      let decoder = new util.TextDecoder('utf-8')
      let xmlStr: string = decoder.decodeToString(rawData)
      this.isDrawio = false
      this.drawioLabel = 'Swimlane (drawio)'
      this.buildBpmnMockData()
      this.model = BpmnXmlParser.parse(xmlStr)
      this.dataVersion++
      this.loading = false
    } catch (e) {
      this.errorMsg = 'Failed: ' + e
      this.loading = false
    }
  }

  async loadSwimlane(): Promise<void> {
    try {
      DrawioNodeDrawer.init()
      let context = getContext(this)
      let rawData: Uint8Array = await context.resourceManager.getRawFileContent('swinlane.drawio')
      let decoder = new util.TextDecoder('utf-8')
      let xmlStr: string = decoder.decodeToString(rawData)
      let result: DrawioParseResult = DrawioXmlParser.parse(xmlStr)
      this.isDrawio = true
      this.drawioLabel = 'Kitchen Sink (BPMN)'
      this.buildDrawioMockData()
      this.model = result.model
      this.dataVersion++
      this.loading = false
    } catch (e) {
      this.errorMsg = 'Failed: ' + e
      this.loading = false
    }
  }

  toggleSource(): void {
    this.loading = true
    if (this.isDrawio) {
      this.loadKitchenSink()
    } else {
      this.loadSwimlane()
    }
  }

  private buildBpmnMockData(): void {
    this.nodeStatuses = new NodeStatusMap()
    this.edgeTrails = []
    let now: number = Date.now()

    this.nodeStatuses.set('Task_0qibn8y',
      new NodeStatus('Task_0qibn8y', 'current', '张三', '', now, '', '审批中'))
    this.nodeStatuses.set('Task_12nft3n',
      new NodeStatus('Task_12nft3n', 'approved', '李四', '', now - 3600000, '同意', '同意'))
    this.nodeStatuses.set('Task_0t0pnde',
      new NodeStatus('Task_0t0pnde', 'approved', '王五', '', now - 7200000, '无异议', '同意'))
    this.nodeStatuses.set('Task_0vcqxha',
      new NodeStatus('Task_0vcqxha', 'rejected', '赵六', '', now - 1800000, '材料不全，请补充', '驳回至发起人'))
    this.nodeStatuses.set('Task_1x2pxcn',
      new NodeStatus('Task_1x2pxcn', 'skipped'))
    this.nodeStatuses.set('Task_1mvn5bz',
      new NodeStatus('Task_1mvn5bz', 'skipped'))
    this.nodeStatuses.set('Task_0oz8m30',
      new NodeStatus('Task_0oz8m30', 'transferred', '孙七', '', now - 900000, '', '转办至陈八'))
    this.nodeStatuses.set('StartEvent_1',
      new NodeStatus('StartEvent_1', 'approved', '', '', now - 86400000, '', '流程发起'))
    this.nodeStatuses.set('StartEvent_124mvrl',
      new NodeStatus('StartEvent_124mvrl', 'approved', '', '', now - 86000000, '', ''))

    let child1: NodeStatus = new NodeStatus('child_1', 'approved', '周九', '', now - 3600000, '同意', '同意')
    let child2: NodeStatus = new NodeStatus('child_2', 'approved', '吴十', '', now - 1800000, '同意', '同意')
    let child3: NodeStatus = new NodeStatus('child_3', 'current', '郑十一', '', now, '', '审批中')
    let miNode: NodeStatus = new NodeStatus('Task_11mt25q', 'current', '会签中', '', now, '', '2/3 完成')
    miNode.withMultiInstance(3, 2, [child1, child2, child3])
    this.nodeStatuses.set('Task_11mt25q', miNode)

    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1lzbqcf', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_096651s', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1kzeawi', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_0o98gnu', 'rejected', '驳回', now - 1800000, '赵六'))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1w1mjsk', 'rejected', '驳回至发起人', now - 2000000))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_03fvpge', 'historical', '', now - 7200000))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_01nciaj', 'historical', '', now - 3600000))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1o24o7s', 'skipped', '条件不满足'))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_16qfe96', 'skipped', '条件不满足'))
  }

  /**
   * swinlane.drawio CF 流程图的审批 mock：
   *   Start → Find barista → Request latte → Decision → Buy latte → Barista → Drink latte → End
   */
  private buildDrawioMockData(): void {
    this.nodeStatuses = new NodeStatusMap()
    this.edgeTrails = []
    let now: number = Date.now()
    let prefix: string = '3nuBFxr9cyL0pnOWT2aG-'

    this.nodeStatuses.set(prefix + '6',
      new NodeStatus(prefix + '6', 'approved', '', '', now - 7200000, '', '流程发起'))
    this.nodeStatuses.set(prefix + '7',
      new NodeStatus(prefix + '7', 'approved', '张三', '', now - 3600000, '已找到咖啡师', '同意'))
    this.nodeStatuses.set(prefix + '9',
      new NodeStatus(prefix + '9', 'current', '李四', '', now, '', '审批中'))
    this.nodeStatuses.set(prefix + '10',
      new NodeStatus(prefix + '10', 'rejected', '王五', '', now - 900000, '余额不足', '驳回至发起人'))
    this.nodeStatuses.set(prefix + '13',
      new NodeStatus(prefix + '13', 'transferred', '赵六', '', now - 600000, '', '转办至孙七'))
    this.nodeStatuses.set(prefix + '14',
      new NodeStatus(prefix + '14', 'skipped'))

    // 会签节点 (mock 到 Request latte 上)
    let c1: NodeStatus = new NodeStatus('dc_1', 'approved', '员工A', '', now - 3600000, '通过', '同意')
    let c2: NodeStatus = new NodeStatus('dc_2', 'current', '员工B', '', now, '', '审批中')
    let miNode: NodeStatus = new NodeStatus(prefix + '21', 'current', '会签中', '', now, '', '1/2 完成')
    miNode.withMultiInstance(2, 1, [c1, c2])
    this.nodeStatuses.set(prefix + '21', miNode)

    // 流转路径
    this.edgeTrails.push(new EdgeTrail(prefix + '5', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail(prefix + '24', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail(prefix + '25', 'rejected', '驳回', now - 900000))
    this.edgeTrails.push(new EdgeTrail(prefix + '26', 'historical', '', now - 3600000))
    this.edgeTrails.push(new EdgeTrail(prefix + '27', 'active', '', now - 1800000))
    this.edgeTrails.push(new EdgeTrail(prefix + '12', 'skipped', '流程终止'))
  }

  build() {
    Column() {
      Row() {
        Button('← 返回')
          .fontSize(14)
          .onClick(() => { router.back() })

        Button(this.drawioLabel)
          .fontSize(14)
          .fontColor('#1565C0')
          .onClick(() => { this.toggleSource() })

        Text(this.isDrawio ? 'Drawio Swimlane' : 'BPMN Kitchen Sink')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row() {
          this.legendDot('#F57F17', '审批中')
          this.legendDot('#1565C0', '已批')
          this.legendDot('#C62828', '驳回')
          this.legendDot('#BDBDBD', '跳过')
          this.legendDot('#7B1FA2', '转办')
        }
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor('#FAFAFA')

      if (this.loading) {
        Text('加载中...')
          .fontSize(14).fontColor('#999').layoutWeight(1)
      } else if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(13).fontColor('#E53935').layoutWeight(1)
      } else {
        FlowViewer({
          model: this.model,
          nodeStatuses: this.nodeStatuses,
          edgeTrails: this.edgeTrails,
          approvalColorPreset: 'GOVERNMENT',
          dataVersion: this.dataVersion
        })
          .width('100%')
          .layoutWeight(1)
      }

      Row() {
        Text('点击节点查看审批详情  |  i 按钮打开信息面板  |  📋 复制全文')
          .fontSize(10).fontColor('#888').maxLines(1).textAlign(TextAlign.Center)
      }
      .width('100%').padding({ top: 4, bottom: 4 }).backgroundColor('#FAFAFA')
    }
    .width('100%').height('100%')
  }

  @Builder
  legendDot(color: string, label: string) {
    Row() {
      Circle({ width: 8, height: 8 }).fill(color)
      Text(label).fontSize(10).fontColor('#666').margin({ left: 2, right: 6 })
    }
  }
}
