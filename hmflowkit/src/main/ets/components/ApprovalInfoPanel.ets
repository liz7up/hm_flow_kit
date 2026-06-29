// hmflowkit/src/main/ets/components/ApprovalInfoPanel.ets

import { NodeStatus, NodeStatusMap, MultiInstanceStatus,
  ApprovalOverlayConfig } from '../approval/ApprovalTypes';
import { GraphModel, GraphNode, NodeType } from '../model/GraphModel';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

@Component
export struct ApprovalInfoPanel {
  @Prop model: GraphModel = GraphModel.createEmpty();
  @Prop nodeStatuses: NodeStatusMap = new NodeStatusMap();
  @Prop @Watch('onSelectionChange') selectedNodeId: string = '';
  @Prop visible: boolean = false;
  @Prop canvasHeight: number = 600;
  @Prop approvalConfig: ApprovalOverlayConfig = new ApprovalOverlayConfig();
  @StorageProp('currentColorMode') currentColorMode: number = 0;
  onClose?: () => void;

  @State _multiExpanded: boolean = true;
  @State _cachedNodeType: string = '';
  @State _cachedNodeLabel: string = '';
  @State _cachedOperator: string = '';
  @State _cachedTimestamp: number = 0;
  @State _cachedResult: string = '';
  @State _cachedComment: string = '';
  @State _cachedHasData: boolean = false;
  @State _cachedMultiInstance: MultiInstanceStatus | null = null;
  @State _cachedChildList: NodeStatus[] = [];

  onSelectionChange(): void {
    this._refreshCache();
  }

  aboutToAppear(): void {
    this._refreshCache();
  }

  private _refreshCache(): void {
    if (this.selectedNodeId.length === 0) {
      this._cachedNodeType = '';
      this._cachedNodeLabel = '';
      this._cachedOperator = '';
      this._cachedTimestamp = 0;
      this._cachedResult = '';
      this._cachedComment = '';
      this._cachedHasData = false;
      this._cachedMultiInstance = null;
      this._cachedChildList = [];
      return;
    }
    let node: GraphNode | null = this.model.getNode(this.selectedNodeId);
    if (node != null) {
      this._cachedNodeType = node.type;
      this._cachedNodeLabel = node.label;
    } else {
      this._cachedNodeType = '';
      this._cachedNodeLabel = '';
    }
    let status: NodeStatus | null = this.nodeStatuses.get(this.selectedNodeId);
    if (status != null) {
      this._cachedOperator = status.operator;
      this._cachedTimestamp = status.timestamp;
      this._cachedResult = status.result;
      this._cachedComment = status.comment;
      this._cachedHasData = status.operator.length > 0 ||
        status.result.length > 0 || status.timestamp > 0;
      this._cachedMultiInstance = status.multiInstance;
      if (status.multiInstance != null) {
        this._cachedChildList = status.multiInstance.children;
      } else {
        this._cachedChildList = [];
      }
    } else {
      this._cachedOperator = '';
      this._cachedTimestamp = 0;
      this._cachedResult = '';
      this._cachedComment = '';
      this._cachedHasData = false;
      this._cachedMultiInstance = null;
      this._cachedChildList = [];
    }
  }

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

  private _buildCopyText(): string {
    let lines: string[] = [];
    if (this._cachedNodeType.length > 0) {
      lines.push('类型: ' + this._cachedNodeType);
    }
    if (this._cachedNodeLabel.length > 0) {
      lines.push('名称: ' + this._cachedNodeLabel);
    }
    if (this._cachedHasData) {
      if (this._cachedOperator.length > 0) {
        lines.push('审批人: ' + this._cachedOperator);
      }
      if (this._cachedTimestamp > 0) {
        lines.push('时间: ' + this._formatTime(this._cachedTimestamp));
      }
      if (this._cachedResult.length > 0) {
        lines.push('结果: ' + this._cachedResult);
      }
      if (this._cachedComment.length > 0) {
        lines.push('意见: ' + this._cachedComment);
      }
      if (this._cachedMultiInstance != null) {
        lines.push('会签 (' + this._cachedMultiInstance.completedCount +
          '/' + this._cachedMultiInstance.totalCount + '):');
        for (let i: number = 0; i < this._cachedChildList.length; i++) {
          let child: NodeStatus = this._cachedChildList[i];
          let childLine: string = '  ' + this._statusIcon(child.status) + ' ' +
            (child.operator.length > 0 ? child.operator : '—') + ' ' + child.result;
          if (child.timestamp > 0) {
            childLine = childLine + ' ' + this._formatTime(child.timestamp);
          }
          lines.push(childLine);
        }
      }
    }
    return lines.join('\n');
  }

  private _copyToClipboard(): void {
    let text: string = this._buildCopyText();
    if (text.length === 0) {
      return;
    }
    try {
      let pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      let sysPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      sysPasteboard.setData(pasteData);
    } catch (_e) {
      // clipboard unavailable, silent fail
    }
  }

  build() {
    Column() {
      if (this.visible && this.selectedNodeId.length > 0) {
        Column() {
          Row() {
            Text('节点详情')
              .fontSize(14).fontColor(this._textColor).fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Button() {
              Text('📋')
                .fontSize(14)
            }
            .width(28).height(28).backgroundColor('#00000000')
            .onClick(() => { this._copyToClipboard(); })
          }
          .width('100%').padding({ left: 12, right: 8, top: 8, bottom: 4 })

          Scroll() {
            Column() {
              if (this._cachedNodeType.length > 0) {
                Row() {
                  Text('类型:')
                    .fontSize(11).fontColor(this._secondaryColor).width(60)
                  Text(this._cachedNodeType)
                    .fontSize(11).fontColor(this._textColor)
                    .layoutWeight(1).maxLines(3)
                }
                .padding({ left: 12, top: 3, bottom: 1 })

                if (this._cachedNodeLabel.length > 0) {
                  Row() {
                    Text('名称:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(this._cachedNodeLabel)
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

              // 审批信息
              if (this._cachedHasData) {
                if (this._cachedOperator.length > 0) {
                  Row() {
                    Text('审批人:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(this._cachedOperator)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }
                if (this._cachedTimestamp > 0) {
                  Row() {
                    Text('时间:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(this._formatTime(this._cachedTimestamp))
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }
                if (this._cachedResult.length > 0) {
                  Row() {
                    Text('结果:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(this._cachedResult)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }
                if (this._cachedComment.length > 0) {
                  Row() {
                    Text('意见:')
                      .fontSize(11).fontColor(this._secondaryColor).width(60)
                    Text(this._cachedComment)
                      .fontSize(11).fontColor(this._textColor)
                      .layoutWeight(1).maxLines(3)
                  }
                  .padding({ left: 12, top: 3, bottom: 1 })
                }

                Row()
                  .width('100%').height(1)
                  .backgroundColor(this._getDividerColor())
                  .margin({ top: 6, bottom: 2 })

                // 会签详情
                if (this._cachedMultiInstance != null) {
                  Row() {
                    Text((this._multiExpanded ? '▼ ' : '▶ ') +
                      '会签详情 (' + this._cachedMultiInstance.completedCount +
                      '/' + this._cachedMultiInstance.totalCount + ')')
                      .fontSize(12).fontColor(this._secondaryColor)
                      .fontWeight(FontWeight.Bold)
                      .layoutWeight(1)
                  }
                  .width('100%').padding({ left: 8, right: 8, top: 6, bottom: 2 })
                  .onClick(() => { this._multiExpanded = !this._multiExpanded; })

                  if (this._multiExpanded) {
                    ForEach(this._cachedChildList, (child: NodeStatus, idx: number) => {
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
        .width(this.approvalConfig.popupWidth)
        .height(this.approvalConfig.popupHeight)
        .backgroundColor(this._bgColor)
        .border({ width: 1, color: this._getDividerColor() })
        .borderRadius(8)
        .shadow({ radius: 8, color: '#00000030', offsetY: 4 })
      }
    }
  }
}
