// hmflowkit/src/main/ets/approval/StatusOverlayRenderer.ets
import {
  NodeStatus, NodeStatusMap, EdgeTrail, StatusColor,
  ApprovalOverlayConfig, ApprovalStatusColorMap, ApprovalStatus,
  NodeDrawRect, OnNodeDecorator, BadgePosition
} from './ApprovalTypes';
import { ApprovalColorPresets, PresetId, getPresetById } from './ApprovalPresets';
import { GraphNode, GraphEdge } from '../model/GraphModel';
import { RenderConfig } from '../renderer/RenderConfig';
import { ShapeConfig, PerimeterKind } from '../adapter/ShapeConfig';

// Fallback color storage (ArkTS forbids Record<K,V> object literals)
class FallbackColorStore {
  approved: StatusColor;
  rejected: StatusColor;
  current: StatusColor;
  skipped: StatusColor;
  transferred: StatusColor;
  pending: StatusColor;

  constructor() {
    this.approved = new StatusColor('#E8F5E9', '#4CAF50', 0, '✓');
    this.rejected = new StatusColor('#FFEBEE', '#F44336', 0, '✗');
    this.current = new StatusColor('#E3F2FD', '#2196F3', 0, '●');
    this.skipped = new StatusColor('#F5F5F5', '#9E9E9E', 0, '—');
    this.transferred = new StatusColor('#FFF3E0', '#FF9800', 0, '↗');
    this.pending = new StatusColor('#FFFFFF', '#BDBDBD', 0, '');
  }

  getByStatus(s: string): StatusColor | undefined {
    if (s === 'approved') return this.approved;
    if (s === 'rejected') return this.rejected;
    if (s === 'current') return this.current;
    if (s === 'skipped') return this.skipped;
    if (s === 'transferred') return this.transferred;
    if (s === 'pending') return this.pending;
    return undefined;
  }
}

export class StatusOverlayRenderer {

  // ═══ 内部默认回退色（保证无配置时也能显示） ═══
  private static _fallbackColors: FallbackColorStore = new FallbackColorStore();

  /**
   * 查表取色，按优先级：user config → preset → fallback
   */
  static resolveColor(
    status: ApprovalStatus,
    config: ApprovalOverlayConfig | undefined,
    presetId: PresetId | undefined
  ): StatusColor {
    // 1. 用户自定义色
    if (config !== undefined && config.statusColors !== undefined) {
      let userColor: StatusColor | null = config.statusColors.getByStatus(status);
      if (userColor !== null) {
        return userColor;
      }
    }
    // 2. 预设
    if (presetId !== undefined) {
      let preset: ApprovalStatusColorMap | undefined = getPresetById(presetId);
      if (preset !== undefined) {
        let pc: StatusColor | null = preset.getByStatus(status);
        if (pc !== null) {
          return pc;
        }
      }
    }
    // 3. 回退
    let fb: StatusColor | undefined = StatusOverlayRenderer._fallbackColors.getByStatus(status);
    if (fb !== undefined) {
      return fb;
    }
    return new StatusColor('#FFFFFF', '#BDBDBD', 0, '');
  }

  /**
   * 在标准节点渲染后调用，绘制审批状态覆盖层。
   * 使用内边框 + 角标，不填充节点底色。
   *
   * @param pulseAlpha  脉冲透明度（0=不透明, 1=完全透明），仅 current 节点使用
   */
  static renderNodeStatus(
    ctx: CanvasRenderingContext2D,
    node: GraphNode,
    statusMap: NodeStatusMap | undefined,
    config: ApprovalOverlayConfig | undefined,
    presetId: PresetId | undefined,
    x: number, y: number, w: number, h: number,
    zoom: number,
    activeModel: GraphNode,
    pulseAlpha: number
  ): void {
    if (statusMap === undefined) {
      return;
    }
    let status: NodeStatus | null = statusMap.get(node.id);
    if (status === null) {
      return;
    }

    let color: StatusColor = StatusOverlayRenderer.resolveColor(
      status.status, config, presetId);

    // ── 内边框（形状自适应：圆形 / 菱形 / 圆角矩形）──
    let kind: PerimeterKind = ShapeConfig.perimeterKind(node.type);
    let inset: number = 2.5 * zoom;
    let lw: number = 3 * zoom;
    ctx.save();
    if (status.status === 'current' && pulseAlpha > 0) {
      ctx.globalAlpha = 0.3 + 0.7 * pulseAlpha;
    }
    ctx.strokeStyle = color.strokeColor;
    ctx.lineWidth = lw;

    if (kind === PerimeterKind.ELLIPSE) {
      ctx.beginPath();
      ctx.ellipse(x + w / 2, y + h / 2, w / 2 - inset, h / 2 - inset, 0, 0, 2 * Math.PI);
      ctx.stroke();
    } else {
      let cr: number = 0.133 * Math.min(w, h);
      if (cr > inset) cr = cr - inset;
      else cr = 0;
      let ix: number = x + inset;
      let iy: number = y + inset;
      let iw: number = w - inset * 2;
      let ih: number = h - inset * 2;
      ctx.beginPath();
      ctx.moveTo(ix + cr, iy);
      ctx.lineTo(ix + iw - cr, iy);
      ctx.arcTo(ix + iw, iy, ix + iw, iy + cr, cr);
      ctx.lineTo(ix + iw, iy + ih - cr);
      ctx.arcTo(ix + iw, iy + ih, ix + iw - cr, iy + ih, cr);
      ctx.lineTo(ix + cr, iy + ih);
      ctx.arcTo(ix, iy + ih, ix, iy + ih - cr, cr);
      ctx.lineTo(ix, iy + cr);
      ctx.arcTo(ix, iy, ix + cr, iy, cr);
      ctx.closePath();
      ctx.stroke();
    }
    ctx.globalAlpha = 1.0;
    ctx.restore();

    // ── Badge 角标（贴合内边框角）──
    if (color.badgeText.length > 0) {
      StatusOverlayRenderer._drawBadge(
        ctx, color, x, y, w, h, zoom,
        config !== undefined ? config.badgePosition : 'topRight',
        inset
      );
    }

    // ── 多实例进度标记 ──
    if (status.multiInstance !== null) {
      StatusOverlayRenderer._drawMultiInstanceProgress(
        ctx, status, color, x, y, w, h, zoom);
    }
  }

  /**
   * 在标准边渲染后调用，绘制流转路径染色。
   */
  static renderEdgeTrail(
    ctx: CanvasRenderingContext2D,
    edge: GraphEdge,
    trails: EdgeTrail[] | undefined,
    points: Array<number[]>,
    zoom: number,
    config: RenderConfig
  ): void {
    if (trails === undefined || trails.length === 0) {
      return;
    }
    let trail: EdgeTrail | null = null;
    for (let i: number = 0; i < trails.length; i++) {
      if (trails[i].edgeId === edge.id) {
        trail = trails[i];
        break;
      }
    }
    if (trail === null) {
      return;
    }

    ctx.save();
    let lw: number = config.edgeStrokeWidth * zoom;

    if (trail.kind === 'active') {
      ctx.strokeStyle = '#22C55E';
      ctx.lineWidth = lw * 1.5;
      // 重绘路径
      ctx.beginPath();
      ctx.moveTo(points[0][0], points[0][1]);
      for (let i: number = 1; i < points.length; i++) {
        ctx.lineTo(points[i][0], points[i][1]);
      }
      ctx.stroke();
    } else if (trail.kind === 'rejected') {
      ctx.strokeStyle = '#EF4444';
      ctx.lineWidth = lw;
      ctx.setLineDash([6 * zoom, 4 * zoom]);
      ctx.beginPath();
      ctx.moveTo(points[0][0], points[0][1]);
      for (let i: number = 1; i < points.length; i++) {
        ctx.lineTo(points[i][0], points[i][1]);
      }
      ctx.stroke();
      ctx.setLineDash([]);
      // 标签
      if (trail.label.length > 0 && points.length >= 2) {
        let mx: number = (points[0][0] + points[points.length - 1][0]) / 2;
        let my: number = (points[0][1] + points[points.length - 1][1]) / 2;
        let fs: number = Math.max(9, Math.round(config.fontSize * 0.85 * zoom));
        ctx.font = fs + 'px ' + config.fontFamily;
        ctx.fillStyle = '#EF4444';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'bottom';
        ctx.fillText(trail.label, mx, my - 6 * zoom);
      }
    } else if (trail.kind === 'historical') {
      ctx.strokeStyle = '#D0D0D0';
      ctx.lineWidth = lw * 0.6;
      ctx.beginPath();
      ctx.moveTo(points[0][0], points[0][1]);
      for (let i: number = 1; i < points.length; i++) {
        ctx.lineTo(points[i][0], points[i][1]);
      }
      ctx.stroke();
    } else if (trail.kind === 'skipped') {
      ctx.strokeStyle = '#BDBDBD';
      ctx.lineWidth = lw;
      ctx.setLineDash([3 * zoom, 3 * zoom]);
      ctx.beginPath();
      ctx.moveTo(points[0][0], points[0][1]);
      for (let i: number = 1; i < points.length; i++) {
        ctx.lineTo(points[i][0], points[i][1]);
      }
      ctx.stroke();
      ctx.setLineDash([]);
    }

    ctx.restore();
  }

  // ── Private helpers ──

  private static _drawBadge(
    ctx: CanvasRenderingContext2D,
    color: StatusColor,
    x: number, y: number, w: number, h: number,
    zoom: number,
    position: BadgePosition,
    borderInset: number
  ): void {
    let r: number = 7 * zoom;
    // shift inward so ~1/4 of badge circle overlaps border corner
    let shift: number = r * 0.4;
    let cx: number;
    let cy: number;

    if (position === 'topRight') {
      cx = x + w - borderInset - shift;
      cy = y + borderInset + shift;
    } else if (position === 'topLeft') {
      cx = x + borderInset + shift;
      cy = y + borderInset + shift;
    } else {
      // bottomRight
      cx = x + w - borderInset - shift;
      cy = y + h - borderInset - shift;
    }

    ctx.save();
    ctx.fillStyle = color.strokeColor;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#FFFFFF';
    let fs: number = Math.max(7, Math.round(9 * zoom));
    ctx.font = 'bold ' + fs + 'px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(color.badgeText, cx, cy);
    ctx.restore();
  }

  private static _drawMultiInstanceProgress(
    ctx: CanvasRenderingContext2D,
    status: NodeStatus,
    color: StatusColor,
    x: number, y: number, w: number, h: number,
    zoom: number
  ): void {
    if (status.multiInstance === null) {
      return;
    }
    let mi = status.multiInstance;
    let text: string = mi.completedCount + '/' + mi.totalCount;
    let cx: number = x + w / 2;
    let by: number = y + h + 4 * zoom;
    let fs: number = Math.max(8, Math.round(10 * zoom));

    ctx.save();
    ctx.font = fs + 'px sans-serif';
    ctx.fillStyle = color.strokeColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText(text, cx, by);
    // 下划线暗示可交互
    let tw: number = ctx.measureText(text).width;
    ctx.strokeStyle = color.strokeColor;
    ctx.lineWidth = Math.max(0.7, 0.8 * zoom);
    ctx.beginPath();
    ctx.moveTo(cx - tw / 2, by + fs + 2 * zoom);
    ctx.lineTo(cx + tw / 2, by + fs + 2 * zoom);
    ctx.stroke();
    ctx.restore();
  }
}
