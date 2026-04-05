---
title: "D001: Liquid Glass 设计系统规范"
description: 定义 Aether Reader 全局设计系统 — Glass 层级、工具栏、侧边栏、面板、扩展协议
status: active
date: 2026-04-05
related: [phase1-core-reader, phase2-annotation, phase3-page-management]
---

# D001: Liquid Glass 设计系统规范

本文档定义 Aether Reader 的设计基座。Phase 1 建立，Phase 2-7 继承。

## 调研来源

- Apple HIG: Liquid Glass / Adopting Liquid Glass
- WWDC25 Session 219 (Meet Liquid Glass), 323 (SwiftUI), 310 (AppKit)
- conorluddy/LiquidGlassReference (社区最全参考)
- artemnovichkov/iOS-26-by-Examples (API 示例)

---

## 1. 分层架构（最高优先级原则）

```
┌─────────────────────────────────┐
│  Glass 层 — 导航/控件/工具      │  ← Liquid Glass 专属
├─────────────────────────────────┤
│  内容层 — 文档/列表/媒体        │  ← 永远不加 Glass
└─────────────────────────────────┘
```

**硬性规则：Glass 只属于导航层，永不用于内容层。**

| 属于 Glass 层 | 属于内容层 |
|--------------|-----------|
| 工具栏 (Toolbar) | PDF 渲染区 |
| 侧边栏 (Sidebar) | Library 网格项 |
| 状态栏 | 标注内容本身 |
| Sheet / Popover / Menu | 列表数据行 |
| 浮动工具面板 | 表单填写区域 |
| 确认/操作按钮 | 文本编辑区域 |

## 2. Glass 变体选择

| 变体 | 透明度 | 何时用 |
|------|--------|--------|
| `.regular` | 中等 | **默认选择** — 工具栏、侧边栏、浮动面板、状态栏 |
| `.clear` | 高 | 媒体丰富背景 + 粗体前景时（如全屏幻灯片模式覆盖控件） |
| `.identity` | 无效果 | 条件切换 Glass 开关，替代 `if-else` 重建视图 |

**Tint 规则：** 仅对主要操作按钮用 `.tint()`（如"应用涂黑"用红色 tint）。不要给所有元素加 tint。

## 3. 自动 vs 手动 Glass

### 自动获得（Xcode 26 编译即可）
- 窗口标题栏 / 工具栏区域
- NavigationSplitView 侧边栏（浮动 glass，自动折射背景内容）
- TabView 标签栏
- Sheet / Popover / Menu chrome
- 系统菜单栏
- 导航堆栈的 fluid morphing 过渡

### 手动应用
- **底部状态栏**: `.glassEffect(.regular, in: .rect)`
- **浮动工具面板** (标注/测量/形状): `.glassEffect(.regular, in: .rect(cornerRadius: 12))`
- **操作按钮**: `.buttonStyle(.glass)` 或 `.buttonStyle(.glassProminent)`（确认操作）
- **自定义弹出面板**: `.glassEffect(.regular, in: .rect(cornerRadius: 16))`

### backgroundExtensionEffect 使用条件
- **仅用于全出血媒体内容** — hero 图片、视频预览等需要视觉延伸到 sidebar 下方的场景
- **不用于文档/列表类内容** — PDF 白页+灰底用这个只会产生灰色模糊，效果很差
- Aether Reader 的 PDF 内容区域 **不使用** backgroundExtensionEffect

### 迁移禁令
- 不使用 `.ultraThinMaterial` / `.thinMaterial`（旧 API）
- 不使用 `.presentationBackground()` 自定义 sheet 背景色
- 不手动叠加 blur + overlay 模拟 glass
- 不在 sidebar 内使用自定义 `listRowBackground` 或 `VStack` 容器包裹（会阻断 glass）

## 4. 性能规则

**`GlassEffectContainer` 是必需品，不是便利封装。**

多个 glass 元素共存时，每个元素独立采样背景 = O(N) GPU 开销。`GlassEffectContainer` 统一采样 = O(1)。

```swift
// ✅ 正确
GlassEffectContainer {
    HStack {
        Button("Highlight") { ... }
            .glassEffect(.regular, in: .capsule)
        Button("Underline") { ... }
            .glassEffect(.regular, in: .capsule)
    }
}

// ❌ 错误 — 每个按钮独立采样，GPU 线性增长
HStack {
    Button("Highlight") { ... }
        .glassEffect(.regular, in: .capsule)
    Button("Underline") { ... }
        .glassEffect(.regular, in: .capsule)
}
```

规则：
- 同一视觉区域内 ≥2 个 glass 元素 → 必须 `GlassEffectContainer` 包裹
- 用 `.glassEffectUnion(id:namespace:)` 合并视觉上分离但逻辑相关的 glass 元素
- 用 `.identity` 做条件切换，不用 `if-else` 重建视图

## 5. 工具栏规范

### 布局分区

```
┌──────────────────────────────────────────────────────────┐
│ [◀ ▶]  │  [模式工具区]  │  ToolbarSpacer  │  [搜索/全局] │
│ 导航区  │  上下文工具    │    弹性间距      │  固定工具     │
└──────────────────────────────────────────────────────────┘
```

- **导航区** (leading): 前进/后退，始终可见
- **模式工具区** (leading, 导航后): 根据当前模式变化的工具
- **弹性间距**: `ToolbarSpacer(.flexible)`
- **全局工具区** (trailing): 搜索、显示设置，始终可见

### 模式切换

| 模式 | 模式工具区内容 |
|------|---------------|
| 阅读 (默认) | [缩放 slider] [显示模式] |
| 标注 (Phase 2) | [高亮 ▾] [形状 ▾] [墨迹] [图章] [橡皮] |
| 编辑 (Phase 4) | [文本] [图片] [链接] |
| 表单 (Phase 5) | [选择] [文本框] [复选框] [签名] |
| 测量 (Phase 7) | [距离] [面积] [角度] [校准] |

工具栏 `confirmationAction` 角色的按钮自动升级为 `.glassProminent`。

### Phase 1 暴露的扩展点

```swift
// Phase 1 定义 ToolbarMode enum，后续 Phase 扩展
enum ToolbarMode: String, CaseIterable {
    case reading    // Phase 1
    // case annotating // Phase 2 添加
    // case editing    // Phase 4 添加
    // case form       // Phase 5 添加
    // case measuring  // Phase 7 添加
}
```

## 6. 侧边栏规范

### Section 结构

```
Sidebar (NavigationSplitView, 自动 glass)
├── 缩略图    ← Phase 1
├── 目录      ← Phase 1
├── 书签      ← Phase 1
├── 标注列表  ← Phase 2 注入
├── 表单域    ← Phase 5 注入
├── 测量结果  ← Phase 7 注入
└── AI 对话   ← Phase 7 注入
```

### 扩展机制

```swift
// Phase 1 定义 SidebarSection protocol
protocol SidebarSection: Identifiable {
    associatedtype Body: View
    var title: String { get }
    var icon: String { get }  // SF Symbol name
    var isAvailable: Bool { get }  // 根据文档状态决定是否显示
    @ViewBuilder var content: Body { get }
}
```

Phase 2-7 各自实现 `SidebarSection`，注册到 SidebarView。

## 7. 浮动面板规范

标注工具选择器、颜色选择器、图章选择器、测量设置等都需要浮动面板。

### 统一样式

```swift
// FloatingPanel — 所有 Phase 共用的浮动面板容器
struct FloatingPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}
```

### 定位规则
- 浮动面板锚定到触发它的工具栏按钮下方
- 不遮挡 PDF 内容中心区域
- 支持拖拽重定位
- ESC 关闭

## 8. Inspector (属性面板) 规范

标注属性、表单域属性、图片属性等编辑场景用 Inspector 侧边栏。

```
┌────────┬──────────────────────┬───────────┐
│Sidebar │     PDF Content      │ Inspector │
│ (glass)│                      │  (glass)  │
│        │                      │           │
│        │                      │ 颜色: ●●● │
│        │                      │ 粗细: ─●─ │
│        │                      │ 透明: ─●─ │
└────────┴──────────────────────┴───────────┘
```

- 使用 `.inspector(isPresented:)` modifier — macOS 上自动切入工具栏空间
- Inspector 内容根据选中对象动态切换
- Phase 1 不实现 Inspector，但 ReaderView 布局需预留 `.inspector()` 挂载点

## 9. 状态栏规范

```
┌─────────────────────────────────────────────────────────┐
│ Page 2/120 │ Report.pdf │ 阅读 45% │ 125% │ [模式指示] │
│ 页码导航    │ 文件名      │ 进度      │ 缩放  │ 扩展区    │
└─────────────────────────────────────────────────────────┘
```

- 使用 `safeAreaBar(edge: .bottom)` 注册到系统 — 自动获得 scroll edge effect
- **不要手动加 `.glassEffect()`** — 系统 safe area bar 自行处理
- 扩展区供后续 Phase 注入状态信息（标注模式、OCR 进度、AI 状态等）
- 点击页码 → 跳转输入框

## 10. 按钮样式规范

**硬性规则：不要为按钮创建自定义 Liquid Glass 效果（不要在 Button 上加 `.glassEffect()`），使用系统提供的 glass 按钮样式。**

| 场景 | 样式 | 说明 |
|------|------|------|
| 工具栏按钮 | 系统默认 | Toolbar 内自动获得 glass |
| 强调操作按钮 | `.buttonStyle(.glassProminent)` | confirmationAction 自动升级 |
| 浮动面板内按钮 | `.buttonStyle(.glass)` | 自定义 glass chrome 内 |
| 透明 glass 按钮 | `.buttonStyle(.glass(.clear))` | 媒体丰富背景 |
| 破坏性操作 | `.buttonStyle(.glass)` + `.tint(.red)` | |
| 内容区操作按钮 | `.buttonStyle(.borderedProminent)` | 不用 glass |

### 工具栏内禁止事项
- **不混用文字和图标** — 同一工具栏组内统一用图标
- **不在工具栏按钮上加 `.glassEffect()`** — 系统自动处理
- **不手动 `GlassEffectContainer` 包裹工具栏** — 工具栏已自带 glass
- **隐藏工具栏项时隐藏 ToolbarItem，不隐藏内部 View**

## 11. 动画与过渡

- **Glass morphing**: 用 `.glassEffectID(_:in:)` + `@Namespace` 实现工具栏模式切换时的平滑过渡
- **Materialize 过渡**: `.glassEffectTransition(.materialize)` 控制 glass 元素出现/消失
- **Sheet 内容**: 移除自定义过渡，让系统 glass sheet 自行处理
- **侧边栏折叠**: NavigationSplitView 原生动画

## 12. Morphing 过渡示例

工具栏模式切换时，按钮组可以流畅变形：

```swift
@Namespace private var toolbarNamespace

// 阅读模式工具
GlassEffectContainer {
    if mode == .reading {
        zoomSlider
            .glassEffectID("primary-tools", in: toolbarNamespace)
    }
    // 标注模式工具 (Phase 2)
    if mode == .annotating {
        annotationToolbar
            .glassEffectID("primary-tools", in: toolbarNamespace)
    }
}
```

同一个 `glassEffectID` 在模式切换时自动 morphing 过渡。
