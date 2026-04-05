---
title: "Phase 1: 核心阅读器"
description: macOS 原生 PDF 阅读器骨架 — 阅读、侧边栏、Library、搜索、macOS 集成
status: active
date: 2026-04-05
depends-on: []
---

# Phase 1: 核心阅读器

所有后续 Phase 的基座。完成后 Aether Reader 是一个功能完整的 PDF 阅读器。

## v1 失败复盘

1. **iOS 导航模式照搬 macOS** — NavigationStack push/pop、底部浮动胶囊工具栏、所有功能用 sheet 弹出
2. **Glass 效果只是贴标签** — 在小按钮上加 `.glassEffect()` 不等于 Liquid Glass 设计语言
3. **功能像 demo 不像产品** — 没有侧边栏、没有标注、没有多标签页、没有拖拽导入、没有状态栏
4. **先做 iOS 再移植 Mac** — 方向就错了，应该从一开始就是 macOS 原生设计

## 设计原则

- **macOS 原生** — NavigationSplitView、侧边栏、原生工具栏、菜单栏、键盘快捷键
- **Glass 是架构不是装饰** — 工具栏区域、侧边栏、状态栏整体使用系统 glass 材质
- **macOS 26 Tahoe** — 链接 SDK 后系统 chrome 自动获得 Liquid Glass

## 目标架构

```
┌──────────────────────────────────────────────────────────┐
│ Toolbar: [◀ ▶] [Zoom ─●─] [Search...]    [Display ▾]    │  ← 系统工具栏 (auto glass)
├────────────┬─────────────────────────────────────────────┤
│  Sidebar   │                                             │
│ ──────────│                                             │  ← 系统侧边栏 (auto glass)
│ Thumbnails │              PDF Content                    │
│   [p1]     │                                             │
│   [p2] ◄── │              (PDFView)                      │
│   [p3]     │                                             │
│ ──────────│                                             │
│ Outline    │                                             │
│  ▸ Ch 1    │                                             │
│  ▾ Ch 2    │                                             │
│    § 2.1   │                                             │
│ ──────────│                                             │
│ Bookmarks  │                                             │
│  ★ p.5     │                                             │
├────────────┴─────────────────────────────────────────────┤
│ Page 2 / 120  │  Report.pdf  │  45%  │  125%             │  ← glass 状态栏
└──────────────────────────────────────────────────────────┘
```

Library 模式：
```
┌──────────────────────────────────────────────────────────┐
│ Toolbar: [Import] [Sort ▾]                [Search...]    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│   ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐               │
│   │ PDF  │  │ PDF  │  │ PDF  │  │ PDF  │               │
│   └──────┘  └──────┘  └──────┘  └──────┘               │
│   doc1.pdf  doc2.pdf  doc3.pdf  doc4.pdf               │
│                                                          │
│        Drag & drop PDF files here to import              │
└──────────────────────────────────────────────────────────┘
```

## 技术决策

- **平台**: macOS 26.0 (Tahoe) only
- **框架**: SwiftUI + PDFKit (NSViewRepresentable)
- **架构**: MVVM + @Observable
- **数据层**: SwiftData 元数据 + Application Support 存 PDF
- **窗口**: WindowGroup + .commands 菜单栏
- **导航**: NavigationSplitView (侧边栏 + 详情)
- **零第三方依赖**

## Liquid Glass 策略

### 自动获得 (链接 macOS 26 SDK)
- 窗口标题栏/工具栏区域
- NavigationSplitView 侧边栏
- .sheet / .popover chrome
- 系统菜单

### 手动应用
- 底部状态栏: `.background(.bar)` 或 `.glassEffect()`
- 浮动面板: `.background(.liquidGlass)`

### 不应用 (HIG)
- PDF 内容区域
- Library 网格项

## 功能清单

### 阅读
- [x] PDF 渲染 (NSViewRepresentable + PDFView)
- [x] 显示模式: 单页 / 连续滚动 / 双页 / 双页连续
- [ ] 全屏幻灯片演示模式 (Slide Show)
- [x] 缩放 (菜单: 25%-200% + Fit Page + Fit Width + Actual Size + Cmd+/-)
- [ ] 页面旋转 (90° / 180° / 270°)
- [x] 外观: 日间 / 夜间 / 护眼 / 跟随系统
- [x] 键盘翻页 (Space)
- [ ] 自动滚动 (可调速)
- [x] 阅读进度记忆

### 侧边栏
- [x] 缩略图面板 (垂直列表)
- [x] 目录/大纲导航 (可折叠树)
- [x] 书签列表 (添加/删除/重命名/跳转)

### 搜索
- [x] 全文搜索 (.searchable)
- [x] 搜索结果高亮
- [x] 结果间导航 (上/下一个)

### 文档管理 (Library)
- [x] 文件导入 (.fileImporter)
- [x] 拖拽导入 (.onDrop)
- [ ] 最近打开
- [x] 排序 (名称 / 日期 / 大小 / 最近)
- [x] 右键菜单 (打开 / 删除 / 在 Finder 中显示 / 属性)
- [x] PDF 属性查看 (元数据)
- [ ] 创建空白 PDF

### macOS 集成
- [x] 菜单栏 (File/View/Go 菜单)
- [x] 键盘快捷键 (部分: Cmd+O/+/-/0, Space)
- [ ] 窗口标签页 (macOS 原生 tab)
- [x] 状态栏 (页码 / 文件名 / 进度 / 缩放, ultraThinMaterial)
- [ ] Quick Look 预览扩展
- [ ] Share Extension
- [ ] Spotlight 索引
- [ ] 打印支持

### 已知 UI 微调项
- [ ] 工具栏按钮布局：展示模式/缩放按钮位置调整（目前被挤到 overflow）
- [ ] 初始缩放表现不稳定（Actual Size 设置时机问题）
- [ ] 侧边栏 tab picker 位置优化

## 实施步骤

### Step 1: 项目骨架
- project.yml (macOS 26 target)
- AetherReaderApp + WindowGroup + .commands
- SwiftData 模型 (PDFDocument metadata)
- ContentView (Library ↔ Reader 路由)

### Step 2: 核心阅读
- PDFKitView (NSViewRepresentable wrapping PDFView)
- ReaderView (NavigationSplitView + toolbar)
- 显示模式切换 + 缩放 + 翻页 + 旋转
- StatusBarView (glass 状态栏)
- 外观切换

### Step 3: 侧边栏
- ThumbnailSidebarView (缩略图)
- OutlineSidebarView (目录树)
- BookmarkSidebarView (书签)

### Step 4: Library
- LibraryView (网格 + 空状态)
- 文件导入 + 拖拽导入
- FileService (Application Support 存储)
- 排序 + 右键菜单 + 最近打开

### Step 5: 搜索 + macOS 集成
- .searchable 全文搜索
- 菜单栏 + 键盘快捷键
- 窗口标签页
- 打印 + Quick Look + Share + Spotlight
