---
title: macOS 原生设计，不是 iOS 移植
description: 决定从一开始就按 macOS 原生模式设计，而非先做 iOS 再移植
status: active
date: 2026-04-05
---

# D001: macOS 原生设计

## 决策

Aether Reader 首先是 macOS 原生应用，使用 macOS 原生导航模式和组件。

## 背景

v1 实现犯了严重错误：用 iOS 导航模式 (NavigationStack push/pop、底部浮动工具栏、sheet 弹出所有面板) 构建 macOS app。结果看起来像"Mac 端拙劣的 iOS PDFViewer 模拟器"。

## 具体规则

| 维度 | ❌ 不要 (iOS 模式) | ✅ 要 (macOS 模式) |
|------|-------------------|-------------------|
| 导航 | NavigationStack push/pop | NavigationSplitView 侧边栏+详情 |
| 工具栏 | 底部浮动胶囊 `.glassEffect(in: .capsule)` | 系统窗口工具栏 `.toolbar {}` |
| 面板 | 所有功能用 `.sheet` 弹出 | 侧边栏 section / popover / inspector |
| 搜索 | 自定义 overlay 下滑搜索栏 | `.searchable()` 修饰器 |
| 页码 | 浮动胶囊覆盖在内容上 | 底部状态栏 |
| 返回 | 自定义玻璃圆形返回按钮 | 工具栏标准返回 / 菜单栏 |
| Glass | 在小按钮上贴 `.glassEffect()` | 系统 chrome 整体自动 glass |
