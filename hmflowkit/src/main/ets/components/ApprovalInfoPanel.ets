// hmflowkit/src/main/ets/components/ApprovalInfoPanel.ets

import { NodeStatus, NodeStatusMap, MultiInstanceStatus,
  ApprovalOverlayConfig } from '../approval/ApprovalTypes';
import { GraphModel, GraphNode, NodeType } from '../model/GraphModel';
import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct ApprovalInfoPanel {
  @Prop model: GraphModel = GraphModel.createEmpty();
  @Prop nodeStatuses: NodeStatusMap = new NodeStatusMap();
  @Prop selectedNodeId: string = '';
  @Prop visible: boolean = false;
  @Prop canvasHeight: number = 600;
  @Prop approvalConfig: ApprovalOverlayConfig = new ApprovalOverlayConfig();
  @StorageProp('currentColorMode') currentColorMode: number = 0;
  onClose?: () => void;

  @State _multiExpanded: boolean = true;

  private get _bgColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#2A2A2A' : '#F5F5F5';
  }

  private get _textColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#DDD' : '#333';
  }

  private get _secondaryColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#AAA' : '#666';
  }

  private _formatTime(ts: number): string {
    if (ts <= 0) return '—';
    let d: Date = new Date(ts);
    let month: string = (d.getMonth() + 1).toString().padStart(2, '0');
    let day: string = d.getDate().toString().padStart(2, '0');
    let hours: string = d.getHours().toString().padStart(2, '0');
    let mins: string = d.getMinutes().toString().padStart(2, '0');
    return d.getFullYear() + '-' + month + '-' + day + ' ' + hours + ':' + mins;
  }

  private _statusIcon(status: string): string {
    if (status === 'approved') return '✓';
    if (status === 'rejected') return '✗';
    if (status === 'current') return '◉';
    if (status === 'transferred') return '↗';
    return '—';
  }

  private _getDividerColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#444' : '#E0E0E0';
  }

  build() {
    Column() {
      if (this.visible && this.selectedNodeId.length > 0) {
        // 关键修复：将 getter 结果缓存为局部变量，避免 ArkTS 状态系统重复求值
        let cachedNode: GraphNode | null = this.model.getNode(this.selectedNodeId);
        let cachedStatus: NodeStatus | null = this.nodeStatuses.get(this.selectedNodeId);
        let hasData: boolean = cachedStatus != null &&
          (cachedStatus.operator.length > 0 || cachedStatus.result.length > 0 ||
           cachedStatus.timestamp > 0);

        Column() {
          Row() {
            Text('节点详情')
              .fontSize(14).fontColor(this._textColor).fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Button() {
              Text('✕')
                .fontSize(14).fontColor(this._textColor)
            }
            .width(28).height(28).backgroundColor('#00000000')
            .onClick(() => { if (this.onClose) this.onClose(); })
          }
          .width('100%').padding({ left: 12, right: 8, top: 8, bottom: 4 })

          Scroll() {
            Column() {
              if (cachedNode != null) {
                Row() {
                  Text('类型:')
                    .fontSize(11).fontColor(this._secondaryColor).width(60)
                  Text(cachedNode.type)
                    .fontSize(11).fontColor(this._textColor)
                    .layoutWeight(1).maxLines(3)
                }
                .padding({ left: 12, top: 3, bottom: 1 })

                if (cachedNode.label.length > 0) {
                  Row() {
                    Text('名称:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(cachedNode.label)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }

                Row()
                  .width('100%').height(1)
                  .backgroundColor(this._getDividerColor())
                  .margin({ top: 6, bottom: 2 })
              }

              // ── 审批信息 ──
              if (cachedStatus != null && hasData) {
                if (cachedStatus.operator.length > 0) {
                  Row() {
                    Text('审批人:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(cachedStatus.operator)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }
                if (cachedStatus.timestamp > 0) {
                  Row() {
                    Text('时间:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(this._formatTime(cachedStatus.timestamp))
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }
                if (cachedStatus.result.length > 0) {
                  Row() {
                    Text('结果:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(cachedStatus.result)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }
                if (cachedStatus.comment.length > 0) {
                  Row() {
                    Text('意见:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(cachedStatus.comment)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }

                Row()
                  .width('100%').height(1)
                  .backgroundColor(this._getDividerColor())
                  .margin({ top: 6, bottom: 2 })

                // ── 会签详情 ──
                if (cachedStatus.multiInstance != null) {
                  let mi: MultiInstanceStatus = cachedStatus.multiInstance;
                  Row() {
                    Text((this._multiExpanded ? '▼ ' : '▶ ') +
                      '会签详情 (' + mi.completedCount + '/' + mi.totalCount + ')')
                      .fontSize(12).fontColor(this._secondaryColor)
                      .fontWeight(FontWeight.Bold)
                      .layoutWeight(1)
                  }
                  .width('100%').padding({ left: 8, right: 8, top: 6, bottom: 2 })
                  .onClick(() => { this._multiExpanded = !this._multiExpanded; })

                  if (this._multiExpanded) {
                    ForEach(mi.children, (child: NodeStatus, idx: number) => {
                      Row() {
                        Text(this._statusIcon(child.status))
                          .fontSize(11).fontColor(this._textColor)
                        Text(' ' + (child.operator.length > 0 ? child.operator : '—'))
                          .fontSize(11).fontColor(this._textColor)
                        Text(' ' + child.result)
                          .fontSize(10).fontColor(this._secondaryColor)
                        if (child.timestamp > 0) {
                          Text(' ' + this._formatTime(child.timestamp))
                            .fontSize(10).fontColor(this._secondaryColor)
                        }
                      }
                      .padding({ left: 16, top: 2, bottom: 1 })
                    }, (child: NodeStatus, idx: number) => child.nodeId + '_' + idx)
                  }
                }
              } else {
                Text('暂无审批信息')
                  .fontSize(12).fontColor(this._secondaryColor)
                  .fontStyle(FontStyle.Italic)
                  .padding({ left: 12, top: 8, bottom: 8 })
              }
            }
            .width('100%')
          }
          .width('100%').layoutWeight(1)
        }
        .width(280)
        .height(this.canvasHeight)
        .backgroundColor(this._bgColor)
        .border({ width: 1, color: this._getDividerColor() })
        .borderRadius(8)
      }
    }
  }
}
