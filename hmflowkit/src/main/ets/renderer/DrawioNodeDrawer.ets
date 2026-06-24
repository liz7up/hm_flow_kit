/**
 * DrawioNodeDrawer - Renderer for draw.io shapes.
 *
 * Registered with NodeRenderer for all 'drawio.*' node types.
 * Delegates shape drawing based on node.type prefix.
 *
 * ArkTS strict mode compliance: no implements on function type,
 * explicit typed parameters, no object literals as types.
 */

import { GraphNode } from '../model/GraphModel';
import { RenderConfig } from './RenderConfig';
import { INodeDrawer, NodeRenderer } from './NodeRenderer';

export class DrawioNodeDrawer {
  private static _inited: boolean = false;

  static init(): void {
    if (DrawioNodeDrawer._inited) {
      return;
    }
    DrawioNodeDrawer._inited = true;
    let d: DrawioNodeDrawer = new DrawioNodeDrawer();
    let wrapper: INodeDrawer = (
      ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
      x: number, y: number, w: number, h: number, zoom: number
    ): void => {
      d.render(ctx, node, config, x, y, w, h, zoom);
    };
    NodeRenderer.register('drawio.rect', wrapper);
    NodeRenderer.register('drawio.ellipse', wrapper);
    NodeRenderer.register('drawio.rhombus', wrapper);
    NodeRenderer.register('drawio.triangle', wrapper);
    NodeRenderer.register('drawio.parallelogram', wrapper);
    NodeRenderer.register('drawio.text', wrapper);
    NodeRenderer.register('drawio.swimlane', wrapper);
  }

  render(
    ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
    x: number, y: number, w: number, h: number, zoom: number
  ): void {
    let shape: string = this._extractShape(node.type);
    let fill: string = DrawioNodeDrawer._resolveColor(
      node.properties['_fillColor'], config.fillColor);
    let stroke: string = DrawioNodeDrawer._resolveColor(
      node.properties['_strokeColor'], config.strokeColor);
    let strokeWidth: number = config.strokeWidth * zoom;
    let dashed: boolean = node.properties['_dashed'] === '1';
    let opacity: number = parseInt(node.properties['_opacity'] || '100') / 100;

    ctx.globalAlpha = opacity;

    if (dashed) {
      let dpStr: string = node.properties['_dashPattern'] || '6 4';
      let dpParts: string[] = dpStr.split(' ');
      let dp: number[] = [];
      for (let i: number = 0; i < dpParts.length; i++) {
        let v: number = parseInt(dpParts[i]);
        if (!isNaN(v)) {
          dp.push(v * zoom);
        }
      }
      if (dp.length === 0) {
        dp = [6 * zoom, 4 * zoom];
      }
      ctx.setLineDash(dp);
    }

    ctx.fillStyle = fill;
    ctx.strokeStyle = stroke;
    ctx.lineWidth = strokeWidth;

    switch (shape) {
      case 'ellipse':
        this._drawEllipse(ctx, x, y, w, h);
        break;
      case 'rhombus':
        this._drawRhombus(ctx, x, y, w, h);
        break;
      case 'triangle':
        this._drawTriangle(ctx, x, y, w, h);
        break;
      case 'parallelogram':
        this._drawParallelogram(ctx, x, y, w, h);
        break;
      case 'swimlane':
        this._drawSwimlane(ctx, node, config, x, y, w, h, zoom);
        break;
      case 'text':
        // No border/fill for pure text nodes
        break;
      case 'rect':
      default:
        this._drawRect(ctx, node, x, y, w, h);
        break;
    }

    ctx.setLineDash([]);
    ctx.globalAlpha = 1.0;

    // Draw label
    this._renderLabel(ctx, node, config, x, y, w, h, zoom);
  }

  // ── Shape drawers ─────────────────────────────────────────────────

  private _drawRect(
    ctx: CanvasRenderingContext2D, node: GraphNode,
    x: number, y: number, w: number, h: number
  ): void {
    let rounded: boolean = node.properties['_rounded'] === '1';
    let arcSize: number = parseInt(node.properties['_arcSize'] || '0');
    let noFill: boolean = ctx.fillStyle === 'none';
    let noStroke: boolean = ctx.strokeStyle === 'none';

    if (rounded || arcSize > 0) {
      let r: number;
      if (arcSize > 0) {
        r = Math.min(w, h) * arcSize / 200;
      } else {
        r = Math.min(w, h) * 0.133;
      }
      r = Math.max(0, Math.min(r, w / 2, h / 2));
      ctx.beginPath();
      ctx.moveTo(x + r, y);
      ctx.lineTo(x + w - r, y);
      ctx.arcTo(x + w, y, x + w, y + r, r);
      ctx.lineTo(x + w, y + h - r);
      ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
      ctx.lineTo(x + r, y + h);
      ctx.arcTo(x, y + h, x, y + h - r, r);
      ctx.lineTo(x, y + r);
      ctx.arcTo(x, y, x + r, y, r);
      ctx.closePath();
      if (!noFill) ctx.fill();
      if (!noStroke) ctx.stroke();
    } else {
      if (!noFill) ctx.fillRect(x, y, w, h);
      if (!noStroke) ctx.strokeRect(x, y, w, h);
    }
  }

  private _drawEllipse(
    ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number
  ): void {
    ctx.beginPath();
    ctx.ellipse(x + w / 2, y + h / 2, w / 2, h / 2, 0, 0, 2 * Math.PI);
    if (ctx.fillStyle !== 'none') ctx.fill();
    if (ctx.strokeStyle !== 'none') ctx.stroke();
  }

  private _drawRhombus(
    ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number
  ): void {
    ctx.beginPath();
    ctx.moveTo(x + w / 2, y);
    ctx.lineTo(x + w, y + h / 2);
    ctx.lineTo(x + w / 2, y + h);
    ctx.lineTo(x, y + h / 2);
    ctx.closePath();
    if (ctx.fillStyle !== 'none') ctx.fill();
    if (ctx.strokeStyle !== 'none') ctx.stroke();
  }

  private _drawTriangle(
    ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number
  ): void {
    ctx.beginPath();
    ctx.moveTo(x + w / 2, y);
    ctx.lineTo(x + w, y + h);
    ctx.lineTo(x, y + h);
    ctx.closePath();
    if (ctx.fillStyle !== 'none') ctx.fill();
    if (ctx.strokeStyle !== 'none') ctx.stroke();
  }

  private _drawParallelogram(
    ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number
  ): void {
    let skew: number = w / 6;
    ctx.beginPath();
    ctx.moveTo(x + skew, y);
    ctx.lineTo(x + w, y);
    ctx.lineTo(x + w - skew, y + h);
    ctx.lineTo(x, y + h);
    ctx.closePath();
    if (ctx.fillStyle !== 'none') ctx.fill();
    if (ctx.strokeStyle !== 'none') ctx.stroke();
  }

  private _drawSwimlane(
    ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
    x: number, y: number, w: number, h: number, zoom: number
  ): void {
    let isHorizontal: boolean = node.properties['_horizontal'] !== '0';
    let headerSize: number = config.poolHeaderWidth * zoom;

    // Container fill + stroke
    let containerFill: string = DrawioNodeDrawer._resolveColor(
      node.properties['_fillColor'], config.poolFillColor);
    if (containerFill !== 'none') {
      ctx.fillStyle = containerFill;
      ctx.fillRect(x, y, w, h);
    }
    let containerStroke: string = DrawioNodeDrawer._resolveColor(
      node.properties['_strokeColor'], config.poolStrokeColor);
    if (containerStroke !== 'none') {
      ctx.strokeStyle = containerStroke;
      ctx.lineWidth = config.poolStrokeWidth * zoom;
      ctx.strokeRect(x, y, w, h);
    }

    // Header background
    let hdrFill: string = node.properties['_swimlaneFillColor'] || config.poolHeaderFillColor;
    if (hdrFill !== 'none') {
      ctx.fillStyle = hdrFill;
      if (isHorizontal) {
        ctx.fillRect(x, y, headerSize, h);
      } else {
        ctx.fillRect(x, y, w, headerSize);
      }
    }

    // Header text
    let label: string = node.label;
    if (label.length > 0) {
      let fontColor: string = DrawioNodeDrawer._resolveColor(
        node.properties['_fontColor'], config.poolHeaderTextColor);
      ctx.fillStyle = fontColor;
      let fontSize: number = parseInt(node.properties['_fontSize'] || '12');
      let scaledFontSize: number = Math.max(10, Math.round(fontSize * zoom));
      ctx.font = scaledFontSize + 'px ' + config.fontFamily;

      if (isHorizontal) {
        ctx.save();
        ctx.translate(x + headerSize / 2, y + h / 2);
        ctx.rotate(-Math.PI / 2);
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(label, 0, 0);
        ctx.restore();
      } else {
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(label, x + w / 2, y + headerSize / 2);
      }
    }
  }

  // ── Label rendering ────────────────────────────────────────────────

  private _renderLabel(
    ctx: CanvasRenderingContext2D, node: GraphNode, config: RenderConfig,
    x: number, y: number, w: number, h: number, zoom: number
  ): void {
    let label: string = node.label;
    if (label.length === 0) {
      return;
    }

    let fontColor: string = DrawioNodeDrawer._resolveColor(
      node.properties['_fontColor'], config.textColor);
    let fontSizeStr: string | undefined = node.properties['_fontSize'];
    let fontSize: number = fontSizeStr !== undefined ? parseInt(fontSizeStr) : config.fontSize;
    let scaledFontSize: number = Math.max(9, Math.round(fontSize * zoom));
    let fontFamily: string = node.properties['_fontFamily'] || config.fontFamily;
    let align: string = node.properties['_align'] || 'center';
    let vAlign: string = node.properties['_verticalAlign'] || 'middle';

    ctx.fillStyle = fontColor;
    ctx.font = scaledFontSize + 'px ' + fontFamily;
    ctx.textBaseline = 'middle';

    // Horizontal alignment
    if (align === 'left') {
      ctx.textAlign = 'left';
    } else if (align === 'right') {
      ctx.textAlign = 'right';
    } else {
      ctx.textAlign = 'center';
    }

    let lines: string[] = label.split('\n');
    let lineHeight: number = Math.round(scaledFontSize * 1.4);
    let totalH: number = lineHeight * lines.length;

    // Vertical alignment
    let startY: number;
    if (vAlign === 'top') {
      startY = y + lineHeight / 2 + 4;
    } else if (vAlign === 'bottom') {
      startY = y + h - totalH + lineHeight / 2 - 4;
    } else {
      startY = y + h / 2 - totalH / 2 + lineHeight / 2;
    }

    // Text X position based on alignment
    let textX: number;
    if (align === 'left') {
      textX = x + 4;
    } else if (align === 'right') {
      textX = x + w - 4;
    } else {
      textX = x + w / 2;
    }

    let maxW: number = w - 8;
    for (let i: number = 0; i < lines.length; i++) {
      let ly: number = startY + i * lineHeight;
      let text: string = lines[i];
      if (ctx.measureText(text).width > maxW) {
        while (text.length > 0 && ctx.measureText(text + '...').width > maxW) {
          text = text.substring(0, text.length - 1);
        }
        text = text + '...';
      }
      ctx.fillText(text, textX, ly);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  private static _resolveColor(fileColor: string | undefined, configColor: string): string {
    if (fileColor === undefined || fileColor.length === 0) {
      return configColor;  // not in file → use theme-aware config default
    }
    return fileColor;  // explicit file color (including 'none' for transparent)
  }

  private _extractShape(type: string): string {
    if (type.startsWith('drawio.')) {
      return type.substring(7); // strip 'drawio.' prefix
    }
    return type;
  }
}
