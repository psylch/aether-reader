---
title: Liquid Glass API 与代码参考
description: 从开源仓库和 WWDC25 整理的 Liquid Glass SwiftUI API、代码模式、macOS 专属行为
status: active
date: 2026-04-05
related: [D001-liquid-glass-design-system]
---

# Liquid Glass API 与代码参考

来源：Apple WWDC25 Session 219/323/310、conorluddy/LiquidGlassReference、artemnovichkov/iOS-26-by-Examples

---

## 1. 核心 API 速查

### `.glassEffect(_:in:isEnabled:)`

主修饰符，对任意 View 应用 glass。

```swift
Text("Hello")
    .padding()
    .glassEffect(.regular, in: .capsule)

// 带条件开关 — 用 .identity 而非 if-else
Text("Hello")
    .padding()
    .glassEffect(isActive ? .regular : .identity, in: .capsule)
```

### `GlassEffectContainer`

多个 glass 元素的容器，统一背景采样 O(1)。**性能必需品。**

```swift
GlassEffectContainer {
    HStack(spacing: 8) {
        Button("Highlight") { }
            .glassEffect(.regular, in: .capsule)
        Button("Underline") { }
            .glassEffect(.regular, in: .capsule)
        Button("Note") { }
            .glassEffect(.regular, in: .capsule)
    }
}
```

### `.glassEffectID(_:in:)` + `@Namespace`

Morphing 过渡动画 — 同 ID 的 glass 元素在状态切换时流畅变形。

```swift
@Namespace private var ns

// 切换时 glass 形状平滑过渡
if showExpanded {
    ExpandedToolbar()
        .glassEffectID("toolbar", in: ns)
} else {
    CompactToolbar()
        .glassEffectID("toolbar", in: ns)
}
```

### `.glassEffectUnion(id:namespace:)`

合并视觉上分离但逻辑相关的 glass 元素为一个整体。

```swift
@Namespace private var ns

VStack(spacing: 20) {
    TopBar()
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        .glassEffectUnion(id: "chrome", namespace: ns)
    BottomBar()
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        .glassEffectUnion(id: "chrome", namespace: ns)
}
```

### `.glassEffectTransition(_:isEnabled:)`

控制 glass 元素的出现/消失过渡。

```swift
Button("Action") { }
    .glassEffect(.regular, in: .capsule)
    .glassEffectTransition(.materialize)  // 凝聚出现效果
```

### `.backgroundExtensionEffect()`

允许 glass view 视觉上扩展到 safe area 之外。

```swift
StatusBar()
    .glassEffect(.regular, in: .rect)
    .backgroundExtensionEffect()
```

## 2. Glass 变体与修饰链

```swift
// 三种基础变体
Glass.regular        // 默认，中等透明度
Glass.clear          // 高透明度，媒体背景用
Glass.identity       // 无效果，条件切换用

// 修饰链
Glass.regular
    .tint(.blue)           // 语义色调（仅主要操作）
    .interactive()         // 触摸/悬停缩放弹跳微光反馈
```

## 3. 按钮样式

**不要在 Button 上手动加 `.glassEffect()` — 使用系统 glass 按钮样式。**

```swift
// glass 按钮 — 浮动面板内自定义按钮
Button("Save") { }
    .buttonStyle(.glass)

// 强调 glass 按钮 — 确认操作、confirmationAction
Button("Apply") { }
    .buttonStyle(.glassProminent)

// 透明 glass — 媒体丰富背景
Button("Play") { }
    .buttonStyle(.glass(.clear))

// 带 tint — 破坏性操作
Button("Delete") { }
    .buttonStyle(.glass)
    .tint(.red)

// macOS AppKit
// NSButton.BezelStyle.glass
```

### 工具栏按钮 — ��需要手动样式

工具栏内的按钮**自动获得 glass**，无需任何手动修饰：

```swift
// ✅ 正确 — 工具栏按钮自动 glass
ToolbarItem(placement: .principal) {
    Button { } label: { Image(systemName: "magnifyingglass") }
}

// ❌ 错误 — 不要在工具栏按钮上加 .glassEffect
ToolbarItem(placement: .principal) {
    Button { } label: { Image(systemName: "magnifyingglass") }
        .glassEffect(.regular, in: .capsule)  // 删掉！
}
```

## 4. 工具栏

```swift
.toolbar {
    // 导航区
    ToolbarItem(placement: .navigation) {
        HStack {
            Button(action: goBack) { Image(systemName: "chevron.left") }
            Button(action: goForward) { Image(systemName: "chevron.right") }
        }
    }

    // 模式工具区 — GlassEffectContainer 包裹
    ToolbarItem(placement: .principal) {
        GlassEffectContainer {
            // 内容根据 ToolbarMode 切换
        }
    }

    // 弹性间距
    ToolbarSpacer(.flexible)

    // 全局工具
    ToolbarItem(placement: .primaryAction) {
        Button(action: toggleSearch) { Image(systemName: "magnifyingglass") }
    }
}
```

`ToolbarSpacer` 两种模式：
```swift
ToolbarSpacer(.flexible)  // 弹性填充剩余空间
ToolbarSpacer(.fixed)     // 固定间距
```

## 5. NavigationSplitView (macOS)

编译 macOS 26 SDK 后侧边栏自动获得浮动 glass。

```swift
NavigationSplitView {
    // Sidebar — 自动 glass，无需手动修饰
    List(selection: $selectedSection) {
        Section("Thumbnails") { ... }
        Section("Outline") { ... }
        Section("Bookmarks") { ... }
    }
    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
} detail: {
    // Detail — 内容层，不加 glass
    PDFContentView()
}
```

### Inspector 侧边栏

```swift
NavigationSplitView { ... } detail: {
    PDFContentView()
        .inspector(isPresented: $showInspector) {
            // Inspector 内容 — 自动 glass
            // macOS 上切入工具栏空间，注意圆角会占用可用区域
            InspectorContent(selection: selectedAnnotation)
        }
}
```

## 6. Sheet / Popover

编译 macOS 26 SDK 后自动 inset glass。**迁移注意：移除旧的自定义背景。**

```swift
// ✅ 正确 — 让系统处理
.sheet(isPresented: $showSettings) {
    SettingsView()
}

// ❌ 错误 — 旧代码需移除
.sheet(isPresented: $showSettings) {
    SettingsView()
        .presentationBackground(.ultraThinMaterial)  // 删掉
}
```

## 7. TabView 增强

```swift
TabView {
    Tab("Library", systemImage: "books.vertical") { LibraryView() }
    Tab("Reader", systemImage: "doc.text") { ReaderView() }
    Tab(role: .search) { SearchView() }  // 搜索角色 → 浮动搜索按钮
}
.tabBarMinimizeBehavior(.onScroll)       // 滚动时自动缩小
.tabBarBottomAccessory {                 // 底部附件
    NowPlayingBar()
}
```

## 8. macOS 专属行为

| 行为 | 说明 |
|------|------|
| 窗口同心圆角 | glass 自动对齐窗口边框圆角 |
| 自适应搜索栏 | 高度随窗口尺寸调整 |
| 更高控件尺寸 | 适配鼠标精确操作 (vs iOS 触摸) |
| Stage Manager 集成 | glass 在多窗口场景下正确折射 |
| 侧边栏浮动 | NavigationSplitView sidebar 浮于 detail 之上 |
| Inspector 切入 toolbar | `.inspector()` 内容区域的圆角会占用工具栏空间 |
| 菜单栏透明 | 系统菜单栏完全透明 + glass |

## 9. 迁移检查清单

```
移除项：
- [ ] .ultraThinMaterial / .thinMaterial / .regularMaterial → 改用 .glassEffect()
- [ ] .presentationBackground() 自定义颜色 → 删除，让系统处理
- [ ] 手动 blur + overlay 模拟 glass → 删除
- [ ] .background(.bar) 旧用法 → 视情况改用 .glassEffect()

新增项：
- [ ] 多 glass 元素 → GlassEffectContainer 包裹
- [ ] 条件 glass → .identity 变体
- [ ] 按钮 → .buttonStyle(.glass) / .glassProminent
- [ ] 工具栏间距 → ToolbarSpacer(.flexible)
```

## 10. 参考仓库

| 仓库 | 价值 | 注意 |
|------|------|------|
| conorluddy/LiquidGlassReference | ⭐⭐⭐ 最全 API 文档 + 设计原则 | 参考文档为主，代码示例需验证 |
| artemnovichkov/iOS-26-by-Examples | ⭐⭐ API 用法示例 | 仅 iOS，无 macOS 示例 |
| muhittincamdali/SwiftUI-iOS26-Showcase | ⭐ 60+ demo 但多为 polyfill | 大量 `.ultraThinMaterial` 模拟，非真正 API |

## 11. WWDC25 必看 Session

| Session | 内容 |
|---------|------|
| 219 Meet Liquid Glass | 设计哲学 + 四大特性 (Lensing/Materialization/Fluidity/Adaptivity) |
| 323 Build a SwiftUI app with the new design | SwiftUI 全流程适配 |
| 310 Build an AppKit app with the new design | AppKit 适配 (NSViewRepresentable 可能需要) |
