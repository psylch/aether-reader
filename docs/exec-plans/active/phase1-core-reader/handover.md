---
title: "Phase 1 Handover: 核心阅读器"
description: Phase 1 当前进度、已知问题、设计决策踩坑记录
status: active
date: 2026-04-05
---

# Phase 1 Handover

## 当前状态

v1 (iOS 模式) 完全重写为 v2 (macOS 原生)。从零搭建了完整项目骨架，~70% Phase 1 功能已实现。Build 通过，40 单元测试全绿。

## 已完成

### 项目基础
- xcodegen (`project.yml`) 生成 xcodeproj，含 app + unit test + UI test + snapshot test 四个 target
- SwiftData 模型 (`PDFDocumentModel`, `BookmarkModel`)
- `AppState` (@Observable 全局状态)
- `FileService` (actor, PDF 导入/存储/删除到 Application Support)
- App 入口 + WindowGroup + MenuCommands (File/View/Go)

### 阅读器
- `PDFKitView` — NSViewRepresentable 包装 PDFView，观察页面/缩放变化
- `ReaderView` — NavigationSplitView + 工具栏 + .searchable + .inspector 预留
- 显示模式切换 (单页/连续/双页/双页连续)
- 缩放控制 (25%-200% 预设 + Fit Page + Fit Width + Actual Size)
- 外观切换 (日间/夜间/护眼/跟随系统)
- 键盘翻页 (Space)
- 阅读进度持久化

### 侧边栏
- `ThumbnailSidebarView` — LazyVStack + ScrollView，accent glow 选中态
- `OutlineSidebarView` — 递归 DisclosureGroup 渲染 PDFOutline
- `BookmarkSidebarView` — SwiftData CRUD，滑动删除，右键重命名
- Tab 切换用 toolbar Picker (segmented)

### Library
- `LibraryView` — LazyVGrid + .fileImporter + .onDrop + .searchable
- `LibraryGridItem` — 异步缩略图加载 + NSCache 缓存
- 排序 (名称/日期/大小/最近) + 右键菜单 + 属性 sheet

### 状态栏
- `StatusBarView` — 页码/文件名/进度/缩放，`.ultraThinMaterial` 模糊背景
- 页码点击弹出跳转 popover

### 测试
- `ReaderViewModelTests` — 20 tests (缩放/导航/搜索/显示模式)
- `AppStateTests` — 14 tests (状态管理/打开关闭文档)
- Snapshot test target 就绪 (placeholder)

## 未完成 (Phase 1 scope)

- 全屏幻灯片模式
- 页面旋转
- 自动滚动
- 最近打开列表
- 创建空白 PDF
- 窗口标签页 (macOS 原生 tab)
- Quick Look / Share Extension / Spotlight
- 打印支持
- 完整键盘快捷键覆盖 (目前只有 Space/Cmd+O/Cmd+±)

## 已知 UI 问题 (用户反馈，待修)

### 1. 工具栏按钮被挤到 overflow (>>)
**现象**: 展示模式和缩放按钮经常消失到 >> 菜单里。
**原因**: `.primaryAction` / `.secondaryAction` 在窗口不够宽时会被 macOS 自动折叠。
**尝试过**: `.principal` 放 HStack（被标题挤掉）、全放 `.primaryAction`（overflow）、`.secondaryAction`（也 overflow）。
**建议方向**: 可能需要用 `ToolbarItemGroup` 或自定义 NSToolbar delegate 来精确控制。

### 2. 初始缩放不生效
**现象**: 设了 actual size (100%) 但打开文档仍然是 fit-to-width 的大缩放。
**原因**: `DispatchQueue.main.async` 里设 scaleFactor，但 PDFView 可能还没完成 layout，autoScales 又覆盖了手动设置。
**建议方向**: 用 `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` 或监听 PDFView 的 frame 变化后再设置。

### 3. 侧边栏 tab picker 位置
**现象**: 从 sidebar 内部的 segmented control 移到了 toolbar，但在某些情况下不可见。
**建议方向**: 考虑放回 sidebar 顶部但用更原生的样式，或确认 toolbar placement 正确。

## Liquid Glass 设计踩坑记录

### 做了但效果不好的
1. **`.backgroundExtensionEffect()`** — 只适合全出血媒体(hero 图片)，对 PDF 白页+灰底产生灰糊糊的镜像，已移除
2. **`.toolbarBackgroundVisibility(.hidden)`** — 标题和工具栏项全部消失，过于激进
3. **手动 `.glassEffect(.regular, in: .capsule)` 在工具栏按钮上** — Apple 明确说不要这样做，工具栏按钮自动获得 glass
4. **颜色渐变叠加模拟模糊过渡** — `windowBackgroundColor` 在深色模式下是黑色，变成一条黑带

### 最终有效的方案
1. **`.ignoresSafeArea(edges: .top)`** — PDF 内容延伸到 toolbar 下方，系统 glass 自动模糊，效果最好
2. **`.ultraThinMaterial`** — StatusBarView 底部模糊背景
3. **`.scrollContentBackground(.hidden)`** — 侧边栏 List 去掉不透明背景，让 glass 透出
4. **不做 > 做错** — Liquid Glass 的核心是让系统自动处理，手动干预越多效果越差

### macOS 26 Liquid Glass 的现实
- Sidebar glass 在深色模式下**非常微妙**，几乎不透明——这是系统行为，不是 bug
- Apple Books 在深色模式下的 sidebar 同样几乎不透明
- Glass 采样的是 window 后面的内容(壁纸)，不是 app 内容
- 不要追 Apple 宣传图的效果，那是精心控制的环境

## 设计系统文档

- `docs/decisions/D001-liquid-glass-design-system.md` — 完整设计规范
- `docs/decisions/D002-testing-strategy.md` — 三层测试体系
- `docs/research/liquid-glass-api-reference.md` — API 速查 + 代码片段

## Phase 2-7 计划

7 个独立 Phase plan 已写好，星型依赖（都只依赖 Phase 1）：
- Phase 2: 标注系统
- Phase 3: 页面管理
- Phase 4: 内容编辑
- Phase 5: 表单与签名
- Phase 6: 格式转换与 OCR
- Phase 7: 安全、测量与 AI
