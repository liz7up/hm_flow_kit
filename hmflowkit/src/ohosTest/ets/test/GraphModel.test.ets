import { describe, beforeEach, it, expect } from '@ohos/hypium';
import {
  GraphModel, GraphNode, GraphEdge, Waypoint, NodeType, EdgeStyle, Viewport
} from '../../../main/ets/model/GraphModel';

function makeNode(id: string, x: number, y: number, label?: string, type?: NodeType): GraphNode {
  let l: string = label !== undefined ? label : '';
  let t: NodeType = type !== undefined ? type : NodeType.TASK;
  return new GraphNode(id, t, x, y, 120, 60, l, {});
}

function makeEdge(id: string, src: string, tgt: string): GraphEdge {
  return new GraphEdge(id, src, tgt, [], EdgeStyle.POLYLINE, '', {});
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
  });
}
