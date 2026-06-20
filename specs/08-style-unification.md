# Style Unification Design

## Goal

Unify visual language across all zoom levels by eliminating hardcoded
pixel values and establishing design tokens in `RenderConfig`.

## 1. Design Tokens (new fields in RenderConfig)

### Node Metrics
```
cornerRadiusRatio: number = 0.067     // r = min(w,h)*ratio*zoom (replaces cornerRadius=8)
nodePadding: number = 4               // anchor inset, highlight padding, etc.
```

### Task Markers
```
taskIconSize: number = 12             // subtype icon base size
taskIconOffset: number = 4            // top-left icon offset
loopMarkerSize: number = 5            // loop marker base size
loopMarkerSpacing: number = 4         // multiInstance vertical line spacing
loopMarkerOffset: number = 5          // loop marker bottom offset
```

### CallActivity
```
callActivityBorderRatio: number = 2.5 // thick border multiplier
callActivityMarkerSize: number = 5    // [+] marker base size
callActivityMarkerOffset: number = 10 // [+] marker bottom offset
```

### Event
```
eventIconScale: number = 0.55         // icon size relative to radius
eventLabelGap: number = 4             // text↔circle gap
eventInnerRingScale: number = 0.82    // intermediate inner ring ratio
```

### SubProcess
```
subProcessInset: number = 3           // transaction double-line inset
subProcessExpandMarkerSize: number = 12
subProcessDashPattern: number[] = [6, 3]
```

### Gateway Markers (per-type scale)
```
gatewayMarkerScale: Record<string,number> = {
  exclusiveGateway: 0.16, parallelGateway: 0.28,
  inclusiveGateway: 0.28, complexGateway: 0.42, eventBasedGateway: 0.42
}
```

### Data
```
dataObjectFoldSize: number = 12
```

### Annotation
```
annotationBracketWidth: number = 8
annotationFontScale: number = 1.4
```

### Edge
```
edgeLabelOffset: number = 12          // perpendicular offset
edgeLabelPadding: number = 3          // bg padding
```

### HitTest
```
edgeHitTolerance: number = 12
```

### Viewport
```
fitToViewPadding: number = 40
fitToViewMinZoom: number = 0.1
fitToViewMaxZoom: number = 3.0
renderThrottleMs: number = 16
```

### Highlight
```
highlightColor: string = 'rgba(24,144,255,0.35)'
highlightPadding: number = 4
```

### Font
```
fontSizeMin: number = 12              // minimum renderable font size
fontFamily: string = 'HarmonyOS Sans, sans-serif'  // (already exists)
```

### Layer Order
```
layerPriorities: Record<string,number> = {
  poolLane: 0, subProcess: 1,
  dataObject: 2, dataStore: 2, textAnnotation: 2,
  edge: 3,
  task: 4, callActivity: 4, gateway: 4,
  startEvent: 5, endEvent: 5, intermediateEvent: 5,
  boundaryEvent: 6
}
defaultLayerPriority: number = 3
```

## 2. Font Baseline Unification

All drawers use `textBaseline = 'middle'` consistently.

Files to fix:
- **EventDrawer**: currently `'top'` → `'middle'`, adjust Y to `cy + r + gap + fontSize/2`
- **AnnotationDrawer**: currently `'top'` → `'middle'`, adjust line Y calc

## 3. Drawing Order Configurable

`FlowViewer.renderAll()`:
1. Collect all renderable items with their layer priority
2. Sort by priority ascending
3. Render in order
4. Unknown types use `defaultLayerPriority`

## Files Changed

| File | Changes |
|------|---------|
| `RenderConfig.ets` | +~30 measurement fields, +layerPriorities |
| `TaskDrawer.ets` | replace all magic numbers with config refs |
| `EventDrawer.ets` | same + textBaseline→middle + Y adjustment |
| `GatewayDrawer.ets` | magic numbers → config refs |
| `SubProcessDrawer.ets` | magic numbers → config refs |
| `DataDrawer.ets` | magic numbers → config refs |
| `AnnotationDrawer.ets` | magic numbers→config + textBaseline→middle |
| `EdgeRenderer.ets` | magic numbers → config refs |
| `HitTestManager.ets` | tolerance from config |
| `FlowViewer.ets` | layer-priority-based render order, config refs |

## Non-Goals

- No color changes (those are already in RenderConfig)
- No new drawing logic (only parameterizing existing)
- No API breakage (all new fields have defaults)
