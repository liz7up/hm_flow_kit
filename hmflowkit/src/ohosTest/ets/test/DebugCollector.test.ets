import { describe, it, expect } from '@ohos/hypium'
import { DebugCollector } from '../../../main/ets/debug/DebugCollector'
import { GraphModel, GraphNode, NodeType, Pool, Lane, PoolBounds } from '../../../main/ets/model/GraphModel'
import { CanvasManager } from '../../../main/ets/renderer/CanvasManager'
import { RenderConfig } from '../../../main/ets/renderer/RenderConfig'
import { ParseMeta } from '../../../main/ets/parser/BpmnXmlParser'
import { SourceFormat } from '../../../main/ets/debug/DebugTypes'

function makeModel(): GraphModel {
  let model: GraphModel = GraphModel.createEmpty()
  let n1: GraphNode = new GraphNode('Task_1', NodeType.TASK, 100, 200, 120, 60, 'Task 1', {})
  let n2: GraphNode = new GraphNode('GW_1', NodeType.GATEWAY, 300, 200, 50, 50, 'Gateway', {})
  let n3: GraphNode = new GraphNode('Event_1', NodeType.START_EVENT, 50, 200, 36, 36, 'Start', {})
  model = model.addNodes([n1, n2, n3])
  return model
}

function makeMeta(): ParseMeta {
  let meta: ParseMeta = new ParseMeta()
  meta.semanticIds = ['Task_1', 'GW_1', 'Event_1']
  meta.semanticTypes['Task_1'] = 'userTask'
  meta.semanticTypes['GW_1'] = 'exclusiveGateway'
  meta.semanticTypes['Event_1'] = 'startEvent'
  meta.discardedElementTypes['textAnnotation'] = 2
  return meta
}

export default function DebugCollectorTest() {
  describe('DebugCollector', () => {

    it('getStatistics_should_count_nodes_by_type', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let stats = collector.getStatistics()
      expect(stats.totalNodes).assertEqual(3)
      expect(stats.edgeCount).assertEqual(0)
      let taskCount: number | undefined = stats.nodesByType['task']
      expect(taskCount !== undefined ? taskCount : 0).assertEqual(1)
    })

    it('getStatistics_should_count_pools_and_lanes', 0, () => {
      let model: GraphModel = GraphModel.createEmpty()
      let poolBounds: PoolBounds = new PoolBounds(0, 0, 400, 200)
      let laneBounds: PoolBounds = new PoolBounds(0, 0, 400, 100)
      let lane: Lane = new Lane('Lane_1', 'Lane 1', laneBounds, [], [])
      let pool: Pool = new Pool('Pool_1', 'Pool 1', true, poolBounds, [lane])
      model = model.addPool(pool)
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let stats = collector.getStatistics()
      expect(stats.poolCount).assertEqual(1)
      expect(stats.laneCount).assertEqual(1)
    })

    it('getStatistics_should_return_zero_for_empty_model', 0, () => {
      let model: GraphModel = GraphModel.createEmpty()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let stats = collector.getStatistics()
      expect(stats.totalNodes).assertEqual(0)
      expect(stats.edgeCount).assertEqual(0)
    })

    it('getNodeDetail_should_return_node_data', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let detail = collector.getNodeDetail('Task_1')
      expect(detail !== null).assertTrue()
      if (detail !== null) {
        expect(detail.id).assertEqual('Task_1')
        expect(detail.type).assertEqual('task')
        expect(detail.x).assertEqual(100)
        expect(detail.y).assertEqual(200)
        expect(detail.width).assertEqual(120)
        expect(detail.height).assertEqual(60)
      }
    })

    it('getNodeDetail_should_return_null_for_missing', 0, () => {
      let model: GraphModel = GraphModel.createEmpty()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let detail = collector.getNodeDetail('nonexistent')
      expect(detail).assertNull()
    })

    it('getParseDiff_should_find_missing_elements', 0, () => {
      let model: GraphModel = makeModel() // has Task_1, GW_1, Event_1
      let meta: ParseMeta = makeMeta()
      // Add an extra XML ID that doesn't exist in model
      meta.semanticIds.push('Missing_Task')
      meta.semanticTypes['Missing_Task'] = 'userTask'
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc, meta)
      let diff = collector.getParseDiff()
      expect(diff !== null).assertTrue()
      if (diff !== null) {
        expect(diff.missing.length).assertEqual(1)
        expect(diff.missing[0]).assertEqual('Missing_Task')
      }
    })

    it('getParseDiff_should_return_null_without_parseMeta', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let diff = collector.getParseDiff()
      expect(diff).assertNull()
    })

    it('getSourceFormat_should_return_BPMN_with_parseMeta', 0, () => {
      let model: GraphModel = makeModel()
      let meta: ParseMeta = makeMeta()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc, meta)
      expect(collector.getSourceFormat()).assertEqual(SourceFormat.BPMN)
    })

    it('getSourceFormat_should_return_DIRECT_without_meta', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      expect(collector.getSourceFormat()).assertEqual(SourceFormat.DIRECT)
    })

    it('getRenderStats_should_return_zero_for_no_frames', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let stats = collector.getRenderStats()
      expect(stats.frameCount).assertEqual(0)
    })

    it('getRenderStats_should_track_recorded_times', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      collector.recordRenderTime(10)
      collector.recordRenderTime(20)
      collector.recordRenderTime(15)
      let stats = collector.getRenderStats()
      expect(stats.frameCount).assertEqual(3)
      expect(stats.lastMs).assertEqual(15)
      expect(stats.minMs).assertEqual(10)
      expect(stats.maxMs).assertEqual(20)
    })

    it('getIdMapping_should_match_xml_ids_to_model', 0, () => {
      let model: GraphModel = makeModel()
      let meta: ParseMeta = makeMeta()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc, meta)
      let mappings = collector.getIdMapping()
      expect(mappings.length).assertEqual(3)
      expect(mappings[0].matched).assertTrue()
      expect(mappings[1].matched).assertTrue()
    })

    it('getIdMapping_should_return_empty_without_parseMeta', 0, () => {
      let model: GraphModel = makeModel()
      let cm: CanvasManager = new CanvasManager()
      let rc: RenderConfig = new RenderConfig()
      let collector: DebugCollector = new DebugCollector(model, cm, rc)
      let mappings = collector.getIdMapping()
      expect(mappings.length).assertEqual(0)
    })
  })
}
