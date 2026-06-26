// hmflowkit/src/main/ets/debug/DebugCollector.ets

import { GraphModel, GraphNode, GraphEdge, Pool, Lane } from '../model/GraphModel'
import { CanvasManager } from '../renderer/CanvasManager'
import { RenderConfig } from '../renderer/RenderConfig'
import { ParseMeta } from '../parser/BpmnXmlParser'
import { DrawioParseMeta } from '../parser/DrawioXmlParser'
import {
  SourceFormat, ElementStats, NodeDetail, EdgeDetail, Point,
  ParseDiff, Geometry, ViewportInfo, IdMapping, LayerInfo, RenderStats
} from './DebugTypes'

export class DebugCollector {
  private _model: GraphModel
  private _canvasManager: CanvasManager
  private _renderConfig: RenderConfig
  private _parseMeta: ParseMeta | null = null
  private _drawioMeta: DrawioParseMeta | null = null
  private _parseWarnings: string[] = []
  private _isPartial: boolean = false
  private _times: number[] = new Array(60).fill(0)
  private _timeIdx: number = 0
  private _frameCount: number = 0

  constructor(model: GraphModel, canvasManager: CanvasManager, renderConfig: RenderConfig,
              parseMeta?: ParseMeta, drawioMeta?: DrawioParseMeta,
              warnings?: string[], isPartial?: boolean) {
    this._model = model
    this._canvasManager = canvasManager
    this._renderConfig = renderConfig
    if (parseMeta !== undefined) { this._parseMeta = parseMeta }
    if (drawioMeta !== undefined) { this._drawioMeta = drawioMeta }
    if (warnings !== undefined) { this._parseWarnings = warnings }
    if (isPartial !== undefined) { this._isPartial = isPartial }
  }

  getStatistics(): ElementStats {
    let stats: ElementStats = new ElementStats()
    let nodes: GraphNode[] = this._model.getNodes()
    stats.totalNodes = nodes.length
    for (let i: number = 0; i < nodes.length; i++) {
      let t: string = nodes[i].type as string
      let count: number | undefined = stats.nodesByType[t]
      stats.nodesByType[t] = (count !== undefined ? count : 0) + 1
    }
    stats.edgeCount = this._model.getEdgeCount()
    let pools: Pool[] = this._model.getPools()
    stats.poolCount = pools.length
    let laneCount: number = 0
    for (let i: number = 0; i < pools.length; i++) {
      laneCount += pools[i].lanes.length
    }
    stats.laneCount = laneCount
    return stats
  }

  getNodeDetail(id: string): NodeDetail | null {
    let node: GraphNode | null = this._model.getNode(id)
    if (node === null) { return null }
    let detail: NodeDetail = new NodeDetail()
    detail.id = node.id
    detail.type = node.type as string
    detail.label = node.label
    detail.x = node.x
    detail.y = node.y
    detail.width = node.width
    detail.height = node.height
    let keys: string[] = Object.keys(node.properties)
    for (let i: number = 0; i < keys.length; i++) {
      detail.properties[keys[i]] = node.properties[keys[i]]
    }
    let lane: Lane | null = this._model.getLaneByNode(id)
    if (lane !== null) {
      detail.laneId = lane.id
      detail.poolId = this._findPoolForLane(lane.id)
    }
    let pri: number | undefined = this._renderConfig.layerPriorities[node.type as string]
    detail.layerPriority = pri !== undefined ? pri : this._renderConfig.defaultLayerPriority
    return detail
  }

  getEdgeDetail(id: string): EdgeDetail | null {
    let edge: GraphEdge | null = this._model.getEdge(id)
    if (edge === null) { return null }
    let detail: EdgeDetail = new EdgeDetail()
    detail.id = edge.id
    detail.sourceId = edge.sourceId
    detail.targetId = edge.targetId
    detail.waypoints = edge.waypoints
    detail.style = edge.style
    detail.label = edge.label
    let keys: string[] = Object.keys(edge.properties)
    for (let i: number = 0; i < keys.length; i++) {
      detail.properties[keys[i]] = edge.properties[keys[i]]
    }
    let srcNode: GraphNode | null = this._model.getNode(edge.sourceId)
    if (srcNode !== null) {
      detail.sourcePos.x = srcNode.x + srcNode.width / 2
      detail.sourcePos.y = srcNode.y + srcNode.height / 2
    }
    let tgtNode: GraphNode | null = this._model.getNode(edge.targetId)
    if (tgtNode !== null) {
      detail.targetPos.x = tgtNode.x + tgtNode.width / 2
      detail.targetPos.y = tgtNode.y + tgtNode.height / 2
    }
    return detail
  }

  getNodeGeometry(id: string): Geometry | null {
    let node: GraphNode | null = this._model.getNode(id)
    if (node === null) { return null }
    let geo: Geometry = new Geometry()
    geo.x = node.x
    geo.y = node.y
    geo.width = node.width
    geo.height = node.height
    let lane: Lane | null = this._model.getLaneByNode(id)
    if (lane !== null) {
      geo.laneId = lane.id
      geo.poolId = this._findPoolForLane(lane.id)
    }
    return geo
  }

  getLayerInfo(): LayerInfo[] {
    let nodes: GraphNode[] = this._model.getNodes()
    let result: LayerInfo[] = []
    let max: number = 200
    for (let i: number = 0; i < nodes.length && result.length < max; i++) {
      let n: GraphNode = nodes[i]
      let info: LayerInfo = new LayerInfo()
      info.nodeId = n.id
      info.type = n.type as string
      info.label = n.label
      let pri: number | undefined = this._renderConfig.layerPriorities[n.type as string]
      info.priority = pri !== undefined ? pri : this._renderConfig.defaultLayerPriority
      result.push(info)
    }
    return result
  }

  getViewportState(): ViewportInfo {
    let info: ViewportInfo = new ViewportInfo()
    info.zoom = this._canvasManager.zoom
    info.offsetX = this._canvasManager.offsetX
    info.offsetY = this._canvasManager.offsetY
    info.rotation = this._canvasManager.rotationTurns * 90
    info.canvasWidth = this._canvasManager.canvasWidth
    info.canvasHeight = this._canvasManager.canvasHeight
    return info
  }

  private _findPoolForLane(laneId: string): string {
    let pools: Pool[] = this._model.getPools()
    for (let i: number = 0; i < pools.length; i++) {
      let pool: Pool = pools[i]
      for (let j: number = 0; j < pool.lanes.length; j++) {
        if (this._laneOrChildHasId(pool.lanes[j], laneId)) {
          return pool.id
        }
      }
    }
    return ''
  }

  private _laneOrChildHasId(lane: Lane, id: string): boolean {
    if (lane.id === id) { return true }
    for (let i: number = 0; i < lane.childLanes.length; i++) {
      if (this._laneOrChildHasId(lane.childLanes[i], id)) { return true }
    }
    return false
  }

  getParseDiff(): ParseDiff | null {
    if (this._parseMeta === null) { return null }
    let diff: ParseDiff = new ParseDiff()
    let meta: ParseMeta = this._parseMeta!

    // xmlTypes from semanticTypes
    let semKeys: string[] = Object.keys(meta.semanticTypes)
    for (let i: number = 0; i < semKeys.length; i++) {
      let tagName: string = meta.semanticTypes[semKeys[i]]
      let count: number | undefined = diff.xmlTypes[tagName]
      diff.xmlTypes[tagName] = (count !== undefined ? count : 0) + 1
    }

    // renderTypes from model
    let stats: ElementStats = this.getStatistics()
    diff.renderTypes = stats.nodesByType

    // Find missing: XML IDs that have no rendered node
    for (let i: number = 0; i < meta.semanticIds.length; i++) {
      let xmlId: string = meta.semanticIds[i]
      if (!this._model.hasNode(xmlId)) {
        diff.missing.push(xmlId)
      }
    }

    // discarded from meta tracking
    let discKeys: string[] = Object.keys(meta.discardedElementTypes)
    for (let i: number = 0; i < discKeys.length; i++) {
      let k: string = discKeys[i]
      let cnt: number | undefined = meta.discardedElementTypes[k]
      diff.discarded.push(k + ' x' + (cnt !== undefined ? cnt : 0))
    }
    return diff
  }

  getIdMapping(): IdMapping[] {
    let result: IdMapping[] = []
    if (this._parseMeta === null) { return result }
    let meta: ParseMeta = this._parseMeta!
    let max: number = 200
    for (let i: number = 0; i < meta.semanticIds.length && result.length < max; i++) {
      let xmlId: string = meta.semanticIds[i]
      let mapping: IdMapping = new IdMapping()
      mapping.xmlId = xmlId
      mapping.type = meta.semanticTypes[xmlId] !== undefined ? meta.semanticTypes[xmlId] : ''
      mapping.matched = this._model.hasNode(xmlId)
      mapping.renderedNodeId = mapping.matched ? xmlId : ''
      result.push(mapping)
    }
    return result
  }

  getParseWarnings(): string[] {
    return this._parseWarnings
  }

  getIsPartial(): boolean {
    return this._isPartial
  }

  recordRenderTime(ms: number): void {
    this._times[this._timeIdx % 60] = ms
    this._timeIdx++
    this._frameCount++
  }

  getRenderStats(): RenderStats {
    let stats: RenderStats = new RenderStats()
    stats.frameCount = this._frameCount
    if (this._frameCount === 0) { return stats }
    let count: number = this._frameCount < 60 ? this._frameCount : 60
    let start: number = this._frameCount < 60 ? 0 : (this._timeIdx % 60)
    let sum: number = 0
    stats.minMs = 999999
    stats.maxMs = 0
    for (let i: number = 0; i < count; i++) {
      let t: number = this._times[(start + i) % 60]
      sum += t
      if (t < stats.minMs) { stats.minMs = t }
      if (t > stats.maxMs) { stats.maxMs = t }
    }
    stats.avgMs = Math.round(sum / count)
    stats.lastMs = this._times[(this._timeIdx - 1 + 60) % 60]
    return stats
  }

  getSourceFormat(): SourceFormat {
    if (this._drawioMeta !== null) { return SourceFormat.DRAWIO }
    if (this._parseMeta !== null) { return SourceFormat.BPMN }
    return SourceFormat.DIRECT
  }

  updateModel(model: GraphModel): void {
    this._model = model
  }

  updateParseMeta(meta: ParseMeta, warnings: string[], isPartial: boolean): void {
    this._parseMeta = meta
    this._parseWarnings = warnings
    this._isPartial = isPartial
  }

  updateRenderConfig(config: RenderConfig): void {
    this._renderConfig = config
  }
}
