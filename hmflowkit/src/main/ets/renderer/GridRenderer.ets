/**
 * Copyright (c) 2025 hm-flow-kit Contributors.
 * Licensed under the MIT License.
 *
 * Grid Renderer — 背景网格绘制器
 *
 * 在 Canvas 上绘制点阵或网格背景，辅助视觉定位。
 * 遵循四层架构约束：属于 Renderer 层，只读不写 Model。
 */

/**
 * 网格类型枚举
 */
export enum GridType {
  /** 点阵网格 — 在格点画小圆点 */
  DOT = 'dot',
  /** 线网格 — 画水平/垂直网格线 */
  LINE = 'line',
  /** 无网格 */
  NONE = 'none'
}

/**
 * 网格渲染配置
 *
 * 控制网格的类型、间距、颜色等参数。
 */
export class GridConfig {
  /** 网格类型，默认点阵 */
  gridType: GridType = GridType.DOT;
  /** 网格间距（像素），默认 20 */
  gridSize: number = 20;
  /** 网格主间隔倍数（每 N 格画一条强调线/大点），默认 5 */
  majorInterval: number = 5;
  /** 次要网格颜色 */
  minorColor: string = '#e0e0e0';
  /** 主要网格颜色 */
  majorColor: string = '#d0d0d0';
  /** 圆点半径（点阵模式用），默认 1 */
  dotRadius: number = 1;

  constructor(gridType: GridType = GridType.DOT,
    gridSize: number = 20,
    majorInterval: number = 5,
    minorColor: string = '#e0e0e0',
    majorColor: string = '#d0d0d0',
    dotRadius: number = 1) {
    this.gridType = gridType;
    this.gridSize = gridSize;
    this.majorInterval = majorInterval;
    this.minorColor = minorColor;
    this.majorColor = majorColor;
    this.dotRadius = dotRadius;
  }
}

/**
 * 网格渲染器
 *
 * 静态方法 render() 在给定 CanvasRenderingContext2D 上绘制背景网格。
 * 考虑视口偏移和缩放，保证网格始终对齐屏幕物理像素。
 */
export class GridRenderer {
  /**
   * 渲染背景网格
   *
   * @param ctx - Canvas 渲染上下文
   * @param width - 画布可视宽度（像素）
   * @param height - 画布可视高度（像素）
   * @param offsetX - 视口 X 偏移（逻辑像素）
   * @param offsetY - 视口 Y 偏移（逻辑像素）
   * @param zoom - 当前缩放比例
   * @param config - 网格配置，不传则使用默认值
   */
  public static render(ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    offsetX: number,
    offsetY: number,
    zoom: number,
    config: GridConfig = new GridConfig()): void {
    if (config.gridType === GridType.NONE) {
      return;
    }

    const gridSize: number = config.gridSize;
    const majorInterval: number = config.majorInterval;
    const actualGridSize: number = gridSize * zoom;

    // 防止网格间距太小导致性能问题
    if (actualGridSize < 4) {
      return;
    }

    // 计算可见区域的网格起始位置，保证网格对齐
    const startX: number = ((-offsetX) % actualGridSize + actualGridSize) % actualGridSize;
    const startY: number = ((-offsetY) % actualGridSize + actualGridSize) % actualGridSize;

    // 保存上下文状态
    ctx.save();

    if (config.gridType === GridType.DOT) {
      GridRenderer.renderDotGrid(ctx, width, height, startX, startY, actualGridSize, majorInterval, config);
    } else if (config.gridType === GridType.LINE) {
      GridRenderer.renderLineGrid(ctx, width, height, startX, startY, actualGridSize, majorInterval, config);
    }

    ctx.restore();
  }

  /**
   * 绘制点阵网格
   */
  // 可见点数量超过此阈值时跳过渲染，避免绘制调用过多导致帧率崩溃
  private static MAX_VISIBLE_DOTS: number = 5000;

  private static renderDotGrid(ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    startX: number,
    startY: number,
    actualGridSize: number,
    majorInterval: number,
    config: GridConfig): void {
    // 预估可见点数，超过阈值直接跳过（性能保护）
    let estCols: number = Math.ceil((width + actualGridSize - startX) / actualGridSize);
    let estRows: number = Math.ceil((height + actualGridSize - startY) / actualGridSize);
    if (estCols * estRows > GridRenderer.MAX_VISIBLE_DOTS) {
      return;
    }

    for (let y: number = startY; y < height + actualGridSize; y += actualGridSize) {
      for (let x: number = startX; x < width + actualGridSize; x += actualGridSize) {
        const colIndex: number = Math.round((x - startX) / actualGridSize);
        const rowIndex: number = Math.round((y - startY) / actualGridSize);
        const isMajor: boolean = (colIndex % majorInterval === 0) &&
          (rowIndex % majorInterval === 0);
        const color: string = isMajor ? config.majorColor : config.minorColor;
        const radius: number = isMajor ? config.dotRadius * 1.5 : config.dotRadius;

        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  /**
   * 绘制线网格
   */
  private static renderLineGrid(ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    startX: number,
    startY: number,
    actualGridSize: number,
    majorInterval: number,
    config: GridConfig): void {
    // 绘制垂直线
    for (let x: number = startX; x < width + actualGridSize; x += actualGridSize) {
      const colIndex: number = Math.round((x - startX) / actualGridSize);
      const isMajor: boolean = colIndex % majorInterval === 0;
      ctx.strokeStyle = isMajor ? config.majorColor : config.minorColor;
      ctx.lineWidth = isMajor ? 1 : 0.5;
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }

    // 绘制水平线
    for (let y: number = startY; y < height + actualGridSize; y += actualGridSize) {
      const rowIndex: number = Math.round((y - startY) / actualGridSize);
      const isMajor: boolean = rowIndex % majorInterval === 0;
      ctx.strokeStyle = isMajor ? config.majorColor : config.minorColor;
      ctx.lineWidth = isMajor ? 1 : 0.5;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }
  }
}