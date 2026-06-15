export enum NodeShape {
  RECTANGLE,
  ROUNDED_RECT,
  DIAMOND,
  CIRCLE
}

export class RenderConfig {
  nodeWidth: number = 120;
  nodeHeight: number = 60;
  strokeColor: string = '#333333';
  strokeWidth: number = 2;
  fillColor: string = '#FFFFFF';
  activeStrokeColor: string = '#1890FF';
  activeFillColor: string = '#E6F7FF';
  textColor: string = '#333333';
  fontSize: number = 12;
  fontFamily: string = 'HarmonyOS Sans, sans-serif';
  cornerRadius: number = 8;
  edgeStrokeColor: string = '#333333';
  edgeStrokeWidth: number = 1.5;
  arrowSize: number = 8;
  gridSize: number = 20;
  gridColor: string = '#E8E8E8';

  constructor() {
  }
}