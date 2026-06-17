import { Pool, Lane, PoolBounds } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';

export class PoolLaneRenderer {
  /**
   * Render all pools and their lanes as background layers.
   * Must be called BEFORE nodes and edges are rendered.
   */
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

    ctx.save();

    // Pool background
    ctx.fillStyle = config.poolFillColor;
    ctx.fillRect(x, y, w, h);

    // Pool border
    ctx.strokeStyle = config.poolStrokeColor;
    ctx.lineWidth = config.poolStrokeWidth * zoom;
    ctx.strokeRect(x, y, w, h);

    // Pool header
    PoolLaneRenderer.renderPoolHeader(ctx, pool, x, y, w, h, config, zoom);

    // Render lanes inside pool
    for (let i: number = 0; i < pool.lanes.length; i++) {
      PoolLaneRenderer.renderLane(ctx, pool.lanes[i], pool, config, offsetX, offsetY, zoom);
    }

    ctx.restore();
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

    ctx.save();

    if (pool.isHorizontal) {
      // Header on left side
      ctx.fillStyle = config.poolHeaderFillColor;
      ctx.fillRect(x, y, headerW, h);

      // Pool name rotated -90 degrees
      ctx.save();
      ctx.translate(x + headerW / 2, y + h / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.fillStyle = config.poolHeaderTextColor;
      ctx.font = Math.max(11, Math.round(config.poolHeaderFontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(pool.name, 0, 0);
      ctx.restore();
    } else {
      // Header on top
      ctx.fillStyle = config.poolHeaderFillColor;
      ctx.fillRect(x, y, w, headerW);

      // Pool name horizontal
      ctx.fillStyle = config.poolHeaderTextColor;
      ctx.font = Math.max(11, Math.round(config.poolHeaderFontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(pool.name, x + w / 2, y + headerW / 2);
    }

    ctx.restore();
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

    ctx.save();

    // Lane background
    ctx.fillStyle = config.laneFillColor;
    ctx.fillRect(laneX, laneY, laneW, laneH);

    // Lane border
    ctx.strokeStyle = config.laneStrokeColor;
    ctx.lineWidth = config.laneStrokeWidth * zoom;
    ctx.strokeRect(laneX, laneY, laneW, laneH);

    // Lane header
    PoolLaneRenderer.renderLaneHeader(ctx, lane, laneX, laneY, laneW, laneH, parentPool.isHorizontal, config, zoom);

    // Render child lanes recursively
    for (let i: number = 0; i < lane.childLanes.length; i++) {
      PoolLaneRenderer.renderLane(ctx, lane.childLanes[i], parentPool, config, offsetX, offsetY, zoom);
    }

    ctx.restore();
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

    ctx.save();

    if (isHorizontal) {
      // Header on left side
      ctx.fillStyle = config.laneHeaderFillColor;
      ctx.fillRect(x, y, headerW, h);

      // Lane name rotated
      ctx.save();
      ctx.translate(x + headerW / 2, y + h / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.fillStyle = config.laneHeaderTextColor;
      ctx.font = Math.max(10, Math.round(config.laneHeaderFontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(lane.name, 0, 0);
      ctx.restore();
    } else {
      // Header on top
      ctx.fillStyle = config.laneHeaderFillColor;
      ctx.fillRect(x, y, w, headerW);

      // Lane name horizontal
      ctx.fillStyle = config.laneHeaderTextColor;
      ctx.font = Math.max(10, Math.round(config.laneHeaderFontSize * zoom)) + 'px ' + config.fontFamily;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(lane.name, x + w / 2, y + headerW / 2);
    }

    ctx.restore();
  }
}
