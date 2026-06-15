# Changelog

All notable changes to this project will be documented in this file.

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