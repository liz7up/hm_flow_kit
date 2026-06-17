import { describe, beforeEach, it, expect } from '@ohos/hypium';
import {
  GraphModel, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle, Viewport,
  Pool, Lane, PoolBounds
} from '../../../main/ets/model/GraphModel';

function makeNode(id: string, x: number, y: number, label?: string, type?: NodeType): GraphNode {
  let l: string = label !== undefined ? label : '';
  let t: NodeType = type !== undefined ? type : NodeType.TASK;
  return new GraphNode(id, t, x, y, 120, 60, l, {});
}

function makeEdge(id: string, src: string, tgt: string): GraphEdge {
  return new GraphEdge(id, src, tgt, [], EdgeStyle.POLYLINE, '', {});
}

function makeBounds(x: number, y: number, w: number, h: number): PoolBounds {
  return new PoolBounds(x, y, w, h);
}

function makeLane(id: string, name: string): Lane {
  return new Lane(id, name, new PoolBounds(0, 0, 200, 80), [], []);
}

function makePool(id: string, name: string, isHorizontal: boolean = true): Pool {
  return new Pool(id, name, isHorizontal, new PoolBounds(0, 0, 400, 200), []);
}

export default function graphModelTest(): void {
  describe('GraphModel', () => {
    let model: GraphModel;

    beforeEach(() => {
      model = GraphModel.createEmpty();
    });

    // ── 构造 ──

    it('createEmpty_should_return_model_with_zero_counts', 0, () => {
      expect(model.getNodeCount()).assertEqual(0);
      expect(model.getEdgeCount()).assertEqual(0);
    });

    it('constructor_should_clone_input_arrays', 0, () => {
      let n: GraphNode = makeNode('n1', 10, 20);
      let m: GraphModel = new GraphModel([n], [], new Viewport(0, 0, 1));
      n.x = 999;
      let n1: GraphNode | null = m.getNode('n1');
      expect(n1 !== null ? n1.x : -1).assertEqual(10);
    });

    // ── 查询 ──

    it('getNode_should_return_null_for_missing', 0, () => {
      expect(model.getNode('nonexistent')).assertEqual(null);
    });

    it('getNode_should_return_clone', 0, () => {
      model = model.addNode(makeNode('A', 10, 20, 'Label'));
      let node: GraphNode | null = model.getNode('A');
      expect(node !== null ? node.label : '').assertEqual('Label');
    });

    it('hasNode_should_return_boolean', 0, () => {
      model = model.addNode(makeNode('A', 0, 0));
      expect(model.hasNode('A')).assertEqual(true);
      expect(model.hasNode('B')).assertEqual(false);
    });

    it('getNodes_should_return_all', 0, () => {
      model = model.addNodes([makeNode('A', 0, 0), makeNode('B', 1, 1)]);
      expect(model.getNodeCount()).assertEqual(2);
    });

    it('getEdge_should_return_null_for_missing', 0, () => {
      expect(model.getEdge('no')).assertEqual(null);
    });

    // ── 遍历 ──

    it('getOutgoingEdges_should_filter_by_source', 0, () => {
      let n1: GraphNode = makeNode('n1', 0, 0);
      let n2: GraphNode = makeNode('n2', 100, 0);
      let n3: GraphNode = makeNode('n3', 200, 0);
      model = model.addNodes([n1, n2, n3])
        .addEdge(makeEdge('e1', 'n1', 'n2'))
        .addEdge(makeEdge('e2', 'n1', 'n3'))
        .addEdge(makeEdge('e3', 'n2', 'n3'));
      expect(model.getOutgoingEdges('n1').length).assertEqual(2);
      expect(model.getOutgoingEdges('n3').length).assertEqual(0);
    });

    it('getIncomingEdges_should_filter_by_target', 0, () => {
      model = model.addNodes([makeNode('n1', 0, 0), makeNode('n2', 100, 0)])
        .addEdge(makeEdge('e1', 'n1', 'n2'));
      expect(model.getIncomingEdges('n2').length).assertEqual(1);
      expect(model.getIncomingEdges('n1').length).assertEqual(0);
    });

    it('getConnectedEdges_should_merge_both_directions', 0, () => {
      model = model.addNodes([
        makeNode('A', 0, 0), makeNode('B', 100, 0), makeNode('C', 200, 0)
      ]).addEdge(makeEdge('e1', 'A', 'B'))
        .addEdge(makeEdge('e2', 'C', 'B'));
      expect(model.getConnectedEdges('B').length).assertEqual(2);
    });

    // ── 不可变写入 ──

    it('addNode_should_return_new_model', 0, () => {
      let m2: GraphModel = model.addNode(makeNode('A', 0, 0));
      expect(model.getNodeCount()).assertEqual(0);
      expect(m2.getNodeCount()).assertEqual(1);
    });

    it('addEdge_should_return_new_model', 0, () => {
      model = model.addNodes([makeNode('A', 0, 0), makeNode('B', 100, 0)]);
      let m2: GraphModel = model.addEdge(makeEdge('e1', 'A', 'B'));
      expect(model.getEdgeCount()).assertEqual(0);
      expect(m2.getEdgeCount()).assertEqual(1);
    });

    it('removeNode_should_cascade_delete_edges', 0, () => {
      model = model.addNodes([
        makeNode('A', 0, 0), makeNode('B', 100, 0), makeNode('C', 200, 0)
      ]).addEdge(makeEdge('e1', 'A', 'B'))
        .addEdge(makeEdge('e2', 'A', 'C'))
        .addEdge(makeEdge('e3', 'B', 'C'));
      let m2: GraphModel = model.removeNode('A');
      expect(m2.getNodeCount()).assertEqual(2);
      expect(m2.getEdgeCount()).assertEqual(1);
    });

    it('removeEdge_should_only_remove_target', 0, () => {
      model = model.addNodes([makeNode('A', 0, 0), makeNode('B', 100, 0)])
        .addEdge(makeEdge('e1', 'A', 'B'))
        .addEdge(makeEdge('e2', 'B', 'A'));
      let m2: GraphModel = model.removeEdge('e1');
      expect(m2.getEdgeCount()).assertEqual(1);
      expect(m2.hasEdge('e1')).assertEqual(false);
      expect(m2.hasEdge('e2')).assertEqual(true);
    });

    it('moveNode_should_update_coordinates', 0, () => {
      model = model.addNode(makeNode('A', 10, 20));
      let m2: GraphModel = model.moveNode('A', 99, 88);
      let n: GraphNode | null = m2.getNode('A');
      expect(n !== null ? n.x : -1).assertEqual(99);
      expect(n !== null ? n.y : -1).assertEqual(88);
    });

    // ── 序列化 ──

    it('toJSON_fromJSON_should_roundtrip', 0, () => {
      model = model.addNodes([makeNode('A', 10, 20), makeNode('B', 30, 40)])
        .addEdge(makeEdge('e1', 'A', 'B'));
      let snap = model.toJSON();
      let restored: GraphModel = GraphModel.fromJSON(snap);
      expect(restored.getNodeCount()).assertEqual(2);
      expect(restored.getEdgeCount()).assertEqual(1);
      let a: GraphNode | null = restored.getNode('A');
      expect(a !== null ? a.x : -1).assertEqual(10);
    });

    // ── Pool/Lane 数据结构 ──

    it('PoolBounds_should_store_coordinates', 0, () => {
      let b: PoolBounds = new PoolBounds(10, 20, 300, 150);
      expect(b.x).assertEqual(10);
      expect(b.y).assertEqual(20);
      expect(b.width).assertEqual(300);
      expect(b.height).assertEqual(150);
    });

    it('Lane_should_store_properties', 0, () => {
      let lb: PoolBounds = new PoolBounds(5, 5, 200, 100);
      let child: Lane = new Lane('child', 'Child', new PoolBounds(0, 0, 100, 50), [], ['n1']);
      let lane: Lane = new Lane('L1', 'Manager', lb, [child], ['n1', 'n2']);
      expect(lane.id).assertEqual('L1');
      expect(lane.name).assertEqual('Manager');
      expect(lane.bounds.x).assertEqual(5);
      expect(lane.childLanes.length).assertEqual(1);
      expect(lane.flowNodeRefs.length).assertEqual(2);
      expect(lane.flowNodeRefs[0]).assertEqual('n1');
    });

    it('Pool_should_store_properties', 0, () => {
      let pb: PoolBounds = new PoolBounds(0, 0, 800, 400);
      let lane: Lane = makeLane('L1', 'Swimlane');
      let pool: Pool = new Pool('P1', 'Sales', true, pb, [lane]);
      expect(pool.id).assertEqual('P1');
      expect(pool.name).assertEqual('Sales');
      expect(pool.isHorizontal).assertEqual(true);
      expect(pool.bounds.width).assertEqual(800);
      expect(pool.lanes.length).assertEqual(1);
    });

    // ── Pool CRUD ──

    it('createEmpty_should_have_empty_pools', 0, () => {
      expect(model.getPoolCount()).assertEqual(0);
      expect(model.getPools().length).assertEqual(0);
    });

    it('addPool_should_return_new_model', 0, () => {
      let pool: Pool = makePool('P1', 'Participants');
      let m2: GraphModel = model.addPool(pool);
      expect(model.getPoolCount()).assertEqual(0);
      expect(m2.getPoolCount()).assertEqual(1);
    });

    it('getPool_should_return_null_for_missing', 0, () => {
      expect(model.getPool('nonexistent')).assertEqual(null);
    });

    it('getPool_should_return_clone', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'));
      let p: Pool | null = model.getPool('P1');
      expect(p !== null ? p.name : '').assertEqual('Sales');
    });

    it('hasPool_should_return_boolean', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'));
      expect(model.hasPool('P1')).assertEqual(true);
      expect(model.hasPool('P2')).assertEqual(false);
    });

    it('getPools_should_return_all', 0, () => {
      model = model.addPool(makePool('P1', 'A'))
        .addPool(makePool('P2', 'B', false));
      expect(model.getPools().length).assertEqual(2);
    });

    it('removePool_should_remove_pool_and_lanes', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'))
        .addPool(makePool('P2', 'Finance'));
      let m2: GraphModel = model.removePool('P1');
      expect(m2.getPoolCount()).assertEqual(1);
      expect(m2.hasPool('P1')).assertEqual(false);
      expect(m2.hasPool('P2')).assertEqual(true);
    });

    it('updatePool_should_replace_pool', 0, () => {
      model = model.addPool(makePool('P1', 'Old'));
      let updated: Pool = new Pool('P1', 'New', false, new PoolBounds(10, 20, 300, 150), []);
      let m2: GraphModel = model.updatePool('P1', updated);
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.name : '').assertEqual('New');
      expect(p !== null ? p.isHorizontal : true).assertEqual(false);
    });

    it('updatePoolBounds_should_update_only_bounds', 0, () => {
      let lane: Lane = makeLane('L1', 'Lane');
      let pool: Pool = new Pool('P1', 'Sales', true, new PoolBounds(0, 0, 400, 200), [lane]);
      model = model.addPool(pool);
      let newBounds: PoolBounds = new PoolBounds(50, 50, 600, 300);
      let m2: GraphModel = model.updatePoolBounds('P1', newBounds);
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.bounds.x : -1).assertEqual(50);
      expect(p !== null ? p.bounds.width : -1).assertEqual(600);
      expect(p !== null ? p.lanes.length : -1).assertEqual(1);
    });

    it('updatePool_should_return_this_for_missing_id', 0, () => {
      let updated: Pool = new Pool('NoSuch', 'X', true, new PoolBounds(0, 0, 100, 100), []);
      let m2: GraphModel = model.updatePool('NoSuch', updated);
      expect(m2 === model).assertEqual(true);
    });

    it('updatePoolBounds_should_return_this_for_missing_id', 0, () => {
      let m2: GraphModel = model.updatePoolBounds('NoSuch', new PoolBounds(0, 0, 100, 100));
      expect(m2 === model).assertEqual(true);
    });

    // ── Lane CRUD ──

    it('addLane_should_add_to_pool', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'));
      let lane: Lane = makeLane('L1', 'Manager');
      let m2: GraphModel = model.addLane('P1', lane);
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.lanes.length : -1).assertEqual(1);
      expect(p !== null ? p.lanes[0].name : '').assertEqual('Manager');
    });

    it('addLane_should_add_nested_child', 0, () => {
      let parentLane: Lane = makeLane('L1', 'Parent');
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', parentLane);
      let child: Lane = makeLane('L1a', 'Child');
      let m2: GraphModel = model.addLane('P1', child, 'L1');
      let p: Pool | null = m2.getPool('P1');
      let parent: Lane | null = p !== null ? p.lanes[0] : null;
      expect(parent !== null ? parent.childLanes.length : -1).assertEqual(1);
      expect(parent !== null ? parent.childLanes[0].id : '').assertEqual('L1a');
    });

    it('addLane_should_not_mutate_original', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'));
      model.addLane('P1', makeLane('L1', 'Lane'));
      expect(model.getPool('P1') !== null
        ? (model.getPool('P1') as Pool).lanes.length
        : -1).assertEqual(0);
    });

    it('removeLane_should_cascade_delete_child_lanes', 0, () => {
      let child: Lane = new Lane('child', 'Child', new PoolBounds(0, 0, 100, 50), [], []);
      let parent: Lane = new Lane('parent', 'Parent', new PoolBounds(0, 0, 200, 100), [child], []);
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', parent);
      let m2: GraphModel = model.removeLane('P1', 'parent');
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.lanes.length : -1).assertEqual(0);
    });

    it('removeLane_should_only_remove_target_lane', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', makeLane('L1', 'First'))
        .addLane('P1', makeLane('L2', 'Second'));
      let m2: GraphModel = model.removeLane('P1', 'L1');
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.lanes.length : -1).assertEqual(1);
      expect(p !== null ? p.lanes[0].id : '').assertEqual('L2');
    });

    it('updateLane_should_replace_lane_in_pool', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', makeLane('L1', 'OldName'));
      let updated: Lane = new Lane('L1', 'NewName', new PoolBounds(0, 0, 300, 120), [], ['n1']);
      let m2: GraphModel = model.updateLane('P1', updated);
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.lanes[0].name : '').assertEqual('NewName');
      expect(p !== null ? p.lanes[0].flowNodeRefs.length : -1).assertEqual(1);
    });

    it('addLane_with_parentLaneId_should_nest_directly', 0, () => {
      let parent: Lane = makeLane('L1', 'Parent');
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', parent);
      let child: Lane = makeLane('L1a', 'Child');
      let m2: GraphModel = model.addLane('P1', child, 'L1');
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.lanes[0].childLanes.length : -1).assertEqual(1);
      expect(p !== null ? p.lanes[0].childLanes[0].name : '').assertEqual('Child');
    });

    // ── Node-Lane 关联 ──

    it('getLaneByNode_should_find_lane_containing_node', 0, () => {
      let lane: Lane = new Lane('L1', 'Manager', new PoolBounds(0, 0, 200, 100), [], ['n1', 'n2']);
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', lane);
      let found: Lane | null = model.getLaneByNode('n2');
      expect(found !== null ? found.id : '').assertEqual('L1');
    });

    it('getLaneByNode_should_search_nested_lanes', 0, () => {
      let child: Lane = new Lane('child', 'Child', new PoolBounds(0, 0, 100, 80), [], ['deepNode']);
      let parent: Lane = new Lane('parent', 'Parent', new PoolBounds(0, 0, 200, 160), [child], ['parentNode']);
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', parent);
      expect(model.getLaneByNode('deepNode') !== null
        ? (model.getLaneByNode('deepNode') as Lane).id
        : '').assertEqual('child');
      expect(model.getLaneByNode('parentNode') !== null
        ? (model.getLaneByNode('parentNode') as Lane).id
        : '').assertEqual('parent');
    });

    it('getLaneByNode_should_return_null_for_unreferenced', 0, () => {
      model = model.addPool(makePool('P1', 'Sales'))
        .addLane('P1', makeLane('L1', 'Lane'));
      expect(model.getLaneByNode('noSuchNode')).assertEqual(null);
    });

    it('getLaneByNode_should_return_null_when_no_pools', 0, () => {
      expect(model.getLaneByNode('any')).assertEqual(null);
    });

    // ── 不可变性 ──

    it('constructor_should_clone_pool_data', 0, () => {
      let pool: Pool = makePool('P1', 'Original');
      model = new GraphModel([], [], new Viewport(0, 0, 1), [pool]);
      pool.name = 'Modified';
      let p: Pool | null = model.getPool('P1');
      expect(p !== null ? p.name : '').assertEqual('Original');
    });

    // ── 序列化含 Pool/Lane ──

    it('toJSON_fromJSON_should_roundtrip_with_pools', 0, () => {
      let lane: Lane = new Lane('L1', 'Lane', new PoolBounds(10, 20, 200, 100), [], ['n1']);
      let pool: Pool = new Pool('P1', 'Sales', true, new PoolBounds(0, 0, 400, 200), [lane]);
      model = model.addNode(makeNode('n1', 50, 50, 'Task'))
        .addPool(pool);
      let snap = model.toJSON();
      let restored: GraphModel = GraphModel.fromJSON(snap);
      expect(restored.getPoolCount()).assertEqual(1);
      let rp: Pool | null = restored.getPool('P1');
      expect(rp !== null ? rp.name : '').assertEqual('Sales');
      expect(rp !== null ? rp.lanes.length : -1).assertEqual(1);
    });

    it('removeNode_should_clean_lane_flowNodeRefs', 0, () => {
      let lane: Lane = new Lane('L1', 'Manager', new PoolBounds(0, 0, 200, 100), [], ['n1', 'n2']);
      model = model.addNodes([makeNode('n1', 10, 10), makeNode('n2', 50, 50)])
        .addPool(makePool('P1', 'Sales'))
        .addLane('P1', lane);
      let m2: GraphModel = model.removeNode('n1');
      let p: Pool | null = m2.getPool('P1');
      expect(p !== null ? p.lanes[0].flowNodeRefs.length : -1).assertEqual(1);
      expect(p !== null ? p.lanes[0].flowNodeRefs[0] : '').assertEqual('n2');
    });
  });
}
