/**
 * DebugSidebar -- Debug information panel for FlowViewer.
 *
 * 7 collapsible sections:
 *   1. Render statistics (nodes/edges/pools/lanes by type)
 *   2. Selected element detail (type, coords, pool/lane, properties)
 *   3. XML -> rendering diff analysis
 *   4. ID mapping table (XML ID -> rendered node ID)
 *   5. Layer Z-order info
 *   6. Viewport state + render timing
 *   7. Parse warnings (only when present)
 */
import { DebugCollector } from '../debug/DebugCollector'
import { NodeDetail, ElementStats, ParseDiff, IdMapping, LayerInfo,
  ViewportInfo, RenderStats } from '../debug/DebugTypes'
import { ConfigurationConstant } from '@kit.AbilityKit'

@Component
export struct DebugSidebar {
  @Prop collector: DebugCollector
  @Prop selectedNodeId: string = ''
  @Prop selectedEdgeId: string = ''
  @Prop visible: boolean = true
  @Prop canvasHeight: number = 600
  @Prop currentColorMode: number = 0
  onClose?: () => void

  @State private _statsExpanded: boolean = true
  @State private _detailExpanded: boolean = true
  @State private _diffExpanded: boolean = true
  @State private _idMapExpanded: boolean = false
  @State private _layerExpanded: boolean = false
  @State private _viewportExpanded: boolean = true
  @State private _warnExpanded: boolean = true
  @State private _copyFeedback: string = ''

  // ── Dark mode color helpers ──

  private get _bgColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#333333' : '#E8E8E8'
  }

  private get _textColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#DDD' : '#333'
  }

  private get _secondaryColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#AAA' : '#555'
  }

  private get _borderColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#555' : '#D0D0D0'
  }

  private get _sectionBorderColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#444' : '#E0E0E0'
  }

  private get _placeholderColor(): string {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? '#777' : '#999'
  }

  build() {
    Column() {
      if (this.visible) {
        // Title bar
        Row() {
          Text('调试信息')
            .fontSize(14)
            .fontColor(this._textColor)
            .layoutWeight(1)
          Button() {
            Text('X')
              .fontSize(14)
              .fontColor(this._textColor)
          }
          .width(28).height(28)
          .backgroundColor('#00000000')
          .onClick(() => {
            if (this.onClose) {
              this.onClose()
            }
          })
        }
        .width('100%')
        .padding({ left: 12, right: 8, top: 8, bottom: 4 })

        // Scrollable content
        Scroll() {
          Column() {
            // ── Section 1: 渲染统计 ──
            Column() {
              this.sectionHeader('渲染统计 (' + this._getStatsCountsLabel() + ')', this._statsExpanded,
                () => { this._statsExpanded = !this._statsExpanded })
              if (this._statsExpanded) {
                Column() {
                  Text(this._getStatsSummary())
                    .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 2 })
                    .copyOption(CopyOptions.LocalDevice)
                  ForEach(this._getStatsTypeKeys(), (type: string) => {
                    Text('  ' + type + ': ' + this._getStatsCountForType(type))
                      .fontSize(11).fontColor(this._secondaryColor).padding({ left: 20, top: 1 })
                      .copyOption(CopyOptions.LocalDevice)
                  }, (type: string) => type)
                }
                .padding({ bottom: 4 })
              }
            }
            .width('100%')
            .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })

            // ── Section 2: 选中元素详情 ──
            Column() {
              if (this.selectedNodeId.length === 0) {
                this.sectionHeader('选中元素详情', this._detailExpanded,
                  () => { this._detailExpanded = !this._detailExpanded })
              } else {
                this.sectionHeader('选中元素详情 (' + this.selectedNodeId + ')', this._detailExpanded,
                  () => { this._detailExpanded = !this._detailExpanded })
              }
              if (this._detailExpanded) {
                if (this.selectedNodeId.length === 0) {
                  Text('  点击画布中的节点查看详情')
                    .fontSize(11).fontColor(this._placeholderColor).fontStyle(FontStyle.Italic)
                    .padding({ left: 12, top: 4, bottom: 4 })
                    .copyOption(CopyOptions.LocalDevice)
                } else if (this._getNodeDetailOrNull() === null) {
                  Text('  元素已不存在')
                    .fontSize(11).fontColor('#E53935')
                    .padding({ left: 12, top: 4, bottom: 4 })
                    .copyOption(CopyOptions.LocalDevice)
                } else {
                  Column() {
                    Text('  类型: ' + this._getDetailType() + '    ID: ' + this._getDetailId())
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 2 })
                      .copyOption(CopyOptions.LocalDevice)
                    Text('  坐标: (' + this._getDetailX() + ', ' + this._getDetailY() +
                      ')   尺寸: ' + this._getDetailWidth() + ' x ' + this._getDetailHeight())
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 1 })
                      .copyOption(CopyOptions.LocalDevice)
                    if (this._getDetailPoolId().length > 0) {
                      Text('  Pool: ' + this._getDetailPoolId() + '    Lane: ' + this._getDetailLaneId())
                        .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 1 })
                        .copyOption(CopyOptions.LocalDevice)
                    }
                    Text('  层序: ' + this._getDetailLayer())
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 1 })
                      .copyOption(CopyOptions.LocalDevice)

                    Text('  properties:')
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 4 })
                      .copyOption(CopyOptions.LocalDevice)
                    ForEach(this._getDetailPropKeys(), (k: string) => {
                      Text('    ' + k + ': ' + this._getDetailPropValue(k))
                        .fontSize(11).fontColor(this._secondaryColor).padding({ left: 20, top: 1 })
                        .copyOption(CopyOptions.LocalDevice)
                    }, (k: string) => k)

                    Button('Copy JSON')
                      .fontSize(11)
                      .height(24)
                      .margin({ left: 12, top: 4, bottom: 4 })
                      .onClick(() => {
                        this._onCopyJson()
                      })
                    if (this._copyFeedback.length > 0) {
                      Text(this._copyFeedback)
                        .fontSize(10).fontColor(this._secondaryColor)
                        .padding({ left: 12, top: 2, bottom: 4 })
                    }
                  }
                }
              }
            }
            .width('100%')
            .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })

            // ── Section 3: XML -> 渲染差异 ──
            Column() {
              this.sectionHeader('XML -> 渲染差异' + this._getDiffHeaderSuffix(), this._diffExpanded,
                () => { this._diffExpanded = !this._diffExpanded })
              if (this._diffExpanded) {
                if (!this._hasDiff()) {
                  Text('  无 XML 数据，差异分析不可用')
                    .fontSize(11).fontColor(this._placeholderColor).fontStyle(FontStyle.Italic)
                    .padding({ left: 12, top: 4, bottom: 4 })
                    .copyOption(CopyOptions.LocalDevice)
                } else {
                  Column() {
                    Text('  XML 声明:')
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 2 })
                      .copyOption(CopyOptions.LocalDevice)
                    ForEach(this._getDiffXmlKeys(), (k: string) => {
                      Text('    ' + k + ': ' + this._getDiffXmlValue(k))
                        .fontSize(11).fontColor(this._secondaryColor).padding({ left: 20, top: 1 })
                        .copyOption(CopyOptions.LocalDevice)
                    }, (k: string) => k)
                    Text('  已渲染:')
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 4 })
                      .copyOption(CopyOptions.LocalDevice)
                    ForEach(this._getDiffRenderKeys(), (k: string) => {
                      Text('    ' + k + ': ' + this._getDiffRenderValue(k))
                        .fontSize(11).fontColor(this._secondaryColor).padding({ left: 20, top: 1 })
                        .copyOption(CopyOptions.LocalDevice)
                    }, (k: string) => k)
                    if (this._hasMissing()) {
                      Text(this._getMissingText())
                        .fontSize(11).fontColor('#E53935').padding({ left: 12, top: 4 })
                        .copyOption(CopyOptions.LocalDevice)
                    }
                    if (this._hasDiscarded()) {
                      Text(this._getDiscardedText())
                        .fontSize(11).fontColor('#F57C00').padding({ left: 12, top: 1 })
                        .copyOption(CopyOptions.LocalDevice)
                    }
                  }
                  .padding({ bottom: 4 })
                }
              }
            }
            .width('100%')
            .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })

            // ── Section 4: ID 映射表 ──
            Column() {
              this.sectionHeader('ID 映射表 (' + this._getMappingCount() + ')', this._idMapExpanded,
                () => { this._idMapExpanded = !this._idMapExpanded })
              if (this._idMapExpanded) {
                if (this._getMappingCount() === 0) {
                  Text('  无 XML 数据')
                    .fontSize(11).fontColor(this._placeholderColor).fontStyle(FontStyle.Italic)
                    .padding({ left: 12, top: 4, bottom: 4 })
                    .copyOption(CopyOptions.LocalDevice)
                } else {
                  Column() {
                    ForEach(this._getMappings(), (m: IdMapping) => {
                      Text(this._getMappingText(m))
                        .fontSize(10).fontColor(this._getMappingColor(m))
                        .padding({ left: 12, top: 1 })
                        .copyOption(CopyOptions.LocalDevice)
                    }, (m: IdMapping, idx?: number) => m.xmlId + '_' + (idx !== undefined ? idx : 0))
                    if (this._hasMoreMappings()) {
                      Text('  仅显示前 200 项')
                        .fontSize(10).fontColor(this._placeholderColor)
                        .padding({ left: 12, top: 4 })
                    }
                  }
                  .padding({ bottom: 4 })
                }
              }
            }
            .width('100%')
            .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })

            // ── Section 5: 层序 Z-order ──
            Column() {
              this.sectionHeader('层序 Z-order (' + this.collector.getLayerInfo().length + ')', this._layerExpanded,
                () => { this._layerExpanded = !this._layerExpanded })
              if (this._layerExpanded) {
                Column() {
                  ForEach(this._getLayers(), (l: LayerInfo) => {
                    Text('  [' + l.priority + '] ' + l.nodeId + ' (' + l.type + ') ' + l.label)
                      .fontSize(10).fontColor(this._secondaryColor).padding({ left: 12, top: 1 })
                      .copyOption(CopyOptions.LocalDevice)
                  }, (l: LayerInfo, idx?: number) => l.nodeId + '_' + (idx !== undefined ? idx : 0))
                  if (this._hasMoreLayers()) {
                    Text('  仅显示前 200 项')
                      .fontSize(10).fontColor(this._placeholderColor)
                      .padding({ left: 12, top: 4 })
                  }
                }
                .padding({ bottom: 4 })
              }
            }
            .width('100%')
            .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })

            // ── Section 6: 视口状态 + 渲染耗时 ──
            Column() {
              this.sectionHeader('视口状态 + 渲染耗时', this._viewportExpanded,
                () => { this._viewportExpanded = !this._viewportExpanded })
              if (this._viewportExpanded) {
                Column() {
                  Text(this._getVpSummary())
                    .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 2 })
                    .copyOption(CopyOptions.LocalDevice)
                  Text(this._getVpRotationText())
                    .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 1 })
                    .copyOption(CopyOptions.LocalDevice)
                  if (this._hasRenderTime()) {
                    Text(this._getRenderTimeText())
                      .fontSize(11).fontColor(this._textColor).padding({ left: 12, top: 1 })
                      .copyOption(CopyOptions.LocalDevice)
                  }
                }
                .padding({ bottom: 4 })
              }
            }
            .width('100%')
            .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })

            // ── Section 7: 解析警告 ──
            if (this._getWarningCount() > 0) {
              Column() {
                Row() {
                  Text((this._warnExpanded ? '▼ ' : '▶ ') + '解析警告 (' +
                    this._getWarningCount() + ')')
                    .fontSize(12).fontColor('#F57C00').fontWeight(FontWeight.Bold)
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 8, right: 8, top: 6, bottom: 2 })
                .onClick(() => { this._warnExpanded = !this._warnExpanded })

                if (this._warnExpanded) {
                  ForEach(this._getWarnings(), (w: string, idx?: number) => {
                    Text('  \u26A0 ' + w)
                      .fontSize(10).fontColor('#F57C00')
                      .padding({ left: 12, top: 1 }).maxLines(2)
                      .copyOption(CopyOptions.LocalDevice)
                  }, (w: string, idx?: number) => w + '_' + (idx !== undefined ? idx : 0))
                }
              }
              .border({ width: { bottom: 0.5 }, color: this._sectionBorderColor })
            }
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width(300)
    .height(this.canvasHeight)
    .backgroundColor(this._bgColor)
    .border({ width: 1, color: this._borderColor })
  }

  // ── Builder: reusable collapsible section header ──

  @Builder
  sectionHeader(title: string, expanded: boolean, onToggle: () => void) {
    Row() {
      Text((expanded ? '▼ ' : '▶ ') + title)
        .fontSize(12)
        .fontColor(this._secondaryColor)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 2 })
    .onClick(onToggle)
  }

  // ── Copy JSON handler (C1) ──

  private _onCopyJson(): void {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    if (d === null) {
      this._copyFeedback = '无数据可复制'
      return
    }
    let lines: string[] = []
    lines.push('{')
    lines.push('  "id": "' + this._escapeJson(d.id) + '",')
    lines.push('  "type": "' + this._escapeJson(d.type) + '",')
    lines.push('  "label": "' + this._escapeJson(d.label) + '",')
    lines.push('  "x": ' + d.x + ',')
    lines.push('  "y": ' + d.y + ',')
    lines.push('  "width": ' + d.width + ',')
    lines.push('  "height": ' + d.height + ',')
    lines.push('  "poolId": "' + this._escapeJson(d.poolId) + '",')
    lines.push('  "laneId": "' + this._escapeJson(d.laneId) + '",')
    lines.push('  "layerPriority": ' + d.layerPriority + ',')
    lines.push('  "properties": {')
    let propKeys: string[] = Object.keys(d.properties)
    for (let i: number = 0; i < propKeys.length; i++) {
      let comma: string = i < propKeys.length - 1 ? ',' : ''
      lines.push('    "' + this._escapeJson(propKeys[i]) + '": "' +
        this._escapeJson(d.properties[propKeys[i]]) + '"' + comma)
    }
    lines.push('  }')
    lines.push('}')
    let json: string = lines.join('\n')
    console.info('[DebugSidebar] Node JSON:\n' + json)
    this._copyFeedback = 'JSON 已输出到控制台（SDK 不支持剪贴板）'
  }

  private _escapeJson(s: string): string {
    let result: string = ''
    for (let i: number = 0; i < s.length; i++) {
      let ch: string = s[i]
      if (ch === '"') { result += '\\"' }
      else if (ch === '\\') { result += '\\\\' }
      else if (ch === '\n') { result += '\\n' }
      else if (ch === '\r') { result += '\\r' }
      else if (ch === '\t') { result += '\\t' }
      else { result += ch }
    }
    return result
  }

  // ── Section header count labels (I6) ──

  private _getStatsCountsLabel(): string {
    let stats: ElementStats = this.collector.getStatistics()
    return stats.totalNodes + ' \u8282\u70B9, ' + stats.edgeCount + ' \u8FDE\u7EBF'  // "节点", "连线"
  }

  private _getDiffHeaderSuffix(): string {
    if (!this._hasDiff()) { return '' }
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null || diff.missing.length === 0) { return '' }
    return ' (\u7F3A\u5931 ' + diff.missing.length + ')'  // "缺失 N"
  }

  // ── Data helpers: 渲染统计 ──

  private _getStatsSummary(): string {
    let stats: ElementStats = this.collector.getStatistics()
    return '总节点: ' + stats.totalNodes + '  连线: ' + stats.edgeCount +
      '  泳池: ' + stats.poolCount + '  泳道: ' + stats.laneCount
  }

  private _getStatsTypeKeys(): string[] {
    let stats: ElementStats = this.collector.getStatistics()
    let keys: string[] = Object.keys(stats.nodesByType)
    if (keys.length > 30) {
      return keys.slice(0, 30)
    }
    return keys
  }

  private _getStatsCountForType(type: string): string {
    let stats: ElementStats = this.collector.getStatistics()
    let v: number | undefined = stats.nodesByType[type]
    return (v !== undefined ? v : 0).toString()
  }

  // ── Data helpers: 选中元素详情 ──

  private _getNodeDetailOrNull(): NodeDetail | null {
    if (this.selectedNodeId.length === 0) {
      return null
    }
    return this.collector.getNodeDetail(this.selectedNodeId)
  }

  private _getDetailType(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? d.type : ''
  }

  private _getDetailId(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? d.id : ''
  }

  private _getDetailX(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? Math.round(d.x).toString() : ''
  }

  private _getDetailY(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? Math.round(d.y).toString() : ''
  }

  private _getDetailWidth(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? Math.round(d.width).toString() : ''
  }

  private _getDetailHeight(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? Math.round(d.height).toString() : ''
  }

  private _getDetailPoolId(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? d.poolId : ''
  }

  private _getDetailLaneId(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? d.laneId : ''
  }

  private _getDetailLayer(): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    return d !== null ? d.layerPriority.toString() : ''
  }

  private _getDetailPropKeys(): string[] {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    if (d === null) {
      return []
    }
    return Object.keys(d.properties)
  }

  private _getDetailPropValue(key: string): string {
    let d: NodeDetail | null = this._getNodeDetailOrNull()
    if (d === null) {
      return ''
    }
    return d.properties[key]
  }

  // ── Data helpers: XML diff ──

  private _hasDiff(): boolean {
    return this.collector.getParseDiff() !== null
  }

  private _getDiffXmlKeys(): string[] {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return []
    }
    return Object.keys(diff.xmlTypes)
  }

  private _getDiffXmlValue(key: string): string {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return ''
    }
    let v: number | undefined = diff.xmlTypes[key]
    return (v !== undefined ? v : 0).toString()
  }

  private _getDiffRenderKeys(): string[] {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return []
    }
    return Object.keys(diff.renderTypes)
  }

  private _getDiffRenderValue(key: string): string {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return ''
    }
    let v: number | undefined = diff.renderTypes[key]
    return (v !== undefined ? v : 0).toString()
  }

  private _hasMissing(): boolean {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return false
    }
    return diff.missing.length > 0
  }

  private _getMissingText(): string {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return ''
    }
    return '  缺失: ' + diff.missing.length + ' (ID: ' + diff.missing.join(', ') + ')'
  }

  private _hasDiscarded(): boolean {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return false
    }
    return diff.discarded.length > 0
  }

  private _getDiscardedText(): string {
    let diff: ParseDiff | null = this.collector.getParseDiff()
    if (diff === null) {
      return ''
    }
    return '  丢弃: ' + diff.discarded.join(', ')
  }

  // ── Data helpers: ID mapping ──

  private _getMappingCount(): number {
    return this.collector.getIdMapping().length
  }

  private _getMappings(): IdMapping[] {
    let mappings: IdMapping[] = this.collector.getIdMapping()
    if (mappings.length > 200) {
      return mappings.slice(0, 200)
    }
    return mappings
  }

  private _hasMoreMappings(): boolean {
    return this.collector.getIdMapping().length > 200
  }

  private _getMappingText(m: IdMapping): string {
    let status: string = m.matched ? 'OK' : 'MISS'
    return '  ' + m.xmlId + ' -> ' + (m.matched ? m.renderedNodeId : '-') +
      ' (' + m.type + ') [' + status + ']'
  }

  private _getMappingColor(m: IdMapping): string {
    return m.matched ? '#333' : '#E53935'
  }

  // ── Data helpers: Layer ──

  private _getLayers(): LayerInfo[] {
    let layers: LayerInfo[] = this.collector.getLayerInfo()
    if (layers.length > 200) {
      return layers.slice(0, 200)
    }
    return layers
  }

  private _hasMoreLayers(): boolean {
    return this.collector.getLayerInfo().length > 200
  }

  // ── Data helpers: Viewport ──

  private _getVpSummary(): string {
    let vp: ViewportInfo = this.collector.getViewportState()
    return '  zoom: ' + vp.zoom.toFixed(2) + '  offset: (' +
      Math.round(vp.offsetX) + ', ' + Math.round(vp.offsetY) + ')'
  }

  private _getVpRotationText(): string {
    let vp: ViewportInfo = this.collector.getViewportState()
    return '  rotation: ' + vp.rotation + '\u00B0  canvas: ' +
      vp.canvasWidth + ' x ' + vp.canvasHeight
  }

  private _getRenderTimeText(): string {
    let stats: RenderStats = this.collector.getRenderStats()
    if (stats.frameCount === 0) {
      return ''
    }
    return '  renderAll: ' + stats.lastMs + 'ms (avg: ' + stats.avgMs +
      'ms, max: ' + stats.maxMs + 'ms, \u5E27\u6570: ' + stats.frameCount + ')'
  }

  private _hasRenderTime(): boolean {
    return this.collector.getRenderStats().frameCount > 0
  }

  // ── Data helpers: Warnings ──

  private _getWarningCount(): number {
    return this.collector.getParseWarnings().length
  }

  private _getWarnings(): string[] {
    let warnings: string[] = this.collector.getParseWarnings()
    if (warnings.length > 50) {
      return warnings.slice(0, 50)
    }
    return warnings
  }
}
