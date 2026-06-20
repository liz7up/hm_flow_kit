/**
 * HitTestManager — 坐标 → 元素命中检测
 *
 * 维护所有可交互元素的边界盒索引，根据屏幕坐标反查点击命中了哪个元素。
 * 纯数据操作，不依赖任何 UI 框架。
 *
 * 原理：
 *   屏幕坐标 → CanvasManager.screenToCanvas() → 画布坐标
 *   → 遍历节点边界盒 → 找到命中节点
 *   → 返回命中的元素 ID（节点优先，其次连线）
 *
 * 用法：
 *   const hitMgr = new HitTestManager()
 *   hitMgr.rebuild(model, canvasManager)   // 每次 model 更新后重建索引
 *   const hit = hitMgr.hitTest(clickX, clickY)  // 点击时查询
 */

import { GraphModel, GraphNode, GraphEdge, Pool, Lane } from '../model/GraphModel'
import { NodeRect } from './EdgeRenderer'
import { CanvasManager } from './CanvasManager'
import { RenderConfig } from './RenderConfig'

/**
 * 命中检测结果
 */
export class HitResult {
  /** 命中类型 */
  readonly type: HitType
  /** 命中的节点（仅当 type 为 NODE 时） */
  readonly nodeId: string
  /** 命中的连线（仅当 type 为 EDGE 时） */
  readonly edgeId: string
  /** 命中的 Pool（仅当 type 为 POOL 时） */
  readonly poolId: string
  /** 命中的 Lane（仅当 type 为 LANE 时） */
  readonly laneId: string
  /** 命中点在画布坐标系中的位置 */
  readonly canvasX: number
  readonly canvasY: number

  constructor(
    type: HitType,
    nodeId: string,
    edgeId: string,
    poolId: string,
    laneId: string,
    canvasX: number,
    canvasY: number
  ) {
    this.type = type
    this.nodeId = nodeId
    this.edgeId = edgeId
    this.poolId = poolId
    this.laneId = laneId
    this.canvasX = canvasX
    this.canvasY = canvasY
  }

  /** 是否命中任何元素 */
  get hasHit(): boolean {
    return this.type !== HitType.NONE
  }
}

/**
 * 命中类型
 */
export enum HitType {
  /** 未命中 */
  NONE = 0,
  /** 命中节点 */
  NODE = 1,
  /** 命中连线 */
  EDGE = 2,
  /** 命中画布背景 */
  CANVAS = 3,
  /** 命中泳池 (Pool) */
  POOL = 4,
  /** 命中泳道 (Lane) */
  LANE = 5
}

/**
 * 节点边界盒索引条目（画布坐标）
 */
class NodeHitBox {
  readonly id: string
  readonly left: number
  readonly top: number
  readonly right: number
  readonly bottom: number

  constructor(id: string, left: number, top: number, right: number, bottom: number) {
    this.id = id
    this.left = left
    this.top = top
    this.right = right
    this.bottom = bottom
  }

  contains(canvasX: number, canvasY: number): boolean {
    return canvasX >= this.left && canvasX <= this.right &&
           canvasY >= this.top && canvasY <= this.bottom
  }
}

/**
 * 连线包围盒索引条目（画布坐标）
 */
class EdgeHitBox {
  readonly id: string
  readonly sourceNodeId: string
  readonly targetNodeId: string
  /** 连线的所有折线点（画布坐标） */
  readonly waypoints: WaypointEntry[]
  /** 连线的总包围盒 */
  readonly minX: number
  readonly minY: number
  readonly maxX: number
  readonly maxY: number

  constructor(
    id: string,
    sourceNodeId: string,
    targetNodeId: string,
    waypoints: WaypointEntry[],
    minX: number,
    minY: number,
    maxX: number,
    maxY: number
  ) {
    this.id = id
    this.sourceNodeId = sourceNodeId
    this.targetNodeId = targetNodeId
    this.waypoints = waypoints
    this.minX = minX
    this.minY = minY
    this.maxX = maxX
    this.maxY = maxY
  }

  /** 粗判：点击是否在连线包围盒内（距离检测在 HitTestManager 中做） */
  containsRect(canvasX: number, canvasY: number): boolean {
    return canvasX >= this.minX && canvasX <= this.maxX &&
           canvasY >= this.minY && canvasY <= this.maxY
  }
}

/** 折线点 */
class WaypointEntry {
  x: number
  y: number

  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }
}

/** 泳池/泳道标题栏包围盒 */
class PoolLaneHitBox {
  readonly poolId: string
  readonly laneId: string
  readonly left: number
  readonly top: number
  readonly right: number
  readonly bottom: number

  constructor(poolId: string, laneId: string, left: number, top: number, right: number, bottom: number) {
    this.poolId = poolId
    this.laneId = laneId
    this.left = left
    this.top = top
    this.right = right
    this.bottom = bottom
  }

  contains(cx: number, cy: number): boolean {
    return cx >= this.left && cx <= this.right &&
           cy >= this.top && cy <= this.bottom
  }
}

/**
 * 命中检测管理器
 */
export class HitTestManager {
  /** 节点边界盒索引 */
  private nodeBoxes: NodeHitBox[]
  /** 连线包围盒索引 */
  private edgeBoxes: EdgeHitBox[]
  /** 泳池/泳道标题栏索引 */
  private poolHeaders: PoolLaneHitBox[]
  private laneHeaders: PoolLaneHitBox[]
  /** 连线的命中容忍距离（画布像素） */
  private edgeHitTolerance: number

  constructor() {
    this.nodeBoxes = []
    this.edgeBoxes = []
    this.poolHeaders = []
    this.laneHeaders = []
    this.edgeHitTolerance = 12
  }

  /**
   * 根据当前 Model 重建索引
   * 每次 model 数据变化后需要调用
   */
  rebuild(model: GraphModel, canvasManager: CanvasManager, config: RenderConfig = new RenderConfig()): void {
    this.edgeHitTolerance = config.edgeHitTolerance;
    const nodes: GraphNode[] = model.getNodes()
    const edges: GraphEdge[] = model.getEdges()
    const zoom: number = canvasManager.zoom

    // 重建节点索引
    this.nodeBoxes = []
    for (let i = 0; i < nodes.length; i++) {
      const n: GraphNode = nodes[i]
      // 节点在 model 中的坐标就是画布坐标，不需要转换
      // 但需要考虑缩放后的边界：命中检测用的节点尺寸不变（在画布坐标中）
      const box: NodeHitBox = new NodeHitBox(
        n.id,
        n.x,
        n.y,
        n.x + n.width,
        n.y + n.height
      )
      this.nodeBoxes.push(box)
    }

    // 重建连线索引
    this.edgeBoxes = []
    const modelNodes: GraphNode[] = model.getNodes()
    for (let j = 0; j < edges.length; j++) {
      const e: GraphEdge = edges[j]
      // 查找 source 和 target 节点获取端口坐标
      const srcNode: GraphNode | null = this.findNode(modelNodes, e.sourceId)
      const tgtNode: GraphNode | null = this.findNode(modelNodes, e.targetId)
      if (srcNode === null || tgtNode === null) {
        continue
      }

      // 构建折线点列表：源端口 → waypoints → 目标端口
      const wpList: WaypointEntry[] = []
      const srcCenterX: number = srcNode.x + srcNode.width / 2
      const srcCenterY: number = srcNode.y + srcNode.height / 2
      const tgtCenterX: number = tgtNode.x + tgtNode.width / 2
      const tgtCenterY: number = tgtNode.y + tgtNode.height / 2

      wpList.push(new WaypointEntry(srcCenterX, srcCenterY))

      const waypoints = e.waypoints
      for (let k = 0; k < waypoints.length; k++) {
        const wp = waypoints[k]
        wpList.push(new WaypointEntry(wp.x, wp.y))
      }

      wpList.push(new WaypointEntry(tgtCenterX, tgtCenterY))

      // 计算总包围盒
      let minX: number = Number.MAX_VALUE
      let minY: number = Number.MAX_VALUE
      let maxX: number = -Number.MAX_VALUE
      let maxY: number = -Number.MAX_VALUE
      for (let m = 0; m < wpList.length; m++) {
        const w: WaypointEntry = wpList[m]
        if (w.x < minX) {
          minX = w.x
        }
        if (w.y < minY) {
          minY = w.y
        }
        if (w.x > maxX) {
          maxX = w.x
        }
        if (w.y > maxY) {
          maxY = w.y
        }
      }

      const eb: EdgeHitBox = new EdgeHitBox(
        e.id,
        e.sourceId,
        e.targetId,
        wpList,
        minX,
        minY,
        maxX,
        maxY
      )
      this.edgeBoxes.push(eb)
    }

    // 重建泳道/泳池标题栏索引
    this.poolHeaders = []
    this.laneHeaders = []
    let pools: Pool[] = model.getPools()
    for (let pi: number = 0; pi < pools.length; pi++) {
      let pool: Pool = pools[pi]
      this.addPoolHeader(pool, config)
      this.addLaneHeaders(pool.lanes, pool.isHorizontal, config)
    }
  }

  private addPoolHeader(pool: Pool, config: RenderConfig): void {
    let headerW: number = config.poolHeaderWidth
    let hb: PoolLaneHitBox
    if (pool.isHorizontal) {
      hb = new PoolLaneHitBox(pool.id, '',
        pool.bounds.x, pool.bounds.y,
        pool.bounds.x + headerW, pool.bounds.y + pool.bounds.height)
    } else {
      hb = new PoolLaneHitBox(pool.id, '',
        pool.bounds.x, pool.bounds.y,
        pool.bounds.x + pool.bounds.width, pool.bounds.y + headerW)
    }
    this.poolHeaders.push(hb)
  }

  private addLaneHeaders(lanes: Lane[], isHorizontal: boolean, config: RenderConfig): void {
    for (let i: number = 0; i < lanes.length; i++) {
      let lane: Lane = lanes[i]
      let headerW: number = config.laneHeaderWidth
      let indent: number = config.laneHeaderIndent
      let hb: PoolLaneHitBox
      if (isHorizontal) {
        hb = new PoolLaneHitBox('', lane.id,
          lane.bounds.x + indent, lane.bounds.y,
          lane.bounds.x + indent + headerW, lane.bounds.y + lane.bounds.height)
      } else {
        hb = new PoolLaneHitBox('', lane.id,
          lane.bounds.x, lane.bounds.y,
          lane.bounds.x + lane.bounds.width, lane.bounds.y + headerW)
      }
      this.laneHeaders.push(hb)
      this.addLaneHeaders(lane.childLanes, isHorizontal, config)
    }
  }

  /**
   * 命中检测主入口
   * @param screenX 屏幕 X 坐标（来自手势事件）
   * @param screenY 屏幕 Y 坐标（来自手势事件）
   * @param canvasManager 用于屏幕→画布坐标转换
   * @returns 命中结果
   */
  hitTest(screenX: number, screenY: number, canvasManager: CanvasManager): HitResult {
    // 屏幕坐标 → 画布坐标
    const canvasPos = canvasManager.screenToCanvas(screenX, screenY)
    const cx: number = canvasPos.x
    const cy: number = canvasPos.y

    // 优先级：节点 > 连线 > 画布背景
    // 如果多个节点重叠，后构建的（通常在最上层）优先

    // 1. 检查节点命中（倒序遍历，顶层优先）
    for (let i = this.nodeBoxes.length - 1; i >= 0; i--) {
      const box: NodeHitBox = this.nodeBoxes[i]
      if (box.contains(cx, cy)) {
        return new HitResult(HitType.NODE, box.id, '', '', '', cx, cy)
      }
    }

    // 2. 检查连线命中（距离检测）
    for (let j = this.edgeBoxes.length - 1; j >= 0; j--) {
      const eb: EdgeHitBox = this.edgeBoxes[j]
      // 先用包围盒粗筛
      if (!eb.containsRect(cx, cy)) {
        continue
      }
      // 精确距离检测：计算点击点到每条线段的距离
      if (this.hitTestEdgeSegments(eb, cx, cy)) {
        return new HitResult(HitType.EDGE, '', eb.id, '', '', cx, cy)
      }
    }

    // 3. 检查泳池标题栏命中
    for (let pk = this.poolHeaders.length - 1; pk >= 0; pk--) {
      let ph: PoolLaneHitBox = this.poolHeaders[pk]
      if (ph.contains(cx, cy)) {
        return new HitResult(HitType.POOL, '', '', ph.poolId, '', cx, cy)
      }
    }

    // 4. 检查泳道标题栏命中
    for (let lk = this.laneHeaders.length - 1; lk >= 0; lk--) {
      let lh: PoolLaneHitBox = this.laneHeaders[lk]
      if (lh.contains(cx, cy)) {
        return new HitResult(HitType.LANE, '', '', '', lh.laneId, cx, cy)
      }
    }

    // 5. 未命中任何元素
    return new HitResult(HitType.CANVAS, '', '', '', '', cx, cy)
  }

  /**
   * 获取节点在画布坐标中的边界盒
   */
  getNodeRect(nodeId: string): NodeRect | null {
    for (let i = 0; i < this.nodeBoxes.length; i++) {
      const box: NodeHitBox = this.nodeBoxes[i]
      if (box.id === nodeId) {
        return new NodeRect(box.left, box.top, box.right - box.left, box.bottom - box.top)
      }
    }
    return null
  }

  /**
   * 获取连线的折线点列表（画布坐标）
   */
  getEdgeWaypoints(edgeId: string): WaypointEntry[] {
    for (let i = 0; i < this.edgeBoxes.length; i++) {
      const eb: EdgeHitBox = this.edgeBoxes[i]
      if (eb.id === edgeId) {
        return eb.waypoints
      }
    }
    return []
  }

  /** 清空所有索引 */
  clear(): void {
    this.nodeBoxes = []
    this.edgeBoxes = []
    this.poolHeaders = []
    this.laneHeaders = []
  }

  // ========== 私有方法 ==========

  /** 在节点列表中按 ID 查找 */
  private findNode(nodes: GraphNode[], id: string): GraphNode | null {
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].id === id) {
        return nodes[i]
      }
    }
    return null
  }

  /** 精确检测：点到连线段段的距离是否在容忍范围内 */
  private hitTestEdgeSegments(edgeBox: EdgeHitBox, cx: number, cy: number): boolean {
    const wpList: WaypointEntry[] = edgeBox.waypoints
    if (wpList.length < 2) {
      return false
    }

    for (let i = 1; i < wpList.length; i++) {
      const a: WaypointEntry = wpList[i - 1]
      const b: WaypointEntry = wpList[i]
      const dist: number = this.pointToSegmentDistance(cx, cy, a.x, a.y, b.x, b.y)
      if (dist <= this.edgeHitTolerance) {
        return true
      }
    }
    return false
  }

  /** 点到线段的最短距离 */
  private pointToSegmentDistance(
    px: number, py: number,
    ax: number, ay: number,
    bx: number, by: number
  ): number {
    const dx: number = bx - ax
    const dy: number = by - ay
    const lenSquared: number = dx * dx + dy * dy

    // 线段退化为点
    if (lenSquared < 0.0001) {
      const dpx: number = px - ax
      const dpy: number = py - ay
      return Math.sqrt(dpx * dpx + dpy * dpy)
    }

    // 投影参数 t，截断到 [0, 1]
    let t: number = ((px - ax) * dx + (py - ay) * dy) / lenSquared
    if (t < 0) {
      t = 0
    }
    if (t > 1) {
      t = 1
    }

    const projX: number = ax + t * dx
    const projY: number = ay + t * dy
    const pdx: number = px - projX
    const pdy: number = py - projY
    return Math.sqrt(pdx * pdx + pdy * pdy)
  }
}