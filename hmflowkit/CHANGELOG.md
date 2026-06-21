# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-06-20

### Added — BPMN Full Coverage (Phase 3)

- **13 NodeType enum**: TASK, START_EVENT, END_EVENT, GATEWAY, BOUNDARY_EVENT, INTERMEDIATE_THROW_EVENT, INTERMEDIATE_CATCH_EVENT, DATA_OBJECT, DATA_STORE, TEXT_ANNOTATION, DATA_INPUT, DATA_OUTPUT, GROUP
- **7 per-type drawers**: TaskDrawer, GatewayDrawer, EventDrawer, SubProcessDrawer, DataDrawer, AnnotationDrawer (exported, user-extensible)
- **10 event definition icons**: timer (clock), message (envelope), error (lightning), signal (triangle), terminate (filled circle), cancel (X-circle), compensate (double-arrow), escalation (up-arrow), conditional (ruled-page), link (arrow)
- **7 task type icons**: userTask (person), serviceTask (gear), scriptTask (script), manualTask (hand), sendTask (filled envelope), receiveTask (outline envelope), businessRuleTask (table/grid)
- **3 SubProcess border styles**: single-line (default), double-line (transaction), dashed (eventSubProcess)
- **Multi-instance markers**: `≡` sequential, `|||` parallel, `↻` loop (Canvas-drawn inside task)
- **callActivity** with [+] marker below border
- **isInterrupting=false** → dashed border for startEvent / intermediateCatchEvent / boundaryEvent
- **textAnnotation** bracket with pixel-perfect word-wrap, **dataStore** cylinder, **dataObject**
- **Association** + **DataAssociation** dashed edge rendering (deferred dataAssoc capture via TEXT events + post-parse processing)
- **5-layer Z-order**: Pool → SubProcess (bg) → Edges → Regular → Boundary → SubProcess (collapsed)
- 16 new parser + NodeType tests (118 → 120 total)
- `currentAttrs` save/restore stack to prevent cross-element pollution
- 7 visual bugs fixed: gateway markers, textAnnotation, dataStore, task icons, dataAssoc edges

### Added — Style Unification (Phase 4)

- **~30 design tokens** in `RenderConfig` replacing ~50 hardcoded values across all drawers
- `cornerRadiusRatio` replacing absolute `cornerRadius` (pixel-perfect defaults unchanged)
- `textBaseline` unified to `"middle"` across all 6 drawers + EdgeRenderer
- `layerPriorities` config map for customizable Z-order
- All renderers (6 drawers + EdgeRenderer + HitTestManager + FlowViewer) driven by config tokens

### Added — Monochrome + Dark Mode (Phase 5)

- **Default monochrome palette**: all strokes/text `#000`, fills `#FFF`, task subtypes via line weight
- **`RenderConfig.darkPreset()`** static factory for dark theme
- `FlowViewer` **`@StorageProp('currentColorMode')`** + `@Watch` auto-adapt to system theme
- `EntryAbility` AppStorage sync + `onConfigurationUpdate` for live light/dark switch
- `FlowViewer` **`@Prop renderConfig`** for user customization (protected from theme override by `_userConfig` flag)
- Canvas background follows theme, edge label background rect removed

### Added — Multi-Plane Drill-Down (Phase 6)

- **`PlaneHierarchy`** data model: `PlaneDefinition`, `BreadcrumbEntry`, parent-child chains
- **`BpmnXmlParser.parseHierarchy()`** with post-scan for diagram → plane routing + subProcess parent chains
- `FlowViewer` **`@Prop planeHierarchy`** + clickable breadcrumb navigation (`Root > Procure > Charge`)
- Expanded subProcess renders children in-place (layer 0 background container, centered label)
- Collapsed subProcess renders as interactive node (layer 4, blue `[+]` marker)
- **HitTest smallest-area priority** for nested elements (inner icon preferred over parent box)
- `BpmnViewerPage` with file picker for `.bpmn` / `.xml` files
- Demo buttons: Kitchen Sink, Nested Subprocess, Pizza Demo, 打开任意bpmn文件

### Added — Public API

- `TaskDrawer`, `GatewayDrawer`, `EventDrawer`, `SubProcessDrawer`, `DataDrawer`, `AnnotationDrawer` exported
- `PlaneHierarchy`, `PlaneDefinition`, `BreadcrumbEntry`, `ParseResult` exported
- `BpmnXmlParser.parseBestEffort()` → `ParseResult { model, warnings, isPartial }`

### Changed — DevOps

- `build.sh` daemon + flag trigger mode, `test_all.sh` merged into `build.sh` Step 3
- `FlowViewer` `@Prop model` accepts `GraphModel.createEmpty()` default

### Known Limitations

- Interactive editing (drag, connect, select) not yet implemented (deferred to Spec 04)
- Dagre auto-layout not yet implemented (deferred to Spec 05)
- PC wheel zoom blocked by HarmonyOS PC `onMouse`/`onWheel` API instability
- 4 event definition icons pending: Conditional, Escalation, Compensation, Link
- No Choreography / Conversation support
- 120 unit tests (compile-verified), but no visual regression / integration / perf tests

## [0.1.0] - 2026-06-15

### Added
- **GraphModel**: Immutable graph data model with node/edge CRUD, serialization, and viewport management
- **CanvasManager**: Viewport zoom, pan, and coordinate transformation (screen ↔ canvas)
- **NodeRenderer**: Static node rendering for rectangle, diamond, and circle shapes with centered labels
- **EdgeRenderer**: Static edge rendering with polyline waypoints and arrowheads
- **GridRenderer**: Configurable background grid (dots or lines)
- **HitTestManager**: Coordinate-to-element hit detection for nodes and edges
- **BpmnXmlParser**: Full BPMN 2.0 XML parsing with namespace support, BPMNShape/BPMNEdge coordinate extraction, and graceful fallback for missing BPMNDiagram
- **FlowViewer**: One-line embedded flow viewer component with auto-fit, click-to-highlight, and tap-blank-to-deselect
- **RenderConfig**: Centralized render configuration (colors, sizes, typography)
- 31 verification tests covering all core features
- Support for BPMN 2.0 task, startEvent, endEvent, exclusiveGateway, sequenceFlow, and labels
- Graceful fallback for XMLs without BPMNDiagram (auto-assigns default coordinates)

### Known Limitations
- Interactive editing (drag, connect, select) not yet implemented (deferred to Spec 04)
- Dagre auto-layout not yet implemented (deferred to Spec 05)
- Node labels overflow on small nodes (e.g., 36×36 circles)
- No BPMN 2.0 execution engine (rendering only)