/**
 * GraphModel - Core data model for the graph editor.
 *
 * Immutable pattern: all mutation methods return a new GraphModel instance.
 * This is the single source of truth for the entire application.
 * No UI dependencies. No Canvas dependencies. Pure data.
 *
 * ArkTS Strict Mode compliant:
 * - No object literal type declarations (arkts-no-obj-literals-as-types)
 * - No spread operator on non-array objects (arkts-no-spread)
 * - All object literals correspond to explicit class/interface (arkts-no-untyped-obj-literals)
 */

// ─── Enums ───────────────────────────────────────────────────────────────────

export enum NodeType {
  START_EVENT = 'startEvent',
  END_EVENT = 'endEvent',
  TASK = 'task',
  GATEWAY = 'gateway',
  BOUNDARY_EVENT = 'boundaryEvent',
  INTERMEDIATE_EVENT = 'intermediateEvent',
  CALL_ACTIVITY = 'callActivity',
  SUB_PROCESS = 'subProcess',
  EVENT_BASED_GATEWAY = 'eventBasedGateway',
  COMPLEX_GATEWAY = 'complexGateway',
  DATA_OBJECT = 'dataObject',
  DATA_STORE = 'dataStore',
  TEXT_ANNOTATION = 'textAnnotation'
}

export enum EdgeStyle {
  POLYLINE = 'polyline',
  STRAIGHT = 'straight',
  CURVED = 'curved'
}

// ─── Data Classes ────────────────────────────────────────────────────────────
//  Every "plain object" in the spec is converted to an explicit class
//  because ArkTS strict mode forbids untyped object literals.

export class Viewport {
  x: number;
  y: number;
  zoom: number;

  constructor(x: number, y: number, zoom: number) {
    this.x = x;
    this.y = y;
    this.zoom = zoom;
  }
}

export class Waypoint {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

export class GraphNode {
  id: string;
  type: NodeType;
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
  properties: Record<string, string>;

  constructor(
    id: string,
    type: NodeType,
    x: number,
    y: number,
    width: number,
    height: number,
    label: string,
    properties: Record<string, string>
  ) {
    this.id = id;
    this.type = type;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.label = label;
    this.properties = properties;
  }
}

export class GraphEdge {
  id: string;
  sourceId: string;
  targetId: string;
  waypoints: Waypoint[];
  style: EdgeStyle;
  label: string;
  properties: Record<string, string>;

  constructor(
    id: string,
    sourceId: string,
    targetId: string,
    waypoints: Waypoint[],
    style: EdgeStyle,
    label: string,
    properties: Record<string, string>
  ) {
    this.id = id;
    this.sourceId = sourceId;
    this.targetId = targetId;
    this.waypoints = waypoints;
    this.style = style;
    this.label = label;
    this.properties = properties;
  }
}

// ─── Pool / Lane Data Classes ─────────────────────────────────────────────────

export class PoolBounds {
  x: number;
  y: number;
  width: number;
  height: number;

  constructor(x: number, y: number, width: number, height: number) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
}

export class Lane {
  id: string;
  name: string;
  bounds: PoolBounds;
  childLanes: Lane[];
  flowNodeRefs: string[];

  constructor(
    id: string,
    name: string,
    bounds: PoolBounds,
    childLanes: Lane[],
    flowNodeRefs: string[]
  ) {
    this.id = id;
    this.name = name;
    this.bounds = bounds;
    this.childLanes = childLanes;
    this.flowNodeRefs = flowNodeRefs;
  }
}

export class Pool {
  id: string;
  name: string;
  isHorizontal: boolean;
  bounds: PoolBounds;
  lanes: Lane[];

  constructor(
    id: string,
    name: string,
    isHorizontal: boolean,
    bounds: PoolBounds,
    lanes: Lane[]
  ) {
    this.id = id;
    this.name = name;
    this.isHorizontal = isHorizontal;
    this.bounds = bounds;
    this.lanes = lanes;
  }
}

// ─── Snapshot class (for serialization) ──────────────────────────────────────
//  Must be an explicit class — ArkTS forbids inline object literal types.

export class GraphModelSnapshot {
  nodes: GraphNode[];
  edges: GraphEdge[];
  viewport: Viewport;
  pools: Pool[];

  constructor(nodes: GraphNode[], edges: GraphEdge[], viewport: Viewport, pools: Pool[]) {
    this.nodes = nodes;
    this.edges = edges;
    this.viewport = viewport;
    this.pools = pools;
  }
}

// ─── GraphModel ──────────────────────────────────────────────────────────────

export class GraphModel {
  private _nodes: GraphNode[];
  private _edges: GraphEdge[];
  private _viewport: Viewport;
  private _pools: Pool[];

  /**
   * Construct a new GraphModel.
   * If no parameters given, creates an empty graph with default viewport.
   */
  constructor(nodes: GraphNode[], edges: GraphEdge[], viewport: Viewport, pools?: Pool[]) {
    this._nodes = [];
    for (let i = 0; i < nodes.length; i++) {
      this._nodes.push(this.cloneNode(nodes[i]));
    }
    this._edges = [];
    for (let i = 0; i < edges.length; i++) {
      this._edges.push(this.cloneEdge(edges[i]));
    }
    this._viewport = new Viewport(viewport.x, viewport.y, viewport.zoom);
    this._pools = [];
    let poolList: Pool[] = pools !== undefined ? pools : [];
    for (let i = 0; i < poolList.length; i++) {
      this._pools.push(this.clonePool(poolList[i]));
    }
  }

  /**
   * Create an empty model (convenience).
   */
  static createEmpty(): GraphModel {
    return new GraphModel(
      [] as GraphNode[],
      [] as GraphEdge[],
      new Viewport(0, 0, 1)
    );
  }

  // ── Query (read-only) ────────────────────────────────────────────────────

  getNodes(): GraphNode[] {
    let result: GraphNode[] = [];
    for (let i = 0; i < this._nodes.length; i++) {
      result.push(this.cloneNode(this._nodes[i]));
    }
    return result;
  }

  getNode(id: string): GraphNode | null {
    for (let i = 0; i < this._nodes.length; i++) {
      if (this._nodes[i].id === id) {
        return this.cloneNode(this._nodes[i]);
      }
    }
    return null;
  }

  hasNode(id: string): boolean {
    for (let i = 0; i < this._nodes.length; i++) {
      if (this._nodes[i].id === id) {
        return true;
      }
    }
    return false;
  }

  getNodeCount(): number {
    return this._nodes.length;
  }

  getEdges(): GraphEdge[] {
    let result: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      result.push(this.cloneEdge(this._edges[i]));
    }
    return result;
  }

  getEdge(id: string): GraphEdge | null {
    for (let i = 0; i < this._edges.length; i++) {
      if (this._edges[i].id === id) {
        return this.cloneEdge(this._edges[i]);
      }
    }
    return null;
  }

  hasEdge(id: string): boolean {
    for (let i = 0; i < this._edges.length; i++) {
      if (this._edges[i].id === id) {
        return true;
      }
    }
    return false;
  }

  getEdgeCount(): number {
    return this._edges.length;
  }

  getViewport(): Viewport {
    return new Viewport(this._viewport.x, this._viewport.y, this._viewport.zoom);
  }

  // ── Traversal ────────────────────────────────────────────────────────────

  getOutgoingEdges(nodeId: string): GraphEdge[] {
    let result: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      if (this._edges[i].sourceId === nodeId) {
        result.push(this.cloneEdge(this._edges[i]));
      }
    }
    return result;
  }

  getIncomingEdges(nodeId: string): GraphEdge[] {
    let result: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      if (this._edges[i].targetId === nodeId) {
        result.push(this.cloneEdge(this._edges[i]));
      }
    }
    return result;
  }

  getConnectedEdges(nodeId: string): GraphEdge[] {
    let outgoing: GraphEdge[] = this.getOutgoingEdges(nodeId);
    let incoming: GraphEdge[] = this.getIncomingEdges(nodeId);
    let result: GraphEdge[] = [];
    for (let i = 0; i < outgoing.length; i++) {
      result.push(outgoing[i]);
    }
    for (let i = 0; i < incoming.length; i++) {
      result.push(incoming[i]);
    }
    return result;
  }

  // ── Mutation (immutable pattern — every method returns a NEW GraphModel) ──

  /**
   * Add a single node. Returns a new GraphModel.
   */
  addNode(node: GraphNode): GraphModel {
    let newNodes: GraphNode[] = [];
    for (let i = 0; i < this._nodes.length; i++) {
      newNodes.push(this.cloneNode(this._nodes[i]));
    }
    newNodes.push(this.cloneNode(node));
    return new GraphModel(newNodes, this._edges, this._viewport, this._pools);
  }

  /**
   * Add multiple nodes at once. Returns a new GraphModel.
   */
  addNodes(nodes: GraphNode[]): GraphModel {
    let newNodes: GraphNode[] = [];
    for (let i = 0; i < this._nodes.length; i++) {
      newNodes.push(this.cloneNode(this._nodes[i]));
    }
    for (let i = 0; i < nodes.length; i++) {
      newNodes.push(this.cloneNode(nodes[i]));
    }
    return new GraphModel(newNodes, this._edges, this._viewport, this._pools);
  }

  /**
   * Add a single edge. Returns a new GraphModel.
   */
  addEdge(edge: GraphEdge): GraphModel {
    let newEdges: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      newEdges.push(this.cloneEdge(this._edges[i]));
    }
    newEdges.push(this.cloneEdge(edge));
    return new GraphModel(this._nodes, newEdges, this._viewport, this._pools);
  }

  /**
   * Add multiple edges at once. Returns a new GraphModel.
   */
  addEdges(edges: GraphEdge[]): GraphModel {
    let newEdges: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      newEdges.push(this.cloneEdge(this._edges[i]));
    }
    for (let i = 0; i < edges.length; i++) {
      newEdges.push(this.cloneEdge(edges[i]));
    }
    return new GraphModel(this._nodes, newEdges, this._viewport, this._pools);
  }

  /**
   * Fully replace an existing node by id.
   * If the id is not found, the model is returned unchanged.
   */
  updateNode(id: string, replacement: GraphNode): GraphModel {
    let newNodes: GraphNode[] = [];
    let found: boolean = false;
    for (let i = 0; i < this._nodes.length; i++) {
      if (this._nodes[i].id === id) {
        newNodes.push(this.cloneNode(replacement));
        found = true;
      } else {
        newNodes.push(this.cloneNode(this._nodes[i]));
      }
    }
    if (!found) {
      // id not found — return model unchanged
      return this;
    }
    return new GraphModel(newNodes, this._edges, this._viewport, this._pools);
  }

  /**
   * Fully replace an existing edge by id.
   * If the id is not found, the model is returned unchanged.
   */
  updateEdge(id: string, replacement: GraphEdge): GraphModel {
    let newEdges: GraphEdge[] = [];
    let found: boolean = false;
    for (let i = 0; i < this._edges.length; i++) {
      if (this._edges[i].id === id) {
        newEdges.push(this.cloneEdge(replacement));
        found = true;
      } else {
        newEdges.push(this.cloneEdge(this._edges[i]));
      }
    }
    if (!found) {
      return this;
    }
    return new GraphModel(this._nodes, newEdges, this._viewport, this._pools);
  }

  /**
   * Move a node to new (x, y) coordinates. Returns a new GraphModel.
   */
  moveNode(id: string, x: number, y: number): GraphModel {
    let newNodes: GraphNode[] = [];
    for (let i = 0; i < this._nodes.length; i++) {
      let n: GraphNode = this._nodes[i];
      if (n.id === id) {
        newNodes.push(new GraphNode(
          n.id, n.type, x, y, n.width, n.height, n.label,
          this.cloneRecord(n.properties)
        ));
      } else {
        newNodes.push(this.cloneNode(n));
      }
    }
    return new GraphModel(newNodes, this._edges, this._viewport, this._pools);
  }

  /**
   * Remove a node and ALL edges connected to it. Returns a new GraphModel.
   */
  removeNode(id: string): GraphModel {
    let newNodes: GraphNode[] = [];
    for (let i = 0; i < this._nodes.length; i++) {
      if (this._nodes[i].id !== id) {
        newNodes.push(this.cloneNode(this._nodes[i]));
      }
    }
    let newEdges: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      let e: GraphEdge = this._edges[i];
      if (e.sourceId !== id && e.targetId !== id) {
        newEdges.push(this.cloneEdge(e));
      }
    }
    let newPools: Pool[] = this.removeNodeFromPools(this._pools, id);
    return new GraphModel(newNodes, newEdges, this._viewport, newPools);
  }

  /**
   * Remove a single edge by id. Returns a new GraphModel.
   */
  removeEdge(id: string): GraphModel {
    let newEdges: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      if (this._edges[i].id !== id) {
        newEdges.push(this.cloneEdge(this._edges[i]));
      }
    }
    return new GraphModel(this._nodes, newEdges, this._viewport, this._pools);
  }

  /**
   * Replace the viewport. Returns a new GraphModel.
   */
  setViewport(viewport: Viewport): GraphModel {
    return new GraphModel(
      this._nodes,
      this._edges,
      new Viewport(viewport.x, viewport.y, viewport.zoom),
      this._pools
    );
  }

  /**
   * Reset to an empty graph. Returns a new GraphModel.
   */
  clear(): GraphModel {
    return GraphModel.createEmpty();
  }

  // ── Pool / Lane Query ────────────────────────────────────────────────────

  getPools(): Pool[] {
    let result: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      result.push(this.clonePool(this._pools[i]));
    }
    return result;
  }

  getPool(id: string): Pool | null {
    for (let i = 0; i < this._pools.length; i++) {
      if (this._pools[i].id === id) {
        return this.clonePool(this._pools[i]);
      }
    }
    return null;
  }

  hasPool(id: string): boolean {
    for (let i = 0; i < this._pools.length; i++) {
      if (this._pools[i].id === id) {
        return true;
      }
    }
    return false;
  }

  getPoolCount(): number {
    return this._pools.length;
  }

  getLaneByNode(nodeId: string): Lane | null {
    for (let i = 0; i < this._pools.length; i++) {
      let found: Lane | null = this.findLaneByNode(this._pools[i].lanes, nodeId);
      if (found !== null) {
        return found;
      }
    }
    return null;
  }

  // ── Pool Mutation ──────────────────────────────────────────────────────────

  addPool(pool: Pool): GraphModel {
    let newPools: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      newPools.push(this.clonePool(this._pools[i]));
    }
    newPools.push(this.clonePool(pool));
    return new GraphModel(this._nodes, this._edges, this._viewport, newPools);
  }

  removePool(id: string): GraphModel {
    let newPools: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      if (this._pools[i].id !== id) {
        newPools.push(this.clonePool(this._pools[i]));
      }
    }
    return new GraphModel(this._nodes, this._edges, this._viewport, newPools);
  }

  updatePool(id: string, replacement: Pool): GraphModel {
    let newPools: Pool[] = [];
    let found: boolean = false;
    for (let i = 0; i < this._pools.length; i++) {
      if (this._pools[i].id === id) {
        newPools.push(this.clonePool(replacement));
        found = true;
      } else {
        newPools.push(this.clonePool(this._pools[i]));
      }
    }
    if (!found) {
      return this;
    }
    return new GraphModel(this._nodes, this._edges, this._viewport, newPools);
  }

  updatePoolBounds(id: string, bounds: PoolBounds): GraphModel {
    let pool: Pool | null = this.getPool(id);
    if (pool === null) {
      return this;
    }
    let updated: Pool = new Pool(
      pool.id, pool.name, pool.isHorizontal,
      new PoolBounds(bounds.x, bounds.y, bounds.width, bounds.height),
      pool.lanes
    );
    return this.updatePool(id, updated);
  }

  // ── Lane Mutation ──────────────────────────────────────────────────────────

  addLane(poolId: string, lane: Lane, parentLaneId?: string): GraphModel {
    let newPools: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      let pool: Pool = this._pools[i];
      if (pool.id === poolId) {
        let newLanes: Lane[];
        if (parentLaneId !== undefined) {
          newLanes = this.addLaneToParent(pool.lanes, parentLaneId, lane);
        } else {
          newLanes = [];
          for (let j = 0; j < pool.lanes.length; j++) {
            newLanes.push(this.cloneLane(pool.lanes[j]));
          }
          newLanes.push(this.cloneLane(lane));
        }
        newPools.push(new Pool(pool.id, pool.name, pool.isHorizontal,
          new PoolBounds(pool.bounds.x, pool.bounds.y, pool.bounds.width, pool.bounds.height),
          newLanes));
      } else {
        newPools.push(this.clonePool(pool));
      }
    }
    return new GraphModel(this._nodes, this._edges, this._viewport, newPools);
  }

  removeLane(poolId: string, laneId: string): GraphModel {
    let newPools: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      let pool: Pool = this._pools[i];
      if (pool.id === poolId) {
        let newLanes: Lane[] = this.removeLaneFromList(pool.lanes, laneId);
        newPools.push(new Pool(pool.id, pool.name, pool.isHorizontal,
          new PoolBounds(pool.bounds.x, pool.bounds.y, pool.bounds.width, pool.bounds.height),
          newLanes));
      } else {
        newPools.push(this.clonePool(pool));
      }
    }
    return new GraphModel(this._nodes, this._edges, this._viewport, newPools);
  }

  updateLane(poolId: string, replacement: Lane): GraphModel {
    let newPools: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      let pool: Pool = this._pools[i];
      if (pool.id === poolId) {
        let newLanes: Lane[] = this.replaceLaneInList(pool.lanes, replacement);
        newPools.push(new Pool(pool.id, pool.name, pool.isHorizontal,
          new PoolBounds(pool.bounds.x, pool.bounds.y, pool.bounds.width, pool.bounds.height),
          newLanes));
      } else {
        newPools.push(this.clonePool(pool));
      }
    }
    return new GraphModel(this._nodes, this._edges, this._viewport, newPools);
  }

  // ── Serialization ────────────────────────────────────────────────────────

  /**
   * Export to a plain snapshot (explicit class, not object literal).
   */
  toJSON(): GraphModelSnapshot {
    let nodesCopy: GraphNode[] = [];
    for (let i = 0; i < this._nodes.length; i++) {
      nodesCopy.push(this.cloneNode(this._nodes[i]));
    }
    let edgesCopy: GraphEdge[] = [];
    for (let i = 0; i < this._edges.length; i++) {
      edgesCopy.push(this.cloneEdge(this._edges[i]));
    }
    let poolsCopy: Pool[] = [];
    for (let i = 0; i < this._pools.length; i++) {
      poolsCopy.push(this.clonePool(this._pools[i]));
    }
    return new GraphModelSnapshot(
      nodesCopy,
      edgesCopy,
      new Viewport(this._viewport.x, this._viewport.y, this._viewport.zoom),
      poolsCopy
    );
  }

  /**
   * Import from a snapshot. Returns a new GraphModel.
   */
  static fromJSON(snapshot: GraphModelSnapshot): GraphModel {
    return new GraphModel(snapshot.nodes, snapshot.edges, snapshot.viewport, snapshot.pools);
  }

  // ── Private helpers (deep-clone, zero spread) ─────────────────────────────

  private cloneNode(node: GraphNode): GraphNode {
    return new GraphNode(
      node.id,
      node.type,
      node.x,
      node.y,
      node.width,
      node.height,
      node.label,
      this.cloneRecord(node.properties)
    );
  }

  private cloneEdge(edge: GraphEdge): GraphEdge {
    let waypointsCopy: Waypoint[] = [];
    for (let j = 0; j < edge.waypoints.length; j++) {
      let wp: Waypoint = edge.waypoints[j];
      waypointsCopy.push(new Waypoint(wp.x, wp.y));
    }
    return new GraphEdge(
      edge.id,
      edge.sourceId,
      edge.targetId,
      waypointsCopy,
      edge.style,
      edge.label,
      this.cloneRecord(edge.properties)
    );
  }

  private cloneRecord(original: Record<string, string>): Record<string, string> {
    let result: Record<string, string> = {};
    let keys: string[] = Object.keys(original);
    for (let i = 0; i < keys.length; i++) {
      let k: string = keys[i];
      result[k] = original[k];
    }
    return result;
  }

  // ── Pool/Lane helpers ──────────────────────────────────────────────────────

  private clonePoolBounds(b: PoolBounds): PoolBounds {
    return new PoolBounds(b.x, b.y, b.width, b.height);
  }

  private cloneLane(lane: Lane): Lane {
    let childClones: Lane[] = [];
    for (let i = 0; i < lane.childLanes.length; i++) {
      childClones.push(this.cloneLane(lane.childLanes[i]));
    }
    let refsCopy: string[] = [];
    for (let i = 0; i < lane.flowNodeRefs.length; i++) {
      refsCopy.push(lane.flowNodeRefs[i]);
    }
    return new Lane(
      lane.id,
      lane.name,
      this.clonePoolBounds(lane.bounds),
      childClones,
      refsCopy
    );
  }

  private clonePool(pool: Pool): Pool {
    let laneClones: Lane[] = [];
    for (let i = 0; i < pool.lanes.length; i++) {
      laneClones.push(this.cloneLane(pool.lanes[i]));
    }
    return new Pool(
      pool.id,
      pool.name,
      pool.isHorizontal,
      this.clonePoolBounds(pool.bounds),
      laneClones
    );
  }

  private findLaneByNode(lanes: Lane[], nodeId: string): Lane | null {
    for (let i = 0; i < lanes.length; i++) {
      let lane: Lane = lanes[i];
      for (let j = 0; j < lane.flowNodeRefs.length; j++) {
        if (lane.flowNodeRefs[j] === nodeId) {
          return this.cloneLane(lane);
        }
      }
      if (lane.childLanes.length > 0) {
        let found: Lane | null = this.findLaneByNode(lane.childLanes, nodeId);
        if (found !== null) {
          return found;
        }
      }
    }
    return null;
  }

  private addLaneToParent(lanes: Lane[], parentId: string, newLane: Lane): Lane[] {
    let result: Lane[] = [];
    for (let i = 0; i < lanes.length; i++) {
      let lane: Lane = lanes[i];
      if (lane.id === parentId) {
        let newChildren: Lane[] = [];
        for (let j = 0; j < lane.childLanes.length; j++) {
          newChildren.push(this.cloneLane(lane.childLanes[j]));
        }
        newChildren.push(this.cloneLane(newLane));
        result.push(new Lane(
          lane.id, lane.name,
          this.clonePoolBounds(lane.bounds),
          newChildren,
          this.cloneStringArray(lane.flowNodeRefs)
        ));
      } else {
        result.push(this.cloneLane(lane));
      }
    }
    return result;
  }

  private removeLaneFromList(lanes: Lane[], targetId: string): Lane[] {
    let result: Lane[] = [];
    for (let i = 0; i < lanes.length; i++) {
      if (lanes[i].id !== targetId) {
        result.push(this.cloneLane(lanes[i]));
      }
    }
    return result;
  }

  private replaceLaneInList(lanes: Lane[], replacement: Lane): Lane[] {
    let result: Lane[] = [];
    for (let i = 0; i < lanes.length; i++) {
      if (lanes[i].id === replacement.id) {
        result.push(this.cloneLane(replacement));
      } else {
        // check child lanes recursively
        let updatedChildren: Lane[] = this.replaceLaneInList(lanes[i].childLanes, replacement);
        let changed: boolean = updatedChildren.length !== lanes[i].childLanes.length;
        if (!changed) {
          for (let j = 0; j < updatedChildren.length; j++) {
            if (updatedChildren[j] !== lanes[i].childLanes[j]) {
              changed = true;
              break;
            }
          }
        }
        if (changed) {
          result.push(new Lane(
            lanes[i].id, lanes[i].name,
            this.clonePoolBounds(lanes[i].bounds),
            updatedChildren,
            this.cloneStringArray(lanes[i].flowNodeRefs)
          ));
        } else {
          result.push(this.cloneLane(lanes[i]));
        }
      }
    }
    return result;
  }

  private removeNodeFromPools(pools: Pool[], nodeId: string): Pool[] {
    let result: Pool[] = [];
    for (let i = 0; i < pools.length; i++) {
      let pool: Pool = pools[i];
      let newLanes: Lane[] = this.removeNodeFromLanes(pool.lanes, nodeId);
      result.push(new Pool(
        pool.id, pool.name, pool.isHorizontal,
        this.clonePoolBounds(pool.bounds),
        newLanes
      ));
    }
    return result;
  }

  private removeNodeFromLanes(lanes: Lane[], nodeId: string): Lane[] {
    let result: Lane[] = [];
    for (let i = 0; i < lanes.length; i++) {
      let lane: Lane = lanes[i];
      let newRefs: string[] = [];
      for (let j = 0; j < lane.flowNodeRefs.length; j++) {
        if (lane.flowNodeRefs[j] !== nodeId) {
          newRefs.push(lane.flowNodeRefs[j]);
        }
      }
      let newChildren: Lane[] = this.removeNodeFromLanes(lane.childLanes, nodeId);
      result.push(new Lane(
        lane.id, lane.name,
        this.clonePoolBounds(lane.bounds),
        newChildren,
        newRefs
      ));
    }
    return result;
  }

  private cloneStringArray(arr: string[]): string[] {
    let result: string[] = [];
    for (let i = 0; i < arr.length; i++) {
      result.push(arr[i]);
    }
    return result;
  }
}