// hmflowkit/src/main/ets/debug/DebugTypes.ets

import { Waypoint, EdgeStyle } from '../model/GraphModel'

export enum SourceFormat { BPMN = 'bpmn', DRAWIO = 'drawio', DIRECT = 'direct' }

export class ElementStats {
  nodesByType: Record<string, number> = {}
  edgeCount: number = 0
  poolCount: number = 0
  laneCount: number = 0
  totalNodes: number = 0
}

export class NodeDetail {
  id: string = ''
  type: string = ''
  label: string = ''
  x: number = 0
  y: number = 0
  width: number = 0
  height: number = 0
  properties: Record<string, string> = {}
  poolId: string = ''
  laneId: string = ''
  layerPriority: number = 0
}

export class Point { x: number = 0; y: number = 0 }

export class EdgeDetail {
  id: string = ''
  sourceId: string = ''
  targetId: string = ''
  waypoints: Waypoint[] = []
  style: EdgeStyle = EdgeStyle.POLYLINE
  label: string = ''
  properties: Record<string, string> = {}
  sourcePos: Point = new Point()
  targetPos: Point = new Point()
}

export class ParseDiff {
  xmlTypes: Record<string, number> = {}
  renderTypes: Record<string, number> = {}
  missing: string[] = []
  discarded: string[] = []
}

export class Geometry {
  x: number = 0
  y: number = 0
  width: number = 0
  height: number = 0
  poolId: string = ''
  laneId: string = ''
}

export class ViewportInfo {
  zoom: number = 1
  offsetX: number = 0
  offsetY: number = 0
  rotation: number = 0
  canvasWidth: number = 0
  canvasHeight: number = 0
}

export class IdMapping {
  xmlId: string = ''
  renderedNodeId: string = ''
  type: string = ''
  matched: boolean = false
}

export class LayerInfo {
  nodeId: string = ''
  type: string = ''
  priority: number = 0
  label: string = ''
}

export class RenderStats {
  lastMs: number = 0
  avgMs: number = 0
  minMs: number = 0
  maxMs: number = 0
  frameCount: number = 0
}
