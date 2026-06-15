# CLAUDE.md — hm-flow-kit

## 项目定位

鸿蒙原生 BPMN 2.0 流程图组件库。纯 ArkTS + Canvas 2D 实现，兼容 OpenHarmony 与 HarmonyOS。目标是成为鸿蒙生态的「bpmn.js / LogicFlow」——开发者通过 `ohpm install` 即可在自己的鸿蒙应用中嵌入 BPMN 流程图渲染与编辑能力。

## 技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| 语言 | ArkTS (TypeScript 超集) | 100% 代码使用 ArkTS，MVP 阶段不使用 C/C++ |
| UI 框架 | ArkUI | 声明式 UI 框架 |
| 渲染 | Canvas 2D (CanvasRenderingContext2D) | 所有节点、连线、画布均通过 Canvas 直绘 |
| 依赖 | 零第三方库 | MVP 阶段不引入任何 ohpm/npm 依赖 |
| 目标平台 | OpenHarmony 5.0+ / HarmonyOS 5.0+ | 优先兼容 OpenHarmony |

## 项目结构

```
hm-flow-kit/
├── entry/                                # Demo 应用（Empty Ability）
│   └── src/main/ets/pages/
│       └── Index.ets                     # 库的演示页面
├── hmflowkit/                            # 核心库（Static Library HAR）
│   ├── src/main/ets/
│   │   ├── Index.ets                     # 公开 API 导出入口
│   │   ├── model/
│   │   │   └── GraphModel.ets            # 图数据模型（唯一数据源）
│   │   ├── parser/
│   │   │   └── BpmnXmlParser.ets         # BPMN 2.0 XML 解析器
│   │   ├── renderer/
│   │   │   ├── NodeRenderer.ets          # 节点渲染器
│   │   │   ├── EdgeRenderer.ets          # 连线渲染器
│   │   │   └── CanvasManager.ets         # 画布管理（缩放、平移）
│   │   ├── interaction/
│   │   │   ├── DragController.ets        # 拖拽控制器
│   │   │   ├── ConnectController.ets     # 连线交互控制器
│   │   │   └── SelectController.ets      # 选择控制器
│   │   └── components/
│   │       ├── FlowViewer.ets            # 只读流程查看器
│   │       └── FlowDesigner.ets          # 可编辑流程设计器
│   └── oh-package.json5                 # 库的包配置
├── specs/                                # 开发规格文档
│   ├── 01-graph-model.md
│   ├── 02-canvas-renderer.md
│   ├── 03-bpmn-parser.md
│   ├── 04-interaction.md
│   ├── 05-dagre-layout.md
│   └── 06-ui-components.md
├── examples/                             # 可运行的示例
│   ├── hello-graph/                      # 最简渲染示例
│   └── bpmn-viewer/                      # BPMN 查看器示例
├── CLAUDE.md                             # 本文件（BitFun 项目记忆）
├── build.sh                              # 编译桥接脚本（DevEco 终端中运行）
├── build.log                             # 最新编译日志（BitFun 可读）
└── .mcp.json                             # MCP 服务配置
```

## 架构约束（必须遵守）

### 四层架构

```
┌─────────────────────────────────────────────────┐
│  UI 组件层       FlowViewer / FlowDesigner       │
├─────────────────────────────────────────────────┤
│  Interaction 层  DragController / Connect...     │
├─────────────────────────────────────────────────┤
│  Renderer 层     NodeRenderer / EdgeRenderer     │
├─────────────────────────────────────────────────┤
│  Model 层        GraphModel（唯一数据源）         │
├─────────────────────────────────────────────────┤
│  Parser 层       BpmnXmlParser / Serializer      │
└─────────────────────────────────────────────────┘
```

### 关键规则

1. **Model 层是唯一数据源**。GraphModel 持有所有节点和边的数据，Renderer 只读不写，Interaction 通过 Model 的方法修改数据。任何状态变更都必须经过 GraphModel。

2. **不可跨层调用**。UI 组件层不能直接操作 Canvas（那是 Renderer 层的职责），Renderer 不能直接处理手势（那是 Interaction 层的职责）。

3. **Renderer 单向依赖 Model**。Renderer 接收 GraphModel 的快照进行绘制，不持有 Model 引用。

4. **公开 API 必须通过 Index.ets 导出**。所有 `export` 声明集中在 `hmflowkit/src/main/ets/Index.ets`，不允许内部模块被外部直接 import。

5. **接口优先于实现**。每个模块先定义接口（`interface`），再写实现类。便于后续扩展（如插件机制）。

## 参考项目（学习对象，不引入依赖）

| 项目 | 借鉴内容 | 链接 |
|------|---------|------|
| **ofdkit-harmony** | ArkUI Canvas 渲染模式、分层架构、ohpm 发布方式 | gitee.com/notcoder/ofdkit-harmony |
| **LogicFlow** | GraphModel 设计、插件机制、Dagre 布局集成 | github.com/didi/LogicFlow |
| **bpmn.js** | diagram-js 与 bpmn-js 分离模式、BPMN 2.0 XML 解析 | github.com/bpmn-io/bpmn-js |
| **AntV X6** | Canvas 虚拟 DOM、Hit Testing、节点/边渲染管线 | github.com/antvis/X6 |

## 当前开发阶段

**Spec 01 — GraphModel ✅ 已完成**
- 268 行，7 项测试全部通过
- 不可变数据模式、序列化、级联删除

**Spec 02 — Canvas 渲染层 ✅ 已完成**
- ✅ NodeRenderer / EdgeRenderer / GridRenderer / CanvasManager / RenderConfig / HitTestManager
- ✅ 视觉 Demo 验证通过 + 14 项单元测试全部通过
- 共约 1350 行渲染层代码

**Spec 03 — BPMN 2.0 XML 解析器 ✅ 已完成**
- 507 行，12 项测试全部通过
- 支持命名空间前缀、6 种节点类型映射、BPMNShape 坐标、BPMNEdge waypoints
- 降级：无 DI 信息时使用默认坐标

**下一步：Spec 04 — Interaction 交互层**

## 禁止事项

- 禁止使用 WebView 加载 bpmn.js（这违背原生渲染的初衷）
- 禁止在 Renderer 中直接修改 GraphModel 数据
- 禁止引入任何 npm/ohpm 第三方依赖（MVP 阶段保持零依赖）
- 禁止节点位置硬编码——所有坐标来自 GraphModel 或 BPMN XML
- 禁止在单个文件中超过 500 行代码（保持模块粒度）

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 接口 | `I` 前缀 | `IGraphModel`, `INodeRenderer` |
| 类 | PascalCase | `GraphModel`, `NodeRenderer` |
| 方法 | camelCase | `addNode()`, `moveNode()` |
| 常量 | UPPER_SNAKE_CASE | `DEFAULT_NODE_WIDTH` |
| 文件 | PascalCase (类文件) | `GraphModel.ets` |
| 私有成员 | `_` 前缀 | `_nodes`, `_edges` |

## DevOps

### 编译桥接流程（BitFun ↔ DevEco Studio）

BitFun 运行在沙箱中，无法直接编译鸿蒙项目。通过 `build.sh` + `build.log` 实现编译结果的传递：

```
                    ┌──────────────────────────┐
                    │   你的 DevEco Studio       │
                    │                          │
                    │  1. 同步代码               │
                    │  2. sh build.sh           │
                    │     └→ 生成 build.log     │
                    └──────────┬───────────────┘
                               │
                    ┌──────────▼───────────────┐
                    │      BitFun 沙箱          │
                    │                          │
                    │  3. 读取 build.log        │
                    │  4. 分析错误 → 修复代码    │
                    └──────────────────────────┘
```

**操作步骤：**

1. 在 DevEco Studio 中同步项目：`File → Sync Project`
2. 打开 DevEco 底部 Terminal 面板
3. 运行 `sh build.sh`
4. 让 BitFun 读取 `build.log`：
   - 把 build.log 内容粘贴到对话中，或
   - 说 "读一下 build.log"（BitFun 会自动读取）

**build.sh 做了什么：**
- 调用 `hvigorw assembleHar` 编译库模块
- 调用 `hvigorw assembleHap` 编译 Demo 应用
- 全部输出写入 `build.log`，添加时间戳和 Git 信息
- 输出最终结果摘要：成功 / 失败 + 错误数量

### 其他操作

- 测试：DevEco Studio 内置测试框架，每个模块需有对应的 `.test.ets` 文件
- 发布：`ohpm publish` 到 OHPM 三方库中心仓
- 版本号：遵循 SemVer（当前 0.1.0）