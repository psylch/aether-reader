---
title: "D002: 自动化测试策略"
description: 三层测试体系 — 单元测试 + XCUITest 截图 + 快照回归，覆盖逻辑和视觉
status: active
date: 2026-04-05
related: [D001-liquid-glass-design-system, phase1-core-reader]
---

# D002: 自动化测试策略

## 核心目标

1. **逻辑正确性** — ViewModel、Service、数据层的行为符合预期
2. **用户流程可用** — 关键路径走得通（导入→打开→翻页→搜索→书签）
3. **视觉忠实度** — Liquid Glass 设计系统的视觉输出不退化

## 三层测试体系

### Layer 1: 单元测试 (Swift Testing)

```
目标: ViewModel、Service、数据模型的纯逻辑
框架: Swift Testing (@Test, #expect)
运行: xcodebuild test -scheme AetherReader -destination 'platform=macOS'
```

覆盖范围:
- PDFDocumentService (打开/关闭/元数据读取)
- LibraryViewModel (排序/筛选/导入)
- ReaderViewModel (页码导航/缩放/显示模式切换)
- BookmarkManager (增删改查)
- SearchService (搜索结果解析)
- 后续 Phase: AnnotationViewModel, PageManagementService, FormService 等

### Layer 2: UI 流程测试 (XCUITest + 截图)

```
目标: 关键用户流程可用 + 每步截图存档
框架: XCUITest
截图: XCTAttachment(screenshot:), lifetime = .keepAlways
运行: xcodebuild test -scheme AetherReaderUITests
```

**截图辅助函数:**

```swift
extension XCTestCase {
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "Screenshot-\(name).png",
            payload: screenshot.pngRepresentation,
            userInfo: nil
        )
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

**关键流程 (Phase 1):**

```
TC-001: Library → 拖拽导入 PDF → 网格显示 → 截图
TC-002: Library → 双击打开 → Reader 显示 → 截图
TC-003: Reader → 翻页 (键盘↓) → 页码更新 → 截图
TC-004: Reader → 切换显示模式 (单页/双页/连续) → 每种截图
TC-005: Reader → 缩放 (Cmd+/Cmd-) → 状态栏缩放值更新 → 截图
TC-006: Reader → 侧边栏缩略图点击 → 跳转对应页 → 截图
TC-007: Reader → 侧边栏目录展开点击 → 跳转 → 截图
TC-008: Reader → 添加书签 → 侧边栏书签列表显示 → 截图
TC-009: Reader → 搜索文字 → 结果高亮 → 截图
TC-010: Reader → 日间/夜间/护眼切换 → 每种截图
```

后续 Phase 追加对应测试用例。

### Layer 3: 视觉回归测试 (swift-snapshot-testing)

```
目标: 像素级对比，防止 UI 退化
依赖: pointfreeco/swift-snapshot-testing (test-only, 不 ship)
策略: 首次运行录制参考图，后续运行对比差异
```

**配置:**

```swift
// Package.swift 或 SPM test dependency
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")

// Test target dependency
.testTarget(name: "AetherReaderSnapshotTests", dependencies: [
    .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
])
```

**快照测试示例:**

```swift
import SnapshotTesting
import XCTest
@testable import AetherReader

final class ReaderViewSnapshotTests: XCTestCase {
    func testReaderView_singlePage_lightMode() {
        let view = ReaderView(document: .sample)
            .frame(width: 1200, height: 800)
            .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(precision: 0.98))
    }

    func testReaderView_singlePage_darkMode() {
        let view = ReaderView(document: .sample)
            .frame(width: 1200, height: 800)
            .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(precision: 0.98))
    }

    func testStatusBar_glass() {
        let view = StatusBarView(page: 2, totalPages: 120, fileName: "Report.pdf", zoom: 125)
            .frame(width: 1200, height: 36)

        assertSnapshot(of: view, as: .image(precision: 0.95))
    }

    func testToolbar_readingMode() {
        // 工具栏在阅读模式下的快照
        let view = ToolbarContent(mode: .reading)
        assertSnapshot(of: view, as: .image(precision: 0.95))
    }
}
```

**precision 策略:**
- Glass 效果受系统渲染影响，不要求 100% 像素一致
- 布局/组件级: `precision: 0.98` (允许 2% 差异)
- Glass 材质区域: `precision: 0.95` (允许 5% 差异，因为折射内容会变)
- 全屏截图: `precision: 0.93` (允许 7%，背景内容影响大)

**参考图更新规则:**
- Glass 设计系统变更时：删除旧参考图，重新录制
- 功能变更导致 UI 变化时：review diff → 确认后更新参考图
- 不明原因 diff：调查原因，不盲目更新

## Agent 工作流闭环

```
1. 写/改代码
2. xcodebuild test → 跑全部测试
3. 单元测试失败 → 修逻辑
4. XCUITest 失败 → 看截图 (Read 工具读 png) → 修 UI
5. 快照测试失败 → 看 diff 图 → 判断是预期变更还是退化
6. 全部通过 → 提交
```

**截图文件位置:**
- XCUITest: `DerivedData/.../Attachments/` 或测试结果 bundle
- 快照测试: `__Snapshots__/` 目录 (git tracked，作为参考图)
- 快照 diff: `__Snapshots__/failures/` (git ignored)

## 依赖管理

| 依赖 | 用途 | 是否 ship | 备注 |
|------|------|----------|------|
| swift-snapshot-testing | 视觉回归 | ❌ test-only | 零运行时影响 |

App 本体保持 **零第三方依赖**。swift-snapshot-testing 仅存在于 test target。

## Phase 1 测试目标

- [ ] 项目配置 Swift Testing + XCUITest + snapshot test target
- [ ] 10 个核心流程 XCUITest (TC-001 ~ TC-010)，每步截图
- [ ] 5+ 个关键视图快照测试 (ReaderView, StatusBar, Sidebar, Toolbar, LibraryView)
- [ ] ViewModel 单元测试覆盖核心逻辑
