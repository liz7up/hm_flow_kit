# Style Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate all hardcoded pixel values across the rendering layer by introducing design tokens in RenderConfig, unify font baseline to 'middle', and make drawing layer order configurable.

**Architecture:** Extend RenderConfig with ~30 measurement fields (design tokens). Every Drawer/EdgeRenderer/HitTestManager/FlowViewer reads these instead of magic numbers. FlowViewer.renderAll() sorts renderables by layerPriorities. **All defaults produce pixel-identical output.**

## Global Constraints

- All new RenderConfig fields have defaults matching existing hardcoded values
- `cornerRadius` replaced by `cornerRadiusRatio = 0.133` (= 8/60)
- `textBaseline` = `'middle'` everywhere
- `fontFamily` = `'HarmonyOS Sans, sans-serif'` (already correct, unchanged)
- Zero third-party dependencies
- All 120 existing tests must continue to pass

---

### Task 1: Extend RenderConfig with design tokens

**Files:**
- Modify: `hmflowkit/src/main/ets/renderer/RenderConfig.ets`

- [ ] **Step 1: Add new fields**

Insert the following block before `constructor()` in `RenderConfig`:

```typescript
// ═══ Node metrics ═══
cornerRadiusRatio: number = 0.133;    // r = min(w,h) * ratio (replaces cornerRadius=8)
nodePadding: number = 4;

// ═══ Task markers ═══
taskIconSize: number = 12;
taskIconOffset: number = 4;
loopMarkerSize: number = 5;
loopMarkerSpacing: number = 4;
loopMarkerOffset: number = 5;

// ═══ CallActivity ═══
callActivityBorderRatio: number = 2.5;
callActivityMarkerSize: number = 5;
callActivityMarkerOffset: number = 10;

// ═══ Event ═══
eventIconScale: number = 0.55;
eventLabelGap: number = 4;
eventInnerRingScale: number = 0.82;

// ═══ SubProcess ═══
subProcessInset: number = 3;
subProcessExpandMarkerSize: number = 12;
subProcessDashPattern: number[] = [6, 3];

// ═══ Gateway markers ═══
gatewayMarkerScale: Record<string, number> = {
  'exclusiveGateway': 0.16, 'parallelGateway': 0.28,
  'inclusiveGateway': 0.28, 'complexGateway': 0.42, 'eventBasedGateway': 0.42
};

// ═══ Data ═══
dataObjectFoldSize: number = 12;

// ═══ Annotation ═══
annotationBracketWidth: number = 8;
annotationFontScale: number = 1.4;

// ═══ Edge ═══
edgeLabelOffset: number = 12;
edgeLabelPadding: number = 3;

// ═══ HitTest ═══
edgeHitTolerance: number = 12;

// ═══ Viewport ═══
fitToViewPadding: number = 40;
fitToViewMinZoom: number = 0.1;
fitToViewMaxZoom: number = 3.0;
renderThrottleMs: number = 16;

// ═══ Highlight ═══
highlightColor: string = 'rgba(24, 144, 255, 0.35)';
highlightPadding: number = 4;

// ═══ Font ═══
fontSizeMin: number = 12;

// ═══ Layer order ═══
layerPriorities: Record<string, number> = {
  'poolLane': 0,
  'subProcess': 1,
  'dataObject': 2, 'dataStore': 2, 'textAnnotation': 2,
  'edge': 3,
  'task': 4, 'callActivity': 4, 'gateway': 4,
  'eventBasedGateway': 4, 'complexGateway': 4,
  'startEvent': 5, 'endEvent': 5, 'intermediateEvent': 5,
  'boundaryEvent': 6
};
defaultLayerPriority: number = 3;
```

Remove the old field: `cornerRadius: number = 8;`

- [ ] **Step 2: Verify test compatibility**

The existing `RenderConfig.test.ets` doesn't reference `cornerRadius`, so no test changes needed.

- [ ] **Step 3: Commit**

```bash
git add hmflowkit/src/main/ets/renderer/RenderConfig.ets
git commit -m "feat: add ~30 design tokens to RenderConfig, replace cornerRadius with cornerRadiusRatio"
```

---

### Task 2: Replace hardcoded values in all 6 Drawers

**Files:**
- Modify: `TaskDrawer.ets`, `EventDrawer.ets`, `GatewayDrawer.ets`, `SubProcessDrawer.ets`, `DataDrawer.ets`, `AnnotationDrawer.ets`

**Principle:** Every `MAGIC * zoom` / `MAGIC` becomes `config.TOKEN * zoom` / `config.TOKEN` with TOKEN default matching MAGIC. Pixel-identical output.

#### 2a: TaskDrawer.ets

| Line | Old | New |
|------|-----|-----|
| 35 | `config.cornerRadius * zoom` | `Math.min(w, h) * config.cornerRadiusRatio * zoom` |
| 67 | `config.strokeWidth * 2.5` | `config.strokeWidth * config.callActivityBorderRatio` |
| 91 | `y + h - 10 * zoom` | `y + h - config.callActivityMarkerOffset * zoom` |
| 92 | `s: number = 5 * zoom` | `s: number = config.callActivityMarkerSize * zoom` |
| 108 | `Math.max(12, Math.round(...))` | `Math.max(config.fontSizeMin, Math.round(...))` |
| 123 | `y + h - 5 * zoom` | `y + h - config.loopMarkerOffset * zoom` |
| 127 | `Math.max(11, Math.round(14 * zoom))` | `Math.max(11, Math.round(config.loopMarkerSize * 2.8 * zoom))` |
| 130 | `hw: number = 5 * zoom` | `hw: number = config.loopMarkerSize * zoom` |
| 131 | `sp: number = 4 * zoom` | `sp: number = config.loopMarkerSpacing * zoom` |
| 152 | `r: number = 5 * zoom` | `r: number = config.loopMarkerSize * zoom` |
| 170 | `x + 4 * zoom` | `x + config.taskIconOffset * zoom` |
| 171 | `y + 4 * zoom` | `y + config.taskIconOffset * zoom` |
| 172 | `s: number = 12 * zoom` | `s: number = config.taskIconSize * zoom` |
| 222 | `Math.max(12, Math.round(14 * zoom))` | `Math.max(config.fontSizeMin, Math.round(config.taskIconSize * 1.17 * zoom))` |

#### 2b: EventDrawer.ets

| Line | Old | New |
|------|-----|-----|
| 80 | `r * 0.82` | `r * config.eventInnerRingScale` |
| 91 | `r * 0.55` | `r * config.eventIconScale` |
| 98-102 | `Math.max(12,...)`, `textBaseline='top'`, `y+h/2+r+4*zoom` | Use `config.fontSizeMin`, `textBaseline='middle'`, Y: `y+h/2+r + config.eventLabelGap*zoom + fontSize/2` |

```typescript
// EventDrawer label (lines 96-102) — before:
ctx.fillStyle = config.textColor;
ctx.font = Math.max(12, Math.round(config.fontSize * zoom)) + 'px ' + config.fontFamily;
ctx.textAlign = 'center';
ctx.textBaseline = 'top';
ctx.fillText(text, cx, y + h / 2 + r + 4 * zoom);

// After:
let efs: number = Math.max(config.fontSizeMin, Math.round(config.fontSize * zoom));
ctx.fillStyle = config.textColor;
ctx.font = efs + 'px ' + config.fontFamily;
ctx.textAlign = 'center';
ctx.textBaseline = 'middle';
ctx.fillText(text, cx, y + h / 2 + r + config.eventLabelGap * zoom + efs / 2);
```

#### 2c: GatewayDrawer.ets

| Line | Old | New |
|------|-----|-----|
| 52-59 | if/else chain: 0.16, 0.42, 0.28 | `config.gatewayMarkerScale[gwTag] \|\| 0.28` |
| 73 | `Math.max(12, Math.round(...))` | `Math.max(config.fontSizeMin, Math.round(...))` |

```typescript
// Gateway marker sizing (lines 52-59) — before:
if (gwTag === 'exclusiveGateway') {
  s = base * 0.16 * zoom;
} else if (gwTag === 'complexGateway' || gwTag === 'eventBasedGateway') {
  s = base * 0.42 * zoom;
} else {
  s = base * 0.28 * zoom;
}

// After:
let scale: number | undefined = config.gatewayMarkerScale[gwTag];
s = base * (scale !== undefined ? scale : 0.28) * zoom;
```

#### 2d: SubProcessDrawer.ets

| Line | Old | New |
|------|-----|-----|
| 34 | `config.cornerRadius * zoom` | `Math.min(w, h) * config.cornerRadiusRatio * zoom` |
| 56 | `[6 * zoom, 3 * zoom]` | `[config.subProcessDashPattern[0] * zoom, config.subProcessDashPattern[1] * zoom]` |
| 63 | `inset: number = 3 * zoom` | `inset: number = config.subProcessInset * zoom` |
| 84 | `markerSize: number = 12 * zoom` | `markerSize: number = config.subProcessExpandMarkerSize * zoom` |
| 102 | `Math.max(12, Math.round(...))` | `Math.max(config.fontSizeMin, Math.round(...))` |

#### 2e: DataDrawer.ets

| Line | Old | New |
|------|-----|-----|
| 38 | `fold: number = 12 * zoom` | `fold: number = config.dataObjectFoldSize * zoom` |
| 94 | `Math.max(12, Math.round(...))` | `Math.max(config.fontSizeMin, Math.round(...))` |

#### 2f: AnnotationDrawer.ets — textBaseline 'top' → 'middle'

| Line | Old | New |
|------|-----|-----|
| 12 | `bracketW: number = 8 * zoom` | `bracketW: number = config.annotationBracketWidth * zoom` |
| 13 | `Math.max(12, Math.round(config.fontSize * zoom * 1.4))` | `Math.max(config.fontSizeMin, Math.round(config.fontSize * zoom * config.annotationFontScale))` |
| 35 | `ctx.textBaseline = 'top'` | `ctx.textBaseline = 'middle'` |
| 36 | `textX = x + bracketW + 2 * zoom` | `textX = x + bracketW + config.nodePadding / 2 * zoom` |
| 37 | `textW = w - bracketW - 4 * zoom` | `textW = w - bracketW - config.nodePadding * zoom` |
| 41 | `lineY = y + 2 * zoom` | `lineY = y + config.nodePadding / 2 * zoom + fontSize / 2` |
| 62 | `lineY += fontSize + 2 * zoom` | `lineY += fontSize + config.nodePadding / 2 * zoom` |

All 6 drawer changes keep pixel-identical output for default-size elements. Only annotation gets visual Y-shift (half font height) due to baseline change, which is the intended fix.

- [ ] **Step: Commit**

```bash
git add hmflowkit/src/main/ets/renderer/TaskDrawer.ets \
        hmflowkit/src/main/ets/renderer/EventDrawer.ets \
        hmflowkit/src/main/ets/renderer/GatewayDrawer.ets \
        hmflowkit/src/main/ets/renderer/SubProcessDrawer.ets \
        hmflowkit/src/main/ets/renderer/DataDrawer.ets \
        hmflowkit/src/main/ets/renderer/AnnotationDrawer.ets
git commit -m "refactor: all 6 drawers use config design tokens, textBaseline unified to middle"
```

---

### Task 3: EdgeRenderer + HitTestManager config refs

**Files:**
- Modify: `EdgeRenderer.ets`, `HitTestManager.ets`

#### 3a: EdgeRenderer.ets

| Line | Old | New |
|------|-----|-----|
| 211 | `off: number = 12` | `off: number = config.edgeLabelOffset` |
| 217 | `Math.max(10, Math.round(config.fontSize * 0.92))` | `Math.max(config.fontSizeMin - 2, Math.round(config.fontSize * 0.92))` |
| 224 | `pad: number = 3` | `pad: number = config.edgeLabelPadding` |

#### 3b: HitTestManager.ets

In `rebuild()` method (line 210), add at the start of the method body:
```typescript
this.edgeHitTolerance = config.edgeHitTolerance;
```

- [ ] **Step: Commit**

```bash
git add hmflowkit/src/main/ets/renderer/EdgeRenderer.ets \
        hmflowkit/src/main/ets/renderer/HitTestManager.ets
git commit -m "refactor: EdgeRenderer + HitTestManager use config tokens"
```

---

### Task 4: FlowViewer — layer-priority render order + config refs

**Files:**
- Modify: `hmflowkit/src/main/ets/components/FlowViewer.ets`

- [ ] **Step 1: Replace viewport hardcodes**

| Line | Old | New |
|------|-----|-----|
| 160 (renderFrame) | `now - this._lastRenderTime < 16` | `... < this.renderConfig.renderThrottleMs` |
| 254 (fitToView pad) | `let pad: number = 40` | `let pad: number = this.renderConfig.fitToViewPadding` |
| 256 | `if (fitZoom < 0.1)` | `if (fitZoom < this.renderConfig.fitToViewMinZoom)` |
| 257 | `if (fitZoom > 3.0)` | `if (fitZoom > this.renderConfig.fitToViewMaxZoom)` |

- [ ] **Step 2: Replace highlight hardcodes**

| Line | Old | New |
|------|-----|-----|
| 335 | `'rgba(24, 144, 255, 0.35)'` | `this.renderConfig.highlightColor` |
| 336 | `hlNode.x - 4, hlNode.y - 4, hlNode.width + 8, hlNode.height + 8` | `hlNode.x - hp, hlNode.y - hp, hlNode.width + hp*2, hlNode.height + hp*2` where `hp = this.renderConfig.highlightPadding` |

- [ ] **Step 3: Replace hardcoded layer ordering**

Replace the node-split + separate-render block (lines ~287-324, the part that splits into subProcs/regular/boundary and renders edges between them) with this priority-sorted approach:

```typescript
// Collect all renderable items with layer priorities
let items: { priority: number, node?: GraphNode, edge?: GraphEdge }[] = [];

for (let i: number = 0; i < nodes.length; i++) {
  let n: GraphNode = nodes[i];
  let pri: number | undefined = this.renderConfig.layerPriorities[n.type as string];
  items.push({
    priority: pri !== undefined ? pri : this.renderConfig.defaultLayerPriority,
    node: n
  });
}

for (let i: number = 0; i < edges.length; i++) {
  let edgePri: number | undefined = this.renderConfig.layerPriorities['edge'];
  items.push({
    priority: edgePri !== undefined ? edgePri : this.renderConfig.defaultLayerPriority,
    edge: edges[i]
  });
}

items.sort((a, b) => a.priority - b.priority);

for (let i: number = 0; i < items.length; i++) {
  if (items[i].node !== undefined) {
    NodeRenderer.render(this.ctx, items[i].node, this.renderConfig, 0, 0, 1);
  } else if (items[i].edge !== undefined) {
    EdgeRenderer.render(this.ctx, items[i].edge, (id: string): NodeRect => {
      return this.getNodePosition(id);
    }, 0, 0, 1, this.renderConfig);
  }
}
```

Remove the removed variables: `subProcs`, `regular`, `boundary` arrays.

- [ ] **Step 4: Commit**

```bash
git add hmflowkit/src/main/ets/components/FlowViewer.ets
git commit -m "refactor: FlowViewer uses config tokens + layer-priority render order"
```

---

### Task 5: Verify tests compile

- [ ] **Step 1: Run test compilation**

```bash
cd /storage/Users/currentUser/Documents/repo/hm_flow_kit && sh test_all.sh
```

- [ ] **Step 2: Check build log**

Expected: Zero compilation errors. All 120 tests listed.

- [ ] **Step 3: If any compilation errors, fix and re-run. Commit any fixes.**

---

## Risk Mitigation

- **Pixel-identical defaults**: Every config default matches the old hardcoded value exactly (e.g., `taskIconSize=12`, `loopMarkerSize=5`). Visual output unchanged.
- **Single commit per batch**: Each task is one commit. Easy to `git revert` if an issue is found.
- **Only intentionally changed visual**: `cornerRadiusRatio=0.133` means non-120x60 nodes get proportional corners — this is the feature, not a bug.
- **baseline middle shift**: EventDrawer Y adjusted by `+fontSize/2` to compensate; AnnotationDrawer Y adjusted by `+fontSize/2` for first line.
