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
  GATEWAY = 'gateway'
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

// ─── Snapshot class (for serialization) ──────────────────────────────────────
//  Must be an explicit class — ArkTS forbids inline object literal types.

export class GraphModelSnapshot {
  nodes: GraphNode[];
  edges: GraphEdge[];
  viewport: Viewport;

  constructor(nodes: GraphNode[], edges: GraphEdge[], viewport: Viewport) {
    this.nodes = nodes;
    this.edges = edges;
    this.viewport = viewport;
  }
}

// ─── GraphModel ──────────────────────────────────────────────────────────────

export class GraphModel {
  private _nodes: GraphNode[];
  private _edges: GraphEdge[];
  private _viewport: Viewport;

  /**
   * Construct a new GraphModel.
   * If no parameters given, creates an empty graph with default viewport.
   */
  constructor(nodes: GraphNode[], edges: GraphEdge[], viewport: Viewport) {
    this._nodes = [];
    for (let i = 0; i < nodes.length; i++) {
      this._nodes.push(this.cloneNode(nodes[i]));
    }
    this._edges = [];
    for (let i = 0; i < edges.length; i++) {
      this._edges.push(this.cloneEdge(edges[i]));
    }
    this._viewport = new Viewport(viewport.x, viewport.y, viewport.zoom);
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
    return new GraphModel(newNodes, this._edges, this._viewport);
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
    return new GraphModel(newNodes, this._edges, this._viewport);
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
    return new GraphModel(this._nodes, newEdges, this._viewport);
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
    return new GraphModel(this._nodes, newEdges, this._viewport);
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
    return new GraphModel(newNodes, this._edges, this._viewport);
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
    return new GraphModel(this._nodes, newEdges, this._viewport);
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
    return new GraphModel(newNodes, this._edges, this._viewport);
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
    return new GraphModel(newNodes, newEdges, this._viewport);
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
    return new GraphModel(this._nodes, newEdges, this._viewport);
  }

  /**
   * Replace the viewport. Returns a new GraphModel.
   */
  setViewport(viewport: Viewport): GraphModel {
    return new GraphModel(
      this._nodes,
      this._edges,
      new Viewport(viewport.x, viewport.y, viewport.zoom)
    );
  }

  /**
   * Reset to an empty graph. Returns a new GraphModel.
   */
  clear(): GraphModel {
    return GraphModel.createEmpty();
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
    return new GraphModelSnapshot(
      nodesCopy,
      edgesCopy,
      new Viewport(this._viewport.x, this._viewport.y, this._viewport.zoom)
    );
  }

  /**
   * Import from a snapshot. Returns a new GraphModel.
   */
  static fromJSON(snapshot: GraphModelSnapshot): GraphModel {
    return new GraphModel(snapshot.nodes, snapshot.edges, snapshot.viewport);
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
}