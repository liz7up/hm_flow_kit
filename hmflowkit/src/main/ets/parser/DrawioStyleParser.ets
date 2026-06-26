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
    'rounded': '_rounded', 'horizontal': '_horizontal', 'backgroundOutline': '_backgroundOutline'
  };

  // Colors intentionally have NO defaults — missing → renderer falls back to
  // RenderConfig (which auto-adapts to light/dark theme).
  private static _defaults: Record<string, string> = {
    '_fontSize': '12', '_fontFamily': '', '_align': 'center', '_verticalAlign': 'middle',
    '_arcSize': '0', '_dashed': '0', '_dashPattern': '', '_opacity': '100',
    '_endArrow': '', '_startArrow': '', '_edgeStyle': '', '_curved': '0', '_rounded': '0', '_horizontal': '0'
  };

  // Maps drawio BPMN symbols to BPMN element names (reuses BPMN drawers)
  private static _gatewaySymbolMap: Record<string, string> = {
    'parallelGw': 'parallelGateway',
    'exclusiveGw': 'exclusiveGateway',
    'inclusiveGw': 'inclusiveGateway',
    'complexGw': 'complexGateway',
    'eventGw': 'eventBasedGateway'
  };

  private static _gwTypeMap: Record<string, string> = {
    'exclusive': 'exclusiveGateway',
    'parallel': 'parallelGateway',
    'inclusive': 'inclusiveGateway',
    'complex': 'complexGateway'
  };

  private static _taskMarkerMap: Record<string, string> = {
    'user': 'userTask', 'service': 'serviceTask', 'script': 'scriptTask',
    'manual': 'manualTask', 'businessRule': 'businessRuleTask',
    'send': 'sendTask', 'receive': 'receiveTask'
  };

  private static _outlineToEvent: Record<string, string> = {
    'standard': 'startEvent',
    'end': 'endEvent',
    'throwing': 'intermediateEvent',
    'catching': 'intermediateEvent',
    'eventInt': 'intermediateEvent',
    'eventNonint': 'intermediateEvent',
    'boundInt': 'boundaryEvent',
    'boundNonint': 'boundaryEvent'
  };

  // Maps drawio event symbols to BPMN eventDefinition (reuses EventDrawer icons)
  private static _eventSymbolMap: Record<string, string> = {
    'message': 'messageEventDefinition',
    'timer': 'timerEventDefinition',
    'error': 'errorEventDefinition',
    'signal': 'signalEventDefinition',
    'escalation': 'escalationEventDefinition',
    'cancel': 'cancelEventDefinition',
    'compensation': 'compensateEventDefinition',
    'conditional': 'conditionalEventDefinition',
    'link': 'linkEventDefinition',
    'terminate': 'terminateEventDefinition',
    'terminate2': 'terminateEventDefinition'
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
          raw[part] = '1';
        } else {
          let key: string = part.substring(0, eqIdx);
          let value: string = part.substring(eqIdx + 1);
          raw[key] = value;
        }
      }
    }

    // ── Shape detection (priority order) ──
    let shapeType: string = 'drawio.rect';
    let shape: string | undefined = raw['shape'];

    if (shape === 'mxgraph.bpmn.event') {
      let outline: string = raw['outline'] || 'standard';
      shapeType = DrawioStyleParser._outlineToEvent[outline] || 'startEvent';
    } else if (shape === 'mxgraph.bpmn.gateway2') {
      if (raw['gwType'] !== undefined) {
        shapeType = 'gateway';  // data-based gateway (exclusive/parallel/complex)
      } else if (raw['outline'] === 'standard' || raw['outline'] === 'catching') {
        // Basic event-based gateway (pentagon marker). Other variants
        // (boundInt, eventInt, eventNonint, throwing, end) fall back to rhombus.
        shapeType = 'eventBasedGateway';
      } else {
        shapeType = 'drawio.rhombus';  // unrecognized gateway variant → basic diamond
      }
    } else if (shape === 'mxgraph.bpmn.task2') {
      let st: string = raw['bpmnShapeType'] || '';
      if (st === 'subprocess' || st === 'transaction') shapeType = 'subProcess';
      else if (st === 'call') shapeType = 'callActivity';
      else shapeType = 'task';
    } else if (shape === 'mxgraph.bpmn.shape' && raw['background'] === 'gateway') {
      shapeType = 'gateway';
    } else if (shape === 'mxgraph.bpmn.task') {
      shapeType = 'task';
    } else if (shape === 'mxgraph.bpmn.callActivity') {
      shapeType = 'callActivity';
    } else if (shape === 'mxgraph.bpmn.subProcess') {
      shapeType = 'subProcess';
    } else if (shape === 'mxgraph.bpmn.swimlane') {
      shapeType = 'drawio.swimlane';
    } else if (shape === 'mxgraph.bpmn.data2') {
      shapeType = 'dataObject';
    } else if (shape === 'mxgraph.flowchart.annotation_2') {
      shapeType = 'textAnnotation';
    } else if (raw['swimlane'] !== undefined) {
      shapeType = 'drawio.swimlane';
    } else if (raw['text'] !== undefined) {
      shapeType = 'drawio.text';
    } else if (raw['ellipse'] !== undefined) {
      shapeType = 'drawio.ellipse';
    } else if (raw['rhombus'] !== undefined) {
      shapeType = 'drawio.rhombus';
    } else if (raw['triangle'] !== undefined) {
      shapeType = 'drawio.triangle';
    } else if (shape === 'parallelogram') {
      shapeType = 'drawio.parallelogram';
    } else if (shape === 'mxgraph.flowchart.start_1' ||
               shape === 'mxgraph.flowchart.start_2' ||
               shape === 'mxgraph.flowchart.end_1' ||
               shape === 'mxgraph.flowchart.end_2') {
      shapeType = 'drawio.ellipse';
    } else if (shape === 'mxgraph.flowchart.or' ||
               shape === 'mxgraph.flowchart.decision') {
      shapeType = 'drawio.rhombus';
    } else if (raw['shape'] === 'datastore' || shape === 'datastore') {
      shapeType = 'dataStore';
    } else if (shape === 'document') {
      shapeType = 'drawio.document';
    } else if (shape === 'process') {
      shapeType = 'drawio.process';
    } else if (shape === 'tableRow') {
      shapeType = 'drawio.tableRow';
    } else if (shape === 'table') {
      shapeType = 'drawio.table';
    }
    // rect is the fallback for everything else

    let props: Record<string, string> = DrawioStyleParser._withDefaults(raw);

    // ── Set bpmnElement for BPMN-reused types ──

    if (shapeType === 'gateway') {
      let gt: string | undefined = raw['gwType'];
      if (gt !== undefined) {
        let tag: string | undefined = DrawioStyleParser._gwTypeMap[gt];
        if (tag !== undefined) props['bpmnElement'] = tag;
      }
      if (props['bpmnElement'] === undefined) {
        let sym: string | undefined = raw['symbol'];
        if (sym !== undefined) {
          let tag: string | undefined = DrawioStyleParser._gatewaySymbolMap[sym];
          if (tag !== undefined) props['bpmnElement'] = tag;
        }
      }
    }

    if (shapeType === 'eventBasedGateway') {
      props['bpmnElement'] = 'eventBasedGateway';
      // Set event icon from symbol (reuses EventDrawer icon rendering via GatewayDrawer)
      DrawioStyleParser._setEventProps(props, raw);
    }

    if (shapeType === 'task') {
      let tm: string | undefined = raw['taskMarker'];
      if (tm !== undefined) {
        let tag: string | undefined = DrawioStyleParser._taskMarkerMap[tm];
        if (tag !== undefined) props['bpmnElement'] = tag;
      }
    }

    if (shapeType === 'startEvent') {
      props['bpmnElement'] = 'startEvent';
      DrawioStyleParser._setEventProps(props, raw);
    } else if (shapeType === 'endEvent') {
      props['bpmnElement'] = 'endEvent';
      DrawioStyleParser._setEventProps(props, raw);
    } else if (shapeType === 'intermediateEvent') {
      let outline: string = raw['outline'] || 'catching';
      props['bpmnElement'] = (outline === 'throwing') ? 'intermediateThrowEvent' :
        'intermediateCatchEvent';
      DrawioStyleParser._setEventProps(props, raw);
      if (outline === 'eventInt' || outline === 'eventNonint') {
        props['isInterrupting'] = 'false';
      }
    } else if (shapeType === 'boundaryEvent') {
      props['bpmnElement'] = 'boundaryEvent';
      DrawioStyleParser._setEventProps(props, raw);
      if (raw['outline'] === 'boundNonint') {
        props['cancelActivity'] = 'false';  // dashed border
      }
    }

    return new DrawioStyle(shapeType, props);
  }

  private static _setEventProps(props: Record<string, string>,
                                 raw: Record<string, string>): void {
    let symbol: string | undefined = raw['symbol'];
    if (symbol !== undefined && symbol !== 'general') {
      let evDef: string | undefined = DrawioStyleParser._eventSymbolMap[symbol];
      if (evDef !== undefined) {
        props['eventDefinition'] = evDef;
      }
    }
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
