/**
 * CanvasManager - 画布管理（缩放、平移、视口变换）
 *
 * 职责：
 * - 管理视口变换状态（zoom, offsetX, offsetY）
 * - 提供坐标转换方法（screen ↔ canvas）
 * - 应用变换到 CanvasRenderingContext2D
 * - 管理动画参数（缩放到指定节点等，预留）
 *
 * 架构约束：
 * - 只负责视口变换，不接触 GraphModel
 * - 不直接处理手势事件（由 Interaction 层调用）
 * - 坐标转换方法需同时返回 x,y（ArkTS 不支持解构，使用 class）
 */

/**
 * 屏幕坐标点
 */
export class ScreenPoint {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

/**
 * 画布坐标点
 */
export class CanvasPoint {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

/**
 * 视口状态快照
 */
export class ViewportState {
  zoom: number;
  offsetX: number;
  offsetY: number;

  constructor(zoom: number, offsetX: number, offsetY: number) {
    this.zoom = zoom;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
  }
}

/**
 * 画布管理器
 *
 * 管理视口变换，提供坐标系统转换。
 * 不持有 CanvasRenderingContext2D 引用，由调用方传入。
 */
export class CanvasManager {
  /**
   * 缩放系数
   */
  private _zoom: number = 1.0;

  /**
   * X 轴偏移（画布原点在屏幕上的位置）
   */
  private _offsetX: number = 0;

  /**
   * Y 轴偏移（画布原点在屏幕上的位置）
   */
  private _offsetY: number = 0;

  /**
   * 旋转步数（0=0°, 1=90°, 2=180°, 3=270°）
   */
  private _rotationTurns: number = 0;

  /**
   * 画布宽度（用于旋转中心计算）
   */
  private _canvasWidth: number = 0;

  /**
   * 画布高度（用于旋转中心计算）
   */
  private _canvasHeight: number = 0;

  /**
   * 最小缩放值
   */
  private _minZoom: number;

  /**
   * 最大缩放值
   */
  private _maxZoom: number;

  /**
   * 缩放步进系数（每次滚轮缩放的比例变化因子）
   */
  private readonly _zoomStep: number = 0.1;

  /**
   * 缓动动画相关（预留）
   */
  // private _animationTarget: ViewportState | null = null;
  // private _animationStart: ViewportState | null = null;
  // private _animationDuration: number = 0;
  // private _animationElapsed: number = 0;

  constructor(minZoom?: number, maxZoom?: number, initialZoom?: number) {
    this._minZoom = (minZoom !== undefined) ? minZoom : 0.1;
    this._maxZoom = (maxZoom !== undefined) ? maxZoom : 5.0;
    if (initialZoom !== undefined) {
      this._zoom = initialZoom;
    }
  }

  /**
   * 获取当前缩放值
   */
  public get zoom(): number {
    return this._zoom;
  }

  /**
   * 获取当前 X 偏移
   */
  public get offsetX(): number {
    return this._offsetX;
  }

  /**
   * 获取当前 Y 偏移
   */
  public get offsetY(): number {
    return this._offsetY;
  }

  /**
   * 获取当前旋转步数（0=0°, 1=90°, 2=180°, 3=270°）
   */
  public get rotationTurns(): number {
    return this._rotationTurns;
  }

  /**
   * 获取当前画布宽度（屏幕像素）
   */
  public get canvasWidth(): number {
    return this._canvasWidth;
  }

  /**
   * 获取当前画布高度（屏幕像素）
   */
  public get canvasHeight(): number {
    return this._canvasHeight;
  }

  /**
   * 设置画布尺寸（旋转中心计算需要）
   *
   * @param w - 画布宽度（屏幕像素）
   * @param h - 画布高度（屏幕像素）
   */
  public setCanvasSize(w: number, h: number): void {
    this._canvasWidth = w;
    this._canvasHeight = h;
  }

  /**
   * 获取当前视口状态
   */
  public getViewport(): ViewportState {
    return new ViewportState(this._zoom, this._offsetX, this._offsetY);
  }

  /**
   * 应用变换到 Canvas 上下文
   *
   * 变换链（Canvas 2D 右乘）：T(offset) * S(zoom) * T(cx,cy) * R(angle) * T(-cx,-cy)
   * 效果：先绕画布中心旋转 → 缩放 → 平移
   * angle=0 时退化为 T(offset) * S(zoom)，与当前行为完全一致
   *
   * @param ctx - Canvas 渲染上下文
   */
  public applyTransform(ctx: CanvasRenderingContext2D): void {
    let cx: number = this._canvasWidth > 0 ? this._canvasWidth / 2 : 0;
    let cy: number = this._canvasHeight > 0 ? this._canvasHeight / 2 : 0;
    let angle: number = this._rotationTurns * Math.PI / 2;

    ctx.setTransform(1.0, 0, 0, 1.0, 0, 0);
    // 旋转绕画布中心（Canvas 2D 右乘，先追加的在后执行）
    ctx.translate(cx, cy);
    ctx.rotate(angle);
    ctx.translate(-cx, -cy);
    // zoom + pan
    ctx.translate(this._offsetX, this._offsetY);
    ctx.scale(this._zoom, this._zoom);
  }

  /**
   * 重置视口（缩放 1.0，偏移归零，旋转归零）
   */
  public reset(): void {
    this._zoom = 1.0;
    this._offsetX = 0;
    this._offsetY = 0;
    this._rotationTurns = 0;
  }

  /**
   * 缩放（以某一点为中心）
   *
   * @param cx - 缩放中心 X（屏幕坐标）
   * @param cy - 缩放中心 Y（屏幕坐标）
   * @param delta - 缩放方向（1: 放大, -1: 缩小, >0: 放大, <0: 缩小）
   *
   * 旋转后 offset 位于旋转变换内侧，需将屏幕中心映射到旋转前空间：
   *   u = R^{-1} * (center - canvasCenter) + canvasCenter
   *   newOffset = u - (u - oldOffset) * newZoom / oldZoom
   */
  public zoomAt(cx: number, cy: number, delta: number): void {
    const oldZoom: number = this._zoom;
    let newZoom: number;

    if (delta > 0) {
      newZoom = oldZoom * (1 + this._zoomStep);
    } else {
      newZoom = oldZoom * (1 - this._zoomStep);
    }

    // 钳制到有效范围
    newZoom = Math.max(this._minZoom, Math.min(this._maxZoom, newZoom));

    // 如果缩放值没有变化，跳过
    if (Math.abs(newZoom - oldZoom) < 0.001) {
      return;
    }

    let angle: number = this._rotationTurns * Math.PI / 2;
    let ccx: number = this._canvasWidth > 0 ? this._canvasWidth / 2 : 0;
    let ccy: number = this._canvasHeight > 0 ? this._canvasHeight / 2 : 0;
    // u = R^{-1} * (screenCenter - canvasCenter) + canvasCenter
    let cos: number = Math.cos(angle);
    let sin: number = Math.sin(angle);
    let rx: number = cos * (cx - ccx) + sin * (cy - ccy);
    let ry: number = -sin * (cx - ccx) + cos * (cy - ccy);
    let ux: number = rx + ccx;
    let uy: number = ry + ccy;

    this._offsetX = ux - (ux - this._offsetX) * (newZoom / oldZoom);
    this._offsetY = uy - (uy - this._offsetY) * (newZoom / oldZoom);

    this._zoom = newZoom;
  }

  /**
   * 缩放到指定缩放值（以某一点为中心）
   *
   * @param cx - 缩放中心 X（屏幕坐标）
   * @param cy - 缩放中心 Y（屏幕坐标）
   * @param targetZoom - 目标缩放值
   */
  public zoomTo(cx: number, cy: number, targetZoom: number): void {
    const oldZoom: number = this._zoom;
    let newZoom: number = targetZoom;

    // 钳制到有效范围
    newZoom = Math.max(this._minZoom, Math.min(this._maxZoom, newZoom));

    if (Math.abs(newZoom - oldZoom) < 0.001) {
      return;
    }

    let angle: number = this._rotationTurns * Math.PI / 2;
    let ccx: number = this._canvasWidth > 0 ? this._canvasWidth / 2 : 0;
    let ccy: number = this._canvasHeight > 0 ? this._canvasHeight / 2 : 0;
    let cos: number = Math.cos(angle);
    let sin: number = Math.sin(angle);
    let rx: number = cos * (cx - ccx) + sin * (cy - ccy);
    let ry: number = -sin * (cx - ccx) + cos * (cy - ccy);
    let ux: number = rx + ccx;
    let uy: number = ry + ccy;

    this._offsetX = ux - (ux - this._offsetX) * (newZoom / oldZoom);
    this._offsetY = uy - (uy - this._offsetY) * (newZoom / oldZoom);

    this._zoom = newZoom;
  }

  /**
   * 平移视口
   *
   * 屏幕空间位移需逆旋转为 offset 空间位移：
   *   delta_screen = R(angle) * delta_offset
   *   代入 delta_offset = R(-angle) * delta_screen
   * rotation=0 时退化为 offset += (dx, dy)
   *
   * @param dx - X 方向位移（屏幕像素）
   * @param dy - Y 方向位移（屏幕像素）
   */
  public pan(dx: number, dy: number): void {
    let angle: number = this._rotationTurns * Math.PI / 2;
    let cos: number = Math.cos(angle);
    let sin: number = Math.sin(angle);
    this._offsetX += dx * cos + dy * sin;
    this._offsetY += -dx * sin + dy * cos;
  }

  /**
   * 屏幕坐标转换为画布坐标
   *
   * 变换链: screen = R * (zoom * canvas + offset - center) + center
   * 逆推: v = R^{-1} * (screen - center) + center
   *       canvas = (v - offset) / zoom
   * angle=0 时 v = screen，退化为 p = (screen - offset) / zoom
   *
   * @param sx - 屏幕 X
   * @param sy - 屏幕 Y
   * @returns 画布坐标
   */
  public screenToCanvas(sx: number, sy: number): CanvasPoint {
    let angle: number = this._rotationTurns * Math.PI / 2;
    let ccx: number = this._canvasWidth > 0 ? this._canvasWidth / 2 : 0;
    let ccy: number = this._canvasHeight > 0 ? this._canvasHeight / 2 : 0;

    // R^{-1} * (screen - center)
    let cos: number = Math.cos(angle);
    let sin: number = Math.sin(angle);
    let rx: number = cos * (sx - ccx) + sin * (sy - ccy);
    let ry: number = -sin * (sx - ccx) + cos * (sy - ccy);
    // v = rotated + center
    let vx: number = rx + ccx;
    let vy: number = ry + ccy;
    // canvas = (v - offset) / zoom
    return new CanvasPoint((vx - this._offsetX) / this._zoom, (vy - this._offsetY) / this._zoom);
  }

  /**
   * 画布坐标转换为屏幕坐标
   *
   * 变换链: v = zoom * canvas + offset
   *         screen = R * (v - center) + center
   * angle=0 时退化为 screen = zoom * canvas + offset
   *
   * @param cx - 画布 X
   * @param cy - 画布 Y
   * @returns 屏幕坐标
   */
  public canvasToScreen(cx: number, cy: number): ScreenPoint {
    let angle: number = this._rotationTurns * Math.PI / 2;
    let ccx: number = this._canvasWidth > 0 ? this._canvasWidth / 2 : 0;
    let ccy: number = this._canvasHeight > 0 ? this._canvasHeight / 2 : 0;

    // v = zoom * canvas + offset
    let vx: number = this._zoom * cx + this._offsetX;
    let vy: number = this._zoom * cy + this._offsetY;
    // screen = R * (v - center) + center
    let cos: number = Math.cos(angle);
    let sin: number = Math.sin(angle);
    let rx: number = cos * (vx - ccx) - sin * (vy - ccy);
    let ry: number = sin * (vx - ccx) + cos * (vy - ccy);
    return new ScreenPoint(rx + ccx, ry + ccy);
  }

  /**
   * 设置视口状态
   *
   * @param state - 视口状态快照
   */
  public setViewport(state: ViewportState): void {
    this._zoom = state.zoom;
    this._offsetX = state.offsetX;
    this._offsetY = state.offsetY;
  }

  /**
   * 设置缩放范围
   *
   * @param min - 最小缩放值
   * @param max - 最大缩放值
   */
  public setZoomRange(min: number, max: number): void {
    this._minZoom = min;
    this._maxZoom = max;

    // 如果当前缩放值超出新范围，钳制到边界
    if (this._zoom < this._minZoom) {
      this._zoom = this._minZoom;
    }
    if (this._zoom > this._maxZoom) {
      this._zoom = this._maxZoom;
    }
  }

  /**
   * 顺时针旋转 90°
   */
  public rotateClockwise(): void {
    this._rotationTurns = (this._rotationTurns + 1) % 4;
  }

  /**
   * 逆时针旋转 90°
   */
  public rotateCounterClockwise(): void {
    this._rotationTurns = (this._rotationTurns + 3) % 4;
  }

  /**
   * 放大（以画布中心为缩放中心）
   *
   * @param canvasWidth - 画布宽度（屏幕像素）
   * @param canvasHeight - 画布高度（屏幕像素）
   */
  public zoomIn(canvasWidth: number, canvasHeight: number): void {
    this.zoomAt(canvasWidth / 2, canvasHeight / 2, 1);
  }

  /**
   * 缩小（以画布中心为缩放中心）
   *
   * @param canvasWidth - 画布宽度（屏幕像素）
   * @param canvasHeight - 画布高度（屏幕像素）
   */
  public zoomOut(canvasWidth: number, canvasHeight: number): void {
    this.zoomAt(canvasWidth / 2, canvasHeight / 2, -1);
  }

  /**
   * 缩放到适应所有内容
   *
   * 计算合适的 zoom 和 offset 使得内容在画布中居中显示
   * 预留方法，需要配合 Renderer 层计算内容边界
   *
   * @param contentWidth - 内容宽度（画布坐标）
   * @param contentHeight - 内容高度（画布坐标）
   * @param canvasWidth - 画布宽度（屏幕像素）
   * @param canvasHeight - 画布高度（屏幕像素）
   * @param padding - 内边距（屏幕像素）
   */
  public fitToView(contentWidth: number, contentHeight: number,
    canvasWidth: number, canvasHeight: number, padding?: number): void {
    const pad: number = (padding !== undefined) ? padding : 40;

    if (contentWidth <= 0 || contentHeight <= 0) {
      return;
    }

    // 旋转 90°/270° 时 content 宽高视觉互换
    let effW: number = (this._rotationTurns % 2 === 1) ? contentHeight : contentWidth;
    let effH: number = (this._rotationTurns % 2 === 1) ? contentWidth : contentHeight;

    const availableWidth: number = canvasWidth - pad * 2;
    const availableHeight: number = canvasHeight - pad * 2;

    if (availableWidth <= 0 || availableHeight <= 0) {
      return;
    }

    const scaleX: number = availableWidth / effW;
    const scaleY: number = availableHeight / effH;
    let newZoom: number = Math.min(scaleX, scaleY);

    // 钳制到缩放范围
    newZoom = Math.max(this._minZoom, Math.min(this._maxZoom, newZoom));

    // 居中
    const contentScreenWidth: number = effW * newZoom;
    const contentScreenHeight: number = effH * newZoom;

    this._offsetX = (canvasWidth - contentScreenWidth) / 2;
    this._offsetY = (canvasHeight - contentScreenHeight) / 2;
    this._zoom = newZoom;
  }
}