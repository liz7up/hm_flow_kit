import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { HitTestManager, HitResult, HitType } from '../../../main/ets/renderer/HitTestManager';
import { GraphModel, GraphNode, GraphEdge, NodeType, EdgeStyle } from '../../../main/ets/model/GraphModel';
import { CanvasManager } from '../../../main/ets/renderer/CanvasManager';

function makeNode(id: string, x: number, y: number, w?: number, h?: number): GraphNode {
  let wi: number = w !== undefined ? w : 120;
  let he: number = h !== undefined ? h : 60;
  return new GraphNode(id, NodeType.TASK, x, y, wi, he, id, {});
}

function makeEdge(id: string, src: string, tgt: string): GraphEdge {
  return new GraphEdge(id, src, tgt, [], EdgeStyle.POLYLINE, '', {});
}

export default function hitTestManagerTest(): void {
  describe('HitTestManager', () => {
    let hitMgr: HitTestManager;
    let model: GraphModel;
    let canvasMgr: CanvasManager;

    beforeEach(() => {
      hitMgr = new HitTestManager();
      model = GraphModel.createEmpty();
      canvasMgr = new CanvasManager();
    });

    // ── 空模型 ──

    it('empty_model_should_return_CANVAS', 0, () => {
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(50, 50, canvasMgr);
      expect(r.type).assertEqual(HitType.CANVAS);
      expect(r.hasHit).assertEqual(false);
    });

    // ── 节点命中 ──

    it('hit_node_center_should_return_NODE', 0, () => {
      model = model.addNode(makeNode('A', 100, 100, 120, 60));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(160, 130, canvasMgr);
      expect(r.type).assertEqual(HitType.NODE);
      expect(r.nodeId).assertEqual('A');
    });

    it('hit_outside_node_should_return_CANVAS', 0, () => {
      model = model.addNode(makeNode('A', 100, 100, 120, 60));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(0, 0, canvasMgr);
      expect(r.type).assertEqual(HitType.CANVAS);
    });

    it('hit_node_corner_should_return_NODE', 0, () => {
      model = model.addNode(makeNode('A', 100, 100, 50, 50));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(100, 100, canvasMgr);
      expect(r.type).assertEqual(HitType.NODE);
    });

    it('topmost_node_should_win_on_overlap', 0, () => {
      model = model.addNode(makeNode('A', 100, 100, 100, 100))
        .addNode(makeNode('B', 120, 120, 100, 100));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(150, 150, canvasMgr);
      expect(r.type).assertEqual(HitType.NODE);
      expect(r.nodeId).assertEqual('B');
    });

    // ── 连线命中 ──

    it('hit_near_edge_segment_should_return_EDGE', 0, () => {
      model = model.addNode(makeNode('A', 0, 55, 100, 100))
        .addNode(makeNode('B', 400, 55, 100, 100))
        .addEdge(makeEdge('e1', 'A', 'B'));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(250, 105, canvasMgr);
      expect(r.type).assertEqual(HitType.EDGE);
      expect(r.edgeId).assertEqual('e1');
    });

    it('hit_far_from_edge_should_not_match', 0, () => {
      model = model.addNode(makeNode('A', 0, 0, 100, 100))
        .addNode(makeNode('B', 400, 0, 100, 100))
        .addEdge(makeEdge('e1', 'A', 'B'));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(500, 500, canvasMgr);
      expect(r.type).assertEqual(HitType.CANVAS);
    });

    // ── 节点优先于连线 ──

    it('node_should_win_over_edge_at_connection_point', 0, () => {
      model = model.addNode(makeNode('A', 0, 0, 100, 100))
        .addNode(makeNode('B', 400, 0, 100, 100))
        .addEdge(makeEdge('e1', 'A', 'B'));
      hitMgr.rebuild(model, canvasMgr);
      let r: HitResult = hitMgr.hitTest(50, 50, canvasMgr);
      expect(r.type).assertEqual(HitType.NODE);
    });

    // ── clear ──

    it('clear_should_make_all_hits_CANVAS', 0, () => {
      model = model.addNode(makeNode('A', 0, 0, 100, 100));
      hitMgr.rebuild(model, canvasMgr);
      hitMgr.clear();
      let r: HitResult = hitMgr.hitTest(50, 50, canvasMgr);
      expect(r.type).assertEqual(HitType.CANVAS);
    });
  });
}
