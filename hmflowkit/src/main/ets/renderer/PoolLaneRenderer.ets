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

    // Render lanes inside pool (background layer)
    for (let i: number = 0; i < pool.lanes.length; i++) {
      PoolLaneRenderer.renderLane(ctx, pool.lanes[i], pool, config, offsetX, offsetY, zoom);
    }

    // Pool header — rendered AFTER lanes so it stays on top
    PoolLaneRenderer.renderPoolHeader(ctx, pool, x, y, w, h, config, zoom);
  }

  private static renderPoolHeader(
    ctx: CanvasRenderingContext2D,
    pool: Pool,
    x: number,
    y: number,
    w: number,
    h: number,
    config: RenderConfig,
    zoom: number
  ): void {
    const headerW: number = config.poolHeaderWidth * zoom;
    const fontSize: number = Math.max(11, Math.round(config.poolHeaderFontSize * zoom));

    // Header background
    ctx.fillStyle = config.poolHeaderFillColor;
    if (pool.isHorizontal) {
      ctx.fillRect(x, y, headerW, h);
    } else {
      ctx.fillRect(x, y, w, headerW);
    }

    // Header text
    ctx.fillStyle = config.poolHeaderTextColor;
    ctx.font = fontSize + 'px ' + config.fontFamily;

    if (pool.isHorizontal) {
      PoolLaneRenderer.fillVerticalText(ctx, pool.name, x + headerW / 2, y + h / 2, fontSize);
    } else {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(pool.name, x + w / 2, y + headerW / 2);
    }
  }

  private static renderLane(
    ctx: CanvasRenderingContext2D,
    lane: Lane,
    parentPool: Pool,
    config: RenderConfig,
    offsetX: number,
    offsetY: number,
    zoom: number
  ): void {
    const laneX: number = lane.bounds.x * zoom + offsetX;
    const laneY: number = lane.bounds.y * zoom + offsetY;
    const laneW: number = lane.bounds.width * zoom;
    const laneH: number = lane.bounds.height * zoom;

    // Lane background
    ctx.fillStyle = config.laneFillColor;
    ctx.fillRect(laneX, laneY, laneW, laneH);

    // Lane border
    ctx.strokeStyle = config.laneStrokeColor;
    ctx.lineWidth = config.laneStrokeWidth * zoom;
    ctx.strokeRect(laneX, laneY, laneW, laneH);

    // Lane header
    PoolLaneRenderer.renderLaneHeader(ctx, lane, laneX, laneY, laneW, laneH, parentPool.isHorizontal, config, zoom);

    // Child lanes recursively
    for (let i: number = 0; i < lane.childLanes.length; i++) {
      PoolLaneRenderer.renderLane(ctx, lane.childLanes[i], parentPool, config, offsetX, offsetY, zoom);
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
