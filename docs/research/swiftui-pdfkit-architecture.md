---
title: SwiftUI + PDFKit PDF Reader Architecture Research
description: 综合研究 PDFKit 能力、SwiftUI 集成模式、应用架构、项目结构、性能优化等
status: active
date: 2026-04-05
---

# SwiftUI + PDFKit PDF Reader 架构研究

## 1. PDFKit 框架能力总览

PDFKit 是 Apple 原生 PDF 框架，iOS 11+ / macOS 10.4+ 可用。核心由 4 个主类构成：

### 核心类

| 类 | 职责 |
|---|------|
| **PDFView** | 主显示控件。支持缩放、滚动、文字选择、复制。可设置 `displayMode`（单页/连续/双页）、`displayDirection`、`autoScales` |
| **PDFDocument** | PDF 文件的内存模型。从 URL/Data 初始化。提供页面增删、查找（`findString`）、写入（`write(to:)`）、解锁加密文档 |
| **PDFPage** | 单页模型。提供 `thumbnail(of:for:)` 生成缩略图、`string` 获取文字、`annotations` 管理标注、`bounds(for:)` 获取页面尺寸 |
| **PDFAnnotation** | 标注模型。支持类型：高亮、下划线、删除线、手写墨迹、文本框、链接、图章等。可设置 appearance stream 自定义绘制 |

### 辅助类

| 类 | 职责 |
|---|------|
| **PDFThumbnailView** | 缩略图滚动条控件，自动与 PDFView 双向同步当前页 |
| **PDFOutline** | 书签/目录树。`root` → 子节点递归遍历，每个节点有 `label` 和 `destination`（跳转目标） |
| **PDFSelection** | 选区模型。由文字查找或用户框选产生，可获取 `string`、`bounds(for:)` 坐标 |
| **PDFAction** | 动作模型（跳转 URL、跳转页面等），附加在 annotation 或 outline 上 |
| **PDFDestination** | 页面 + 坐标定位，用于精确跳转 |

### 通知机制

PDFKit 通过 `NotificationCenter` 广播状态变化：

- `.PDFViewPageChanged` — 当前页变化
- `.PDFViewScaleChanged` — 缩放级别变化
- `.PDFViewDocumentChanged` — 文档替换
- `.PDFViewChangedHistory` — 前进/后退历史变化
- `.PDFViewAnnotationHit` — 用户点击标注
- `.PDFViewSelectionChanged` — 选区变化
- `.PDFViewDisplayModeChanged` — 显示模式变化

### WWDC22 新增能力

- Live Text 集成（自动识别图片中文字）
- 从图片创建 PDF（`PDFDocument(image:)`）
- Overlay View（在 PDF 页面上叠加自定义 UIView，用于实时协作标注等）
- 表单支持改进

---

## 2. SwiftUI + PDFKit 集成

### UIViewRepresentable 桥接模式

PDFView 是 UIKit 控件，需通过 `UIViewRepresentable` 桥接。基本结构：

```swift
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var scaleFactor: CGFloat

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // 防止无限循环：对比前值，无变化则跳过
        if pdfView.document !== document {
            pdfView.document = document
        }
        // 同理处理 page / scale 更新
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitView

        init(_ parent: PDFKitView) {
            self.parent = parent
            super.init()
            // 通过 NotificationCenter 监听 PDFView 状态变化
            NotificationCenter.default.addObserver(
                self, selector: #selector(pageChanged),
                name: .PDFViewPageChanged, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(scaleChanged),
                name: .PDFViewScaleChanged, object: nil
            )
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: page)
            else { return }
            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }

        @objc func scaleChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            DispatchQueue.main.async {
                self.parent.scaleFactor = pdfView.scaleFactor
            }
        }
    }
}
```

### 关键陷阱和解法

**陷阱 1：updateUIView 无限循环**

`updateUIView` 中修改 PDFView 属性 → 触发通知 → Coordinator 更新 Binding → SwiftUI 再次调用 `updateUIView` → 循环。

解法：在 `updateUIView` 中比较当前值与目标值，相同则 `return`。在 Coordinator 中用标志位或前值追踪防止回写。

**陷阱 2：Annotation 累积**

PDFKit 不会自动清理标注。搜索高亮后切换关键词，旧高亮残留。

解法：每次添加新标注前，遍历所有页面移除同类型旧标注：
```swift
for i in 0..<(document.pageCount) {
    guard let page = document.page(at: i) else { continue }
    let toRemove = page.annotations.filter { $0.type == "Highlight" }
    toRemove.forEach { page.removeAnnotation($0) }
}
```

**陷阱 3：线程安全**

PDF 加载（尤其从网络/iCloud）可能在后台线程，但 `@Published` 属性必须在主线程更新。始终用 `DispatchQueue.main.async` 或 `@MainActor`。

**陷阱 4：PDFThumbnailView 内存泄漏**

`PDFPage.thumbnail(of:for:)` 存在已知的缓存资源泄漏问题。对大文档需自行管理缩略图缓存（`NSCache`），避免反复调用。

**陷阱 5：首响应者冲突**

工具栏中的 TextField 可能抢占 first responder，阻塞 PDFView 交互。切换操作前需显式 dismiss keyboard。

---

## 3. 应用架构推荐

### 推荐方案：MVVM + @Observable（iOS 17+）

项目目标 iOS 16+，但考虑到 Liquid Glass 定位 iOS 26，实际最低部署目标应为 iOS 17+。因此推荐使用 Swift Observation 框架。

**为何选 @Observable 而非 ObservableObject：**

- 精确追踪属性访问，只有被 View body 读取的属性变化才触发重绘（ObservableObject 任一 @Published 变化都重绘所有订阅 View）
- 语法更简洁：不需要 `@Published`、`@ObservedObject`、`@StateObject`
- 与 SwiftUI 的 `@State`、`@Environment` 原生集成
- 性能更优

**架构层次：**

```
View (SwiftUI)
  ↓ 持有/观察
ViewModel (@Observable class)
  ↓ 调用
Service (协议 + 实现)
  ↓ 操作
Model (struct / PDFDocument)
```

**核心 ViewModel 示例：**

```swift
@Observable
class PDFReaderViewModel {
    // MARK: - Document State
    var document: PDFDocument?
    var currentPageIndex: Int = 0
    var scaleFactor: CGFloat = 1.0
    var isLoading: Bool = false

    // MARK: - Search State
    var searchText: String = ""
    var searchResults: [PDFSelection] = []
    var currentSearchIndex: Int = 0

    // MARK: - Outline
    var outlineRoot: PDFOutline?
    var isOutlineVisible: Bool = false

    // MARK: - Services
    private let fileService: FileServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol

    init(fileService: FileServiceProtocol, bookmarkService: BookmarkServiceProtocol) {
        self.fileService = fileService
        self.bookmarkService = bookmarkService
    }

    func loadDocument(from url: URL) async {
        isLoading = true
        defer { isLoading = false }
        let doc = PDFDocument(url: url)
        self.document = doc
        self.outlineRoot = doc?.outlineRoot
        self.currentPageIndex = bookmarkService.lastPage(for: url) ?? 0
    }

    func search(_ text: String) {
        guard let document else { return }
        searchResults = document.findString(text, withOptions: .caseInsensitive)
        currentSearchIndex = 0
    }

    func goToPage(_ index: Int) {
        guard let document, index >= 0, index < document.pageCount else { return }
        currentPageIndex = index
    }
}
```

### 备选方案对比

| 架构 | 优势 | 劣势 | 适用场景 |
|------|------|------|----------|
| **MVVM + @Observable** | 简洁、性能好、Apple 官方方向 | iOS 17+ | 本项目推荐 |
| **TCA (Composable Architecture)** | 强类型状态、可测试、时间旅行调试 | 学习曲线陡峭、引入重依赖 | 团队项目、复杂交互逻辑 |
| **MV (Model-View)** | 最简单，Apple 示例常用 | ViewModel 逻辑散落 View 中，难测试 | 简单原型 |
| **Clean Architecture** | 严格分层、高可测试性 | 过度工程化风险 | 大型商业项目 |

---

## 4. 推荐项目结构

```
AetherReader/
├── App/
│   ├── AetherReaderApp.swift          # @main 入口
│   ├── AppDelegate.swift              # 如需 UIApplicationDelegate
│   └── DependencyContainer.swift      # 依赖注入容器
│
├── Features/
│   ├── Reader/                        # PDF 阅读核心功能
│   │   ├── Views/
│   │   │   ├── ReaderView.swift       # 主阅读界面
│   │   │   ├── PDFKitView.swift       # UIViewRepresentable 桥接
│   │   │   ├── ReaderToolbar.swift    # 工具栏
│   │   │   └── PageIndicator.swift    # 页码指示器
│   │   ├── ViewModels/
│   │   │   └── ReaderViewModel.swift
│   │   └── Models/
│   │       └── ReadingState.swift     # 阅读状态模型
│   │
│   ├── Library/                       # 文件管理/书库
│   │   ├── Views/
│   │   │   ├── LibraryView.swift      # 书库主界面
│   │   │   ├── FileGridItem.swift     # 网格项
│   │   │   └── ImportSheet.swift      # 导入面板
│   │   ├── ViewModels/
│   │   │   └── LibraryViewModel.swift
│   │   └── Models/
│   │       └── PDFFileItem.swift      # 文件元数据模型
│   │
│   ├── Search/                        # 文内搜索
│   │   ├── Views/
│   │   │   ├── SearchBar.swift
│   │   │   └── SearchResultsList.swift
│   │   └── ViewModels/
│   │       └── SearchViewModel.swift
│   │
│   ├── Outline/                       # 目录/大纲
│   │   ├── Views/
│   │   │   └── OutlineView.swift
│   │   └── ViewModels/
│   │       └── OutlineViewModel.swift
│   │
│   ├── Thumbnails/                    # 缩略图导航
│   │   ├── Views/
│   │   │   └── ThumbnailStripView.swift
│   │   └── ViewModels/
│   │       └── ThumbnailViewModel.swift
│   │
│   ├── Annotations/                   # 标注功能
│   │   ├── Views/
│   │   │   ├── AnnotationToolbar.swift
│   │   │   └── AnnotationListView.swift
│   │   └── ViewModels/
│   │       └── AnnotationViewModel.swift
│   │
│   └── Settings/                      # 设置
│       ├── Views/
│       │   └── SettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── Core/
│   ├── Services/
│   │   ├── FileService.swift          # PDF 文件导入/导出/管理
│   │   ├── BookmarkService.swift      # 阅读进度/书签持久化
│   │   ├── ThumbnailCacheService.swift # 缩略图缓存
│   │   ├── SearchService.swift        # 搜索索引
│   │   └── ICloudSyncService.swift    # iCloud 同步
│   ├── Persistence/
│   │   ├── SwiftDataModels.swift      # SwiftData 模型
│   │   └── ModelContainer+Ext.swift
│   └── Protocols/
│       ├── FileServiceProtocol.swift
│       ├── BookmarkServiceProtocol.swift
│       └── ThumbnailCacheProtocol.swift
│
├── UI/
│   ├── Components/                    # 通用 UI 组件
│   │   ├── LoadingOverlay.swift
│   │   ├── EmptyStateView.swift
│   │   └── GlassBackground.swift     # Liquid Glass 效果
│   ├── Theme/
│   │   ├── AppTheme.swift
│   │   └── Typography.swift
│   └── Extensions/
│       ├── View+Extensions.swift
│       ├── Color+Extensions.swift
│       └── PDFDocument+Extensions.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.xcstrings
│
└── Package.swift                      # 若使用 SPM 模块化
```

### 结构设计原则

- **Feature-based**：每个功能自包含 Views/ViewModels/Models，便于独立开发和测试
- **Core**：跨功能共享的 Services 和数据层，通过协议抽象
- **UI**：通用 UI 组件和主题，不包含业务逻辑
- **扁平化 vs 深嵌套**：中等复杂度项目用 2-3 层目录即可，避免过度嵌套

---

## 5. SPM 依赖管理

### Xcode 项目 + SPM 配置

推荐直接在 Xcode 项目中通过 `File → Add Package Dependencies` 添加 SPM 包，而非创建独立 Package.swift（除非做模块化 local package）。

### 推荐 SPM 包

| 包 | 用途 | 地址 |
|----|------|------|
| **Splash** | Swift 语法高亮（代码类 PDF 可能用到） | github.com/JohnSundell/Splash |
| **Nuke** | 图片/缩略图缓存、预加载 | github.com/kean/Nuke |
| **SwiftUIIntrospect** | 访问 SwiftUI 底层 UIKit 控件，调试用 | github.com/siteline/SwiftUIIntrospect |
| **KeychainAccess** | 安全存储（如加密 PDF 密码缓存） | github.com/kishikawakatsumi/KeychainAccess |

### 模块化方案（可选，大型项目）

如需更严格的模块边界，可使用 local SPM packages：

```
AetherReader.xcodeproj
├── Packages/
│   ├── AetherReaderCore/       # Services, Models, Protocols
│   │   └── Package.swift
│   ├── AetherReaderUI/         # 通用 UI 组件
│   │   └── Package.swift
│   └── AetherReaderFeatures/   # Feature 模块（或拆分为多个）
│       └── Package.swift
```

本项目中等复杂度，**不建议一开始就模块化**。先用单 target + 文件夹结构，等代码量增长到需要编译隔离时再拆分。

---

## 6. 文件管理

### PDF 导入

SwiftUI 原生提供 `.fileImporter` modifier，是最简方案：

```swift
.fileImporter(
    isPresented: $isImportPresented,
    allowedContentTypes: [.pdf],
    allowsMultipleSelection: true
) { result in
    switch result {
    case .success(let urls):
        for url in urls {
            // 必须开启 security-scoped access
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            // 复制到 app sandbox 或 app group container
            fileService.importPDF(from: url)
        }
    case .failure(let error):
        // 处理错误
    }
}
```

**关键要点：**
- 必须调用 `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`
- 外部 URL 是临时授权的，应立即复制到 app 自有目录
- 支持多选（`allowsMultipleSelection: true`）

### 文件存储策略

```
Documents/
├── PDFs/                # 导入的 PDF 文件
│   ├── {uuid}.pdf
│   └── ...
└── Thumbnails/          # 缩略图缓存（也可用 Caches/）
    ├── {uuid}_thumb.jpg
    └── ...
```

- 使用 UUID 重命名避免文件名冲突
- 原始文件名存在 SwiftData/CoreData 元数据中
- 缩略图放 `Caches/` 目录（系统可清理）

### iCloud 同步

两种方案：

**方案 A：iCloud Documents（推荐）**
- 在 Xcode Capabilities 开启 iCloud Documents
- 使用 `FileManager.default.url(forUbiquityContainerIdentifier:)` 获取 iCloud 容器
- 文件自动同步，使用 `NSMetadataQuery` 监听下载状态
- 用户体验最接近"无感同步"

**方案 B：CloudKit**
- 更细粒度控制，但实现复杂度高很多
- 适合只同步元数据/书签，不同步 PDF 文件本体

### 最近文件

SwiftData 存储文件元数据：

```swift
@Model
class PDFFileRecord {
    var id: UUID
    var fileName: String
    var fileURL: URL          // 相对路径
    var importDate: Date
    var lastOpenedDate: Date?
    var pageCount: Int
    var lastReadPage: Int
    var fileSize: Int64
    var thumbnailData: Data?  // 首页缩略图
}
```

---

## 7. 性能优化

### 大文件处理

- PDFKit 内部已做懒加载——`PDFDocument` 不会一次加载全部页面到内存
- 但 `PDFView` 在连续滚动模式下会预渲染相邻页，内存消耗与可见区域相关
- 对 500+ 页文档，避免一次性遍历所有页面（如全文搜索应异步分批）

### 缩略图缓存策略

```swift
class ThumbnailCacheService {
    private let cache = NSCache<NSNumber, UIImage>()
    private let thumbnailSize = CGSize(width: 120, height: 160)

    init() {
        cache.countLimit = 100     // 最多缓存 100 张
        cache.totalCostLimit = 50_000_000  // ~50MB
    }

    func thumbnail(for page: PDFPage, at index: Int) async -> UIImage? {
        let key = NSNumber(value: index)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        // 在后台线程生成
        let image = await Task.detached(priority: .utility) {
            page.thumbnail(of: self.thumbnailSize, for: .cropBox)
        }.value
        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }
}
```

**注意**：`PDFPage.thumbnail(of:for:)` 存在已知内存泄漏。对大文档应：
- 限制缓存数量（`NSCache.countLimit`）
- 在文档切换时清空缓存
- 考虑自行用 `CGPDFDocument` + Core Graphics 渲染缩略图作为替代

### 缩略图 UI 懒加载

使用 `LazyVGrid` / `LazyHStack` 显示缩略图列表，配合 `.task` 按需加载：

```swift
LazyVGrid(columns: columns) {
    ForEach(0..<pageCount, id: \.self) { index in
        ThumbnailCell(index: index)
            .task {
                await thumbnailVM.loadThumbnail(at: index)
            }
    }
}
```

### 内存管理要点

- 监听 `UIApplication.didReceiveMemoryWarningNotification`，清空缩略图缓存
- 文档切换时先设 `pdfView.document = nil`，等旧文档释放后再设新文档
- 避免持有 PDFPage 强引用数组——按需从 `PDFDocument.page(at:)` 获取
- 搜索结果 `PDFSelection` 数组可能很大，分页展示

---

## 8. 开源项目参考

| 项目 | 特点 | 链接 |
|------|------|------|
| **rajubd49/PDFViewer** | SwiftUI + PDFKit 最简实现，可作 SPM 包集成 | github.com/rajubd49/PDFViewer |
| **mc-public/PDFPreviewer** | SwiftUI 组件，自定义缩放控制和页面导航 | github.com/mc-public/PDFPreviewer |
| **uxmstudio/UXMPDFKit** | 全功能 PDF 阅读器+标注，UIKit 实现，可参考标注和表单处理逻辑 | github.com/uxmstudio/UXMPDFKit |
| **PSPDFKit/pspdfkit-ios-catalog** | PSPDFKit(Nutrient) 官方示例，展示专业级 PDF SDK 的 UI 架构分层 | github.com/PSPDFKit/pspdfkit-ios-catalog |

### PSPDFKit/Nutrient 架构启示

Nutrient（原 PSPDFKit）将 SDK 分为两层：
- **PSPDFKit**：模型层（文档、页面、标注、渲染）
- **PSPDFKitUI**：UI 层（视图控制器、工具栏、面板）

这种分层值得借鉴：Core 层不依赖 UI 框架，Features 层构建在 Core 之上。

---

## 9. 总结建议

1. **架构**：MVVM + @Observable，Service 层通过协议注入
2. **数据持久化**：SwiftData 存元数据，文件系统存 PDF 和缩略图
3. **PDFKit 集成**：UIViewRepresentable + Coordinator + NotificationCenter，注意防循环
4. **文件导入**：SwiftUI `.fileImporter` + security-scoped resource 处理
5. **性能**：NSCache 缓存缩略图、LazyVGrid 懒加载、后台线程生成缩略图
6. **项目结构**：Feature-based 文件夹，初期不做 SPM 模块化
7. **同步**：iCloud Documents 方案最简，后续可扩展
