---
title: Phase 1 MVP 实现计划
description: Aether Reader 从零搭建到可用 MVP 的完整实施计划，含文件清单、实施顺序、风险缓解
status: active
date: 2026-04-05
---

# Aether Reader — Phase 1 MVP 实现计划

## Context

构建一个开源 PDF 阅读器，采用 iOS 26 Liquid Glass 设计语言，定位为"研究者和深度阅读者的美观阅读工具"。当前项目为空，需要从零搭建。

## 技术决策

- **SwiftUI + PDFKit** (UIViewRepresentable 桥接)
- **MVVM + @Observable** (iOS 26 only)
- **SwiftData** 存元数据，文件系统存 PDF
- **XcodeGen** 生成 .xcodeproj (CLI 环境下无 Xcode GUI)
- **Feature-based** 文件夹结构，不过早模块化
- **零第三方依赖** (Phase 1)

## 导航架构

```
AetherReaderApp (@main)
  └─ NavigationStack
       ├─ LibraryView (root) — PDF 网格 + 导入
       └─ ReaderView (push) — 阅读 + 工具栏 + 各种 sheet
```

文档型 app 用 `NavigationStack`，不用 `TabView`（省屏幕空间给文档）。

## 文件清单 (~35 个文件, ~2,100-2,500 行)

### Layer 0: 项目骨架
| 文件 | 用途 |
|------|------|
| `project.yml` | XcodeGen 项目定义 |
| `AetherReader/App/AetherReaderApp.swift` | @main 入口 + ModelContainer |
| `AetherReader/Resources/Assets.xcassets` | 图标、强调色 |

### Layer 1: SwiftData 模型
| 文件 | 用途 |
|------|------|
| `Core/Persistence/PDFDocumentRecord.swift` | PDF 元数据 (fileName, storagePath, lastReadPage, pageCount, thumbnailData) |
| `Core/Persistence/Bookmark.swift` | 书签 (pageIndex, label, createdDate) → cascade 关联到 PDFDocumentRecord |

### Layer 2: Service 层
| 文件 | 用途 |
|------|------|
| `Core/Protocols/FileServiceProtocol.swift` | PDF 导入/存储协议 |
| `Core/Protocols/BookmarkServiceProtocol.swift` | 书签 CRUD 协议 |
| `Core/Protocols/ThumbnailCacheProtocol.swift` | 缩略图缓存协议 |
| `Core/Services/FileService.swift` | 安全作用域资源处理、复制到沙盒 |
| `Core/Services/BookmarkService.swift` | SwiftData CRUD |
| `Core/Services/ThumbnailCacheService.swift` | NSCache (countLimit:100, 50MB) + 内存警告清理 |
| `App/DependencyContainer.swift` | 依赖注入 |

### Layer 3: PDFKit 桥接 (关键路径)
| 文件 | 用途 |
|------|------|
| `Features/Reader/Views/PDFKitView.swift` (~180行) | UIViewRepresentable + Coordinator，防无限循环 |
| `Features/Reader/ViewModels/ReaderViewModel.swift` (~200行) | @Observable：文档状态、翻页、缩放、搜索、显示模式 |

### Layer 4: 功能视图
| 文件 | 用途 |
|------|------|
| `Features/Reader/Views/ReaderView.swift` | 主阅读界面：PDFKitView + glass 工具栏 + overlay |
| `Features/Reader/Views/ReaderToolbar.swift` | 底部浮动 glass 工具栏 |
| `Features/Reader/Views/PageIndicatorView.swift` | "Page X / Y" glass 胶囊 |
| `Features/Reader/Views/DisplayModeSheet.swift` | 日间/夜间、滚动模式、缩放 |
| `Features/Library/ViewModels/LibraryViewModel.swift` | @Observable：文件列表、导入、删除、排序 |
| `Features/Library/Views/LibraryView.swift` | PDF 网格 + .fileImporter + 空状态 |
| `Features/Library/Views/PDFGridItemView.swift` | 网格项：缩略图 + 标题 + 进度条 |
| `Features/Search/ViewModels/SearchViewModel.swift` | 搜索文本、结果导航、高亮标注管理 |
| `Features/Search/Views/SearchOverlayView.swift` | 顶部下滑搜索栏 + 结果计数 + 上下导航 |
| `Features/Outline/ViewModels/OutlineViewModel.swift` | 解析 PDFOutline 为树/列表 |
| `Features/Outline/Views/OutlineView.swift` | DisclosureGroup 递归目录 |
| `Features/Thumbnails/ViewModels/ThumbnailStripViewModel.swift` | 懒加载缩略图 |
| `Features/Thumbnails/Views/ThumbnailStripView.swift` | 水平 LazyHStack 缩略图条 |

### Layer 5: 共享 UI
| 文件 | 用途 |
|------|------|
| `UI/Components/EmptyStateView.swift` | "还没有 PDF" + 导入按钮 |
| `UI/Components/GlassToolbarButton.swift` | 可复用 glass 工具栏按钮 |
| `UI/Components/LoadingOverlay.swift` | 全屏加载指示器 |
| `UI/Theme/AppTheme.swift` | 色彩常量、外观模式枚举 |
| `UI/Extensions/View+Glass.swift` | `.glassBackground()` 便利修饰器 |
| `UI/Extensions/PDFDocument+Extensions.swift` | outline 展平、文件大小等 |

## Liquid Glass 集成点

| 位置 | 处理方式 |
|------|---------|
| NavigationBar (LibraryView) | 自动 (链接 iOS 26 SDK) |
| 底部工具栏 (ReaderView) | `.glassEffect(in: .capsule)` |
| 页码指示器 | `.glassEffect(in: .capsule)` |
| 搜索栏 | `.background(.liquidGlass)` |
| Sheet chrome | 自动 (系统 .sheet) |
| 空状态按钮 | `.buttonStyle(.glass)` |
| 书签激活态 | `.glassEffectTint(.accentColor)` |
| ❌ Library 网格项 | 不用 glass (HIG：内容区不用) |
| ❌ PDF 内容区 | 不用 glass |

## 实施顺序

### Sprint 1: 基础 (项目 + 模型 + 服务)
1. `brew install xcodegen` → 创建 `project.yml` → `xcodegen generate`
2. AetherReaderApp.swift + ModelContainer
3. SwiftData 模型 (PDFDocumentRecord, Bookmark)
4. Service 协议 + 实现
5. ✅ 验证：app 编译启动到空屏

### Sprint 2: 核心阅读 (最高风险)
1. **PDFKitView** — UIViewRepresentable + Coordinator + 防循环
2. ReaderViewModel
3. ReaderView + 基础工具栏 + PageIndicator
4. ✅ 验证：硬编码 PDF URL，可阅读翻页

### Sprint 3: 书库
1. LibraryViewModel + LibraryView + PDFGridItemView
2. EmptyStateView
3. 导航：Library → Reader
4. ✅ 验证：导入 PDF → 打开阅读

### Sprint 4: 搜索 + 目录
1. SearchViewModel + SearchOverlayView
2. OutlineViewModel + OutlineView
3. 搜索高亮接入 PDFKitView
4. ✅ 验证：全文搜索 + 目录跳转

### Sprint 5: 缩略图 + 书签 + 外观
1. ThumbnailStripViewModel + ThumbnailStripView
2. 书签 toggle 接入工具栏
3. DisplayModeSheet (日/夜/自动，滚动模式)
4. AppTheme + glass 效果全面应用
5. ✅ 验证：完整 MVP 流程

### Sprint 6: 集成测试
1. 端到端流程测试
2. 大文件内存 profiling (500+ 页)
3. 无障碍审计 (VoiceOver, 增强对比度, 减少透明度)
4. 边界情况：加密 PDF、无目录 PDF、空文件

## 关键风险

| 风险 | 缓解 |
|------|------|
| updateUIView 无限循环 | `isUpdatingFromSwiftUI` 标志 + 值相等检查 |
| 缩略图内存泄漏 | NSCache 限制 + 内存警告清理 |
| 大文档搜索卡顿 | `Task.detached` 后台搜索 |
| Swift 6.2 严格并发 | `@MainActor` + `@preconcurrency import PDFKit` |

## 验证方式

1. `xcodegen generate` 成功生成 .xcodeproj
2. `xcodebuild build -scheme AetherReader -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 编译通过
3. 模拟器中运行：导入 PDF → 阅读 → 搜索 → 目录 → 缩略图 → 书签 → 切换外观
4. Instruments: Allocations 检查大文件内存
