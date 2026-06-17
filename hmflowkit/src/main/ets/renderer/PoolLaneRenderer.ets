import { Pool, Lane, PoolBounds } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';

export class PoolLaneRenderer {
  static render(
    ctx: CanvasRenderingContext2D,
    pools: Pool[],
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    for (let i: number = 0; i < pools.length; i++) {
      PoolLaneRenderer.renderPool(ctx, pools[i], config, offsetX, offsetY, zoom);
    }
  }

  private static renderPool(
    ctx: CanvasRenderingContext2D,
    pool: Pool,
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    const x: number = pool.bounds.x * zoom + offsetX;
    const y: number = pool.bounds.y * zoom + offsetY;
    const w: number = pool.bounds.width * zoom;
    const h: number = pool.bounds.height * zoom;

    // Pool background
    ctx.fillStyle = config.poolFillColor;
    ctx.fillRect(x, y, w, h);

    // Pool border
    ctx.strokeStyle = config.poolStrokeColor;
    ctx.lineWidth = config.poolStrokeWidth * zoom;
    ctx.strokeRect(x, y, w, h);

    // Render lane backgrounds+borders (no headers yet)
    for (let i: number = 0; i < pool.lanes.length; i++) {
      let lane: Lane = pool.lanes[i];
      if (lane.bounds.y < y + h && lane.bounds.y + lane.bounds.height > y) {
        PoolLaneRenderer.renderLaneBg(ctx, lane, config, offsetX, offsetY, zoom);
      }
    }

    // Pool header background
    const poolHdrW: number = config.poolHeaderWidth * zoom;
    ctx.fillStyle = config.poolHeaderFillColor;
    if (pool.isHorizontal) {
      ctx.fillRect(x, y, poolHdrW, h);
    } else {
      ctx.fillRect(x, y, w, poolHdrW);
    }

    // Lane headers — drawn on top of pool header bg, indented 6px inside
    const indent: number = 6 * zoom;
    for (let i: number = 0; i < pool.lanes.length; i++) {
      let lane: Lane = pool.lanes[i];
      if (lane.bounds.y < y + h && lane.bounds.y + lane.bounds.height > y) {
        let lx: number = lane.bounds.x * zoom + offsetX + indent;
        let ly: number = lane.bounds.y * zoom + offsetY;
        let lw: number = lane.bounds.width * zoom - indent;
        let lh: number = lane.bounds.height * zoom;
        PoolLaneRenderer.renderLaneHeaderTree(ctx, lane, lx, ly, lw, lh, pool.isHorizontal, config, zoom, offsetX, offsetY);
      }
    }

    // Pool header text — on top of everything
    const fontSizeHdr: number = Math.max(11, Math.round(config.poolHeaderFontSize * zoom));
    ctx.fillStyle = config.poolHeaderTextColor;
    ctx.font = fontSizeHdr + 'px ' + config.fontFamily;
    if (pool.isHorizontal) {
      PoolLaneRenderer.fillVerticalText(ctx, pool.name, x + poolHdrW / 2, y + h / 2, fontSizeHdr);
    } else {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(pool.name, x + w / 2, y + poolHdrW / 2);
    }
  }

  // Render lane background + border only (no header). Recursive for child lanes.
  private static renderLaneBg(
    ctx: CanvasRenderingContext2D,
    lane: Lane,
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    const laneX: number = lane.bounds.x * zoom + offsetX;
    const laneY: number = lane.bounds.y * zoom + offsetY;
    const laneW: number = lane.bounds.width * zoom;
    const laneH: number = lane.bounds.height * zoom;

    ctx.fillStyle = config.laneFillColor;
    ctx.fillRect(laneX, laneY, laneW, laneH);
    ctx.strokeStyle = config.laneStrokeColor;
    ctx.lineWidth = config.laneStrokeWidth * zoom;
    ctx.strokeRect(laneX, laneY, laneW, laneH);

    for (let i: number = 0; i < lane.childLanes.length; i++) {
      PoolLaneRenderer.renderLaneBg(ctx, lane.childLanes[i], config, offsetX, offsetY, zoom);
    }
  }

  private static renderLaneHeader(
    ctx: CanvasRenderingContext2D,
    lane: Lane,
    x: number,
    y: number,
    w: number,
    h: number,
    isHorizontal: boolean,
    config: RenderConfig,
    zoom: number
  ): void {
    const headerW: number = config.laneHeaderWidth * zoom;
    const fontSize: number = Math.max(10, Math.round(config.laneHeaderFontSize * zoom));

    // Header background
    ctx.fillStyle = config.laneHeaderFillColor;
    if (isHorizontal) {
      ctx.fillRect(x, y, headerW, h);
    } else {
      ctx.fillRect(x, y, w, headerW);
    }

    // Header text
    ctx.fillStyle = config.laneHeaderTextColor;
    ctx.font = fontSize + 'px ' + config.fontFamily;

    if (isHorizontal) {
      PoolLaneRenderer.fillVerticalText(ctx, lane.name, x + headerW / 2, y + h / 2, fontSize);
    } else {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(lane.name, x + w / 2, y + headerW / 2);
    }
  }

  // Render lane header tree recursively (for nested child lanes)
  private static renderLaneHeaderTree(
    ctx: CanvasRenderingContext2D,
    lane: Lane,
    x: number,
    y: number,
    w: number,
    h: number,
    isHorizontal: boolean,
    config: RenderConfig,
    zoom: number,
    offsetX: number,
    offsetY: number
  ): void {
    PoolLaneRenderer.renderLaneHeader(ctx, lane, x, y, w, h, isHorizontal, config, zoom);
    const indent: number = 6 * zoom;
    for (let i: number = 0; i < lane.childLanes.length; i++) {
      let child: Lane = lane.childLanes[i];
      let cx: number = child.bounds.x * zoom + offsetX + indent;
      let cy: number = child.bounds.y * zoom + offsetY;
      let cw: number = child.bounds.width * zoom - indent;
      let ch: number = child.bounds.height * zoom;
      PoolLaneRenderer.renderLaneHeaderTree(ctx, child, cx, cy, cw, ch, isHorizontal, config, zoom, offsetX, offsetY);
    }
  }

  // Draw text vertically, one character per line, centered
  private static fillVerticalText(
    ctx: CanvasRenderingContext2D,
    text: string,
    centerX: number,
    centerY: number,
    fontSize: number
  ): void {
    const len: number = text.length;
    if (len === 0) {
      return;
    }

    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    const lineH: number = fontSize * 1.2;
    const totalH: number = (len - 1) * lineH;
    let curY: number = centerY - totalH / 2;

    for (let i: number = 0; i < len; i++) {
      ctx.fillText(text.charAt(i), centerX, curY);
      curY = curY + lineH;
    }
  }
}
