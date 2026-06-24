export class DrawioStyle {
  shapeType: string = 'drawio.rect';
  properties: Record<string, string> = {};

  constructor(shapeType: string, properties: Record<string, string>) {
    this.shapeType = shapeType;
    this.properties = properties;
  }
}

export class DrawioStyleParser {
  // Maps raw style keys to _-prefixed storage keys. Keys not in this map are silently dropped.
  private static _keyMap: Record<string, string> = {
    'fillColor': '_fillColor', 'strokeColor': '_strokeColor', 'fontColor': '_fontColor',
    'fontSize': '_fontSize', 'fontFamily': '_fontFamily', 'align': '_align',
    'verticalAlign': '_verticalAlign', 'arcSize': '_arcSize', 'dashed': '_dashed',
    'dashPattern': '_dashPattern', 'opacity': '_opacity', 'endArrow': '_endArrow',
    'startArrow': '_startArrow', 'edgeStyle': '_edgeStyle', 'curved': '_curved',
    'rounded': '_rounded', 'horizontal': '_horizontal'
  };

  // Colors intentionally have NO defaults — missing → renderer falls back to
  // RenderConfig (which auto-adapts to light/dark theme).
  private static _defaults: Record<string, string> = {
    '_fontSize': '12', '_fontFamily': '', '_align': 'center', '_verticalAlign': 'middle',
    '_arcSize': '0', '_dashed': '0', '_dashPattern': '', '_opacity': '100',
    '_endArrow': '', '_startArrow': '', '_edgeStyle': '', '_curved': '0', '_rounded': '0', '_horizontal': '1'
  };

  static parse(style: string): DrawioStyle {
    let raw: Record<string, string> = {};
    if (style.length > 0) {
      let parts: string[] = style.split(';');
      for (let i: number = 0; i < parts.length; i++) {
        let part: string = parts[i];
        if (part.length === 0) continue;
        let eqIdx: number = part.indexOf('=');
        if (eqIdx === -1) {
          raw[part] = '1';  // key-only entry — e.g. 'ellipse', 'rounded'
        } else {
          let key: string = part.substring(0, eqIdx);
          let value: string = part.substring(eqIdx + 1);
          raw[key] = value;
        }
      }
    }

    // ── Shape detection (priority order) ──
    let shapeType: string = 'drawio.rect';
    if (raw['swimlane'] !== undefined) {
      shapeType = 'drawio.swimlane';
    } else if (raw['text'] !== undefined) {
      shapeType = 'drawio.text';
    } else if (raw['ellipse'] !== undefined) {
      shapeType = 'drawio.ellipse';
    } else if (raw['rhombus'] !== undefined) {
      shapeType = 'drawio.rhombus';
    } else if (raw['triangle'] !== undefined) {
      shapeType = 'drawio.triangle';
    } else if (raw['shape'] === 'parallelogram') {
      shapeType = 'drawio.parallelogram';
    } else if (raw['shape'] === 'mxgraph.flowchart.start_1' ||
               raw['shape'] === 'mxgraph.flowchart.start_2' ||
               raw['shape'] === 'mxgraph.flowchart.end_1' ||
               raw['shape'] === 'mxgraph.flowchart.end_2') {
      shapeType = 'drawio.ellipse';
    } else if (raw['shape'] === 'mxgraph.bpmn.shape' && raw['background'] === 'gateway') {
      shapeType = 'drawio.rhombus';
    } else if (raw['shape'] === 'mxgraph.flowchart.or' ||
               raw['shape'] === 'mxgraph.flowchart.decision') {
      shapeType = 'drawio.rhombus';
    }
    // rect is the fallback for everything else (including rounded=1, arcSize)

    let props: Record<string, string> = DrawioStyleParser._withDefaults(raw);
    return new DrawioStyle(shapeType, props);
  }

  private static _withDefaults(raw: Record<string, string>): Record<string, string> {
    let result: Record<string, string> = {};

    // Map recognized keys to _-prefixed storage keys
    let rawKeys: string[] = Object.keys(raw);
    for (let i: number = 0; i < rawKeys.length; i++) {
      let k: string = rawKeys[i];
      let mapped: string | undefined = DrawioStyleParser._keyMap[k];
      if (mapped !== undefined) {
        result[mapped] = raw[k];
      }
      // Unknown keys: silently dropped
    }

    // Fill defaults for missing keys
    let defKeys: string[] = Object.keys(DrawioStyleParser._defaults);
    for (let i: number = 0; i < defKeys.length; i++) {
      let dk: string = defKeys[i];
      if (result[dk] === undefined) {
        result[dk] = DrawioStyleParser._defaults[dk];
      }
    }

    return result;
  }
}
