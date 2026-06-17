import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { CanvasManager, CanvasPoint, ScreenPoint, ViewportState } from '../../../main/ets/renderer/CanvasManager';

export default function canvasManagerTest(): void {
  describe('CanvasManager', () => {
    let cm: CanvasManager;

    beforeEach(() => {
      cm = new CanvasManager();
    });

    // ── 默认值 ──

    it('default_zoom_should_be_one', 0, () => {
      expect(cm.zoom).assertEqual(1.0);
    });

    it('default_offset_should_be_zero', 0, () => {
      expect(cm.offsetX).assertEqual(0);
      expect(cm.offsetY).assertEqual(0);
    });

    // ── 自定义构造 ──

    it('custom_initial_zoom', 0, () => {
      let c: CanvasManager = new CanvasManager(0.5, 2.0, 1.5);
      expect(c.zoom).assertEqual(1.5);
    });

    // ── 平移 ──

    it('pan_should_update_offsets', 0, () => {
      cm.pan(10, 20);
      expect(cm.offsetX).assertEqual(10);
      expect(cm.offsetY).assertEqual(20);
    });

    it('pan_should_accumulate', 0, () => {
      cm.pan(5, 5);
      cm.pan(-3, 7);
      expect(cm.offsetX).assertEqual(2);
      expect(cm.offsetY).assertEqual(12);
    });

    // ── 缩放 ──

    it('zoomAt_positive_delta_should_increase_zoom', 0, () => {
      cm.zoomAt(0, 0, 1);
      let result: boolean = cm.zoom > 1.0;
      expect(result).assertEqual(true);
    });

    it('zoomAt_negative_delta_should_decrease_zoom', 0, () => {
      cm.zoomAt(0, 0, -1);
      let result: boolean = cm.zoom < 1.0;
      expect(result).assertEqual(true);
    });

    it('zoomAt_should_clamp_to_min', 0, () => {
      cm = new CanvasManager(0.5, 5.0, 1.0);
      for (let i: number = 0; i < 50; i++) {
        cm.zoomAt(0, 0, -1);
      }
      let result: boolean = cm.zoom >= 0.5;
      expect(result).assertEqual(true);
    });

    it('zoomAt_should_clamp_to_max', 0, () => {
      cm = new CanvasManager(0.1, 2.0, 1.0);
      for (let i: number = 0; i < 50; i++) {
        cm.zoomAt(0, 0, 1);
      }
      let result: boolean = cm.zoom <= 2.0;
      expect(result).assertEqual(true);
    });

    // ── zoomTo ──

    it('zoomTo_should_set_exact_zoom', 0, () => {
      cm.zoomTo(100, 100, 2.0);
      expect(cm.zoom).assertEqual(2.0);
    });

    // ── 坐标转换 ──

    it('screenToCanvas_identity_should_passthrough', 0, () => {
      let pt: CanvasPoint = cm.screenToCanvas(50, 100);
      expect(pt.x).assertEqual(50);
      expect(pt.y).assertEqual(100);
    });

    it('screenToCanvas_with_offset', 0, () => {
      cm.pan(20, 30);
      let pt: CanvasPoint = cm.screenToCanvas(70, 80);
      expect(pt.x).assertEqual(50);
      expect(pt.y).assertEqual(50);
    });

    it('screen_to_canvas_roundtrip', 0, () => {
      cm.pan(15, 25);
      cm.zoomAt(0, 0, 2);
      for (let i: number = 0; i < 10; i++) {
        cm.zoomAt(0, 0, 1);
      }
      let orig: CanvasPoint = cm.screenToCanvas(100, 200);
      let back: ScreenPoint = cm.canvasToScreen(orig.x, orig.y);
      let dxOk: boolean = Math.abs(back.x - 100) < 0.1;
      let dyOk: boolean = Math.abs(back.y - 200) < 0.1;
      expect(dxOk).assertEqual(true);
      expect(dyOk).assertEqual(true);
    });

    // ── fitToView ──

    it('fitToView_should_center_content', 0, () => {
      cm.fitToView(400, 300, 800, 600, 0);
      expect(cm.zoom).assertEqual(2.0);
      expect(cm.offsetX).assertEqual(0);
      expect(cm.offsetY).assertEqual(0);
    });

    it('fitToView_with_padding', 0, () => {
      cm.fitToView(200, 100, 800, 600, 40);
      let cw: number = 200 * cm.zoom;
      let ch: number = 100 * cm.zoom;
      expect(cm.offsetX).assertEqual((800 - cw) / 2);
      expect(cm.offsetY).assertEqual((600 - ch) / 2);
    });

    // ── reset ──

    it('reset_should_restore_defaults', 0, () => {
      cm.pan(100, 200);
      cm.zoomAt(0, 0, 10);
      cm.reset();
      expect(cm.zoom).assertEqual(1.0);
      expect(cm.offsetX).assertEqual(0);
      expect(cm.offsetY).assertEqual(0);
    });

    // ── viewport state ──

    it('getViewport_setViewport_roundtrip', 0, () => {
      cm.pan(50, 60);
      cm.zoomTo(0, 0, 1.5);
      let state: ViewportState = cm.getViewport();
      cm.reset();
      cm.setViewport(state);
      expect(cm.offsetX).assertEqual(50);
      expect(cm.offsetY).assertEqual(60);
      expect(cm.zoom).assertEqual(1.5);
    });
  });
}
