// hmflowkit/src/main/ets/components/ApprovalInfoPanel.ets

import { NodeStatus, NodeStatusMap, MultiInstanceStatus,
  ApprovalOverlayConfig } from '../approval/ApprovalTypes';
import { GraphModel, GraphNode, NodeType } from '../model/GraphModel';
import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct ApprovalInfoPanel {
  @Prop model: GraphModel = GraphModel.createEmpty();
  @Prop nodeStatuses?: NodeStatusMap;
  @Prop selectedNodeId: string = '';
  @Prop visible: boolean = false;
  @Prop canvasHeight: number = 600;
  @Prop approvalConfig?: ApprovalOverlayConfig;
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

  private get _node(): GraphNode | null {
    if (this.selectedNodeId.length === 0) return null;
    return this.model.getNode(this.selectedNodeId);
  }

  private get _status(): NodeStatus | null {
    if (this.nodeStatuses === undefined || this.selectedNodeId.length === 0) return null;
    return this.nodeStatuses.get(this.selectedNodeId);
  }

  private get _hasApprovalData(): boolean {
    let s: NodeStatus | null = this._status;
    return s !== null && (s.operator.length > 0 || s.result.length > 0 || s.timestamp > 0);
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
    if (!this.visible || this.selectedNodeId.length === 0) {
      return;
    }
    Column() {
      // ── 标题栏 ──
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
          // ── 节点基础信息 ──
          if (this._node !== null) {
            Row() {
              Text('类型:')
                .fontSize(11).fontColor(this._secondaryColor)
                .width(60)
              Text(this._node.type)
                .fontSize(11).fontColor(this._textColor)
                .layoutWeight(1).maxLines(3)
            }
            .padding({ left: 12, top: 3, bottom: 1 })

            if (this._node.label.length > 0) {
              Row() {
                Text('名称:')
                  .fontSize(11).fontColor(this._secondaryColor)
                  .width(60)
                Text(this._node.label)
                  .fontSize(11).fontColor(this._textColor)
                  .layoutWeight(1).maxLines(3)
              }
              .padding({ left: 12, top: 3, bottom: 1 })
            }

            // divider
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(this._getDividerColor())
              .margin({ top: 6, bottom: 2 })
          }

          // ── 审批信息 ──
          if (this._status !== null && this._hasApprovalData) {
            let s: NodeStatus = this._status;
            if (s.operator.length > 0) {
              Row() {
                Text('审批人:')
                  .fontSize(11).fontColor(this._secondaryColor)
                  .width(60)
                Text(s.operator)
                  .fontSize(11).fontColor(this._textColor)
                  .layoutWeight(1).maxLines(3)
              }
              .padding({ left: 12, top: 3, bottom: 1 })
            }
            if (s.timestamp > 0) {
              Row() {
                Text('时间:')
                  .fontSize(11).fontColor(this._secondaryColor)
                  .width(60)
                Text(this._formatTime(s.timestamp))
                  .fontSize(11).fontColor(this._textColor)
                  .layoutWeight(1).maxLines(3)
              }
              .padding({ left: 12, top: 3, bottom: 1 })
            }
            if (s.result.length > 0) {
              Row() {
                Text('结果:')
                  .fontSize(11).fontColor(this._secondaryColor)
                  .width(60)
                Text(s.result)
                  .fontSize(11).fontColor(this._textColor)
                  .layoutWeight(1).maxLines(3)
              }
              .padding({ left: 12, top: 3, bottom: 1 })
            }
            if (s.comment.length > 0) {
              Row() {
                Text('意见:')
                  .fontSize(11).fontColor(this._secondaryColor)
                  .width(60)
                Text(s.comment)
                  .fontSize(11).fontColor(this._textColor)
                  .layoutWeight(1).maxLines(3)
              }
              .padding({ left: 12, top: 3, bottom: 1 })
            }

            // divider
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(this._getDividerColor())
              .margin({ top: 6, bottom: 2 })

            // ── 会签详情 ──
            if (s.multiInstance !== null) {
              let mi: MultiInstanceStatus = s.multiInstance;
              Row() {
                Text((this._multiExpanded ? '▼ ' : '▶ ') +
                  '会签详情 (' + mi.completedCount + '/' + mi.totalCount + ')')
                  .fontSize(12).fontColor(this._secondaryColor)
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                Text('')
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
    .border({ width: 1, color: this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#555' : '#D0D0D0' })
    .borderRadius(8)
  }
}
