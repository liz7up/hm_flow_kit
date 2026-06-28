/**
 * ApprovalDemoPage — Spec 09 审批流全场景覆盖演示
 *
 * 使用 kitchen-sink.bpmn 作为底图，mock 所有审批状态场景：
 *   1. 节点状态渲染：approved/rejected/current/skipped/transferred/pending
 *   2. 流转路径高亮：active(green)/rejected(red dashed)/historical(gray)/skipped(gray dotted)
 *   3. 会签多实例：底部进度标记 "2/3" + 面板查看子状态
 *   4. 信息面板：点击节点查看审批人/时间/结果/意见
 *   5. 脉冲动画：current 节点自动脉冲 5 周期
 *   6. 预设主题：GOVERNMENT
 */
import {
  BpmnXmlParser, FlowViewer, GraphModel, PlaneHierarchy,
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

  aboutToAppear(): void {
    this.init()
  }

  async init(): Promise<void> {
    try {
      let context = getContext(this)
      let rawData: Uint8Array = await context.resourceManager.getRawFileContent('kitchen-sink.bpmn')
      let decoder = new util.TextDecoder('utf-8')
      let xmlStr: string = decoder.decodeToString(rawData)
      this.model = BpmnXmlParser.parse(xmlStr)
      this.buildMockData()
      this.loading = false
    } catch (e) {
      this.errorMsg = 'Failed: ' + e
      this.loading = false
    }
  }

  /**
   * 构建覆盖全部 6 种审批场景的 mock 数据。
   *
   * kitchen-sink.bpmn 中的关键节点：
   *   Task_0qibn8y   → current（当前审批节点，脉冲动画）
   *   Task_12nft3n   → approved（已通过）
   *   Task_0vcqxha   → rejected（已驳回）
   *   Task_1x2pxcn   → skipped（条件不满足，跳过）
   *   Task_0oz8m30   → transferred（转办）
   *   Task_11mt25q   → multiInstance（会签）
   *   ExclusiveGateway_0w2zn42 → 条件网关（展示分支高亮）
   */
  private buildMockData(): void {
    let now: number = Date.now()

    // ═══ 节点状态 mock ═══
    // 当前审批节点
    let currentStatus: NodeStatus = new NodeStatus(
      'Task_0qibn8y', 'current', '张三', '', now, '', '审批中'
    )

    // 已通过节点
    let approved1: NodeStatus = new NodeStatus(
      'Task_12nft3n', 'approved', '李四', '', now - 3600000, '同意', '同意'
    )
    let approved2: NodeStatus = new NodeStatus(
      'Task_0t0pnde', 'approved', '王五', '', now - 7200000, '无异议', '同意'
    )

    // 已驳回节点
    let rejectedStatus: NodeStatus = new NodeStatus(
      'Task_0vcqxha', 'rejected', '赵六', '', now - 1800000, '材料不全，请补充', '驳回至发起人'
    )

    // 跳过节点（条件不满足，未走此分支）
    let skippedStatus: NodeStatus = new NodeStatus(
      'Task_1x2pxcn', 'skipped'
    )
    let skipped2: NodeStatus = new NodeStatus(
      'Task_1mvn5bz', 'skipped'
    )

    // 转办节点
    let transferredStatus: NodeStatus = new NodeStatus(
      'Task_0oz8m30', 'transferred', '孙七', '', now - 900000, '', '转办至陈八'
    )

    // 会签节点：3 人中 2 人已审批
    let child1: NodeStatus = new NodeStatus(
      'child_1', 'approved', '周九', '', now - 3600000, '同意', '同意'
    )
    let child2: NodeStatus = new NodeStatus(
      'child_2', 'approved', '吴十', '', now - 1800000, '同意', '同意'
    )
    let child3: NodeStatus = new NodeStatus(
      'child_3', 'current', '郑十一', '', now, '', '审批中'
    )
    let multiInstanceNode: NodeStatus = new NodeStatus(
      'Task_11mt25q', 'current', '会签中', '', now, '', '2/3 完成'
    )
    multiInstanceNode.withMultiInstance(3, 2, [child1, child2, child3])

    // 填充 nodeStatuses
    this.nodeStatuses.set('Task_0qibn8y', currentStatus)
    this.nodeStatuses.set('Task_12nft3n', approved1)
    this.nodeStatuses.set('Task_0t0pnde', approved2)
    this.nodeStatuses.set('Task_0vcqxha', rejectedStatus)
    this.nodeStatuses.set('Task_1x2pxcn', skippedStatus)
    this.nodeStatuses.set('Task_1mvn5bz', skipped2)
    this.nodeStatuses.set('Task_0oz8m30', transferredStatus)
    this.nodeStatuses.set('Task_11mt25q', multiInstanceNode)

    // 事件节点状态
    this.nodeStatuses.set('StartEvent_1',
      new NodeStatus('StartEvent_1', 'approved', '', '', now - 86400000, '', '流程发起'))
    this.nodeStatuses.set('StartEvent_124mvrl',
      new NodeStatus('StartEvent_124mvrl', 'approved', '', '', now - 86000000, '', ''))

    // ═══ 流转路径 mock ═══
    // 活跃路径（绿色，当前审批流经的边）
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1lzbqcf', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_096651s', 'active', '', now))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1kzeawi', 'active', '', now))

    // 驳回路径（红色虚线）
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_0o98gnu', 'rejected', '驳回', now - 1800000, '赵六'))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1w1mjsk', 'rejected', '驳回至发起人', now - 2000000, ''))

    // 历史路径（灰线，驳回再提交后保留）
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_03fvpge', 'historical', '', now - 7200000))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_01nciaj', 'historical', '', now - 3600000))

    // 跳过路径（灰虚线，条件分支未走）
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_1o24o7s', 'skipped', '条件不满足', 0))
    this.edgeTrails.push(new EdgeTrail('SequenceFlow_16qfe96', 'skipped', '条件不满足', 0))
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('← 返回')
          .fontSize(14)
          .onClick(() => { router.back() })

        Text('审批流全场景 Demo')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 状态图例
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

      // 加载状态
      if (this.loading) {
        Text('加载中...')
          .fontSize(14)
          .fontColor('#999')
          .layoutWeight(1)
      } else if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(13)
          .fontColor('#E53935')
          .layoutWeight(1)
      } else {
        // 审批流查看器 — GOVERNMENT 预设 + mock 数据
        FlowViewer({
          model: this.model,
          nodeStatuses: this.nodeStatuses,
          edgeTrails: this.edgeTrails,
          approvalColorPreset: 'GOVERNMENT'
        })
          .width('100%')
          .layoutWeight(1)
      }

      // 底部提示
      Row() {
        Text('点击任意状态节点查看审批详情  |  '
          + '绿色边 = 有效路径 | 红色虚线边 = 驳回 | '
          + '灰色边 = 历史/跳过 | "2/3" = 会签进度')
          .fontSize(10)
          .fontColor('#888')
          .maxLines(2)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
      .backgroundColor('#FAFAFA')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  legendDot(color: string, label: string) {
    Row() {
      Circle({ width: 8, height: 8 })
        .fill(color)
      Text(label)
        .fontSize(10)
        .fontColor('#666')
        .margin({ left: 2, right: 6 })
    }
  }
}
