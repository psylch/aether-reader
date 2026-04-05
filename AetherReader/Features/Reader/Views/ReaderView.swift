import SwiftUI
@preconcurrency import PDFKit

struct ReaderView: View {
    let record: PDFDocumentRecord

    @State private var document: PDFDocument?
    @State private var currentPageIndex: Int = 0
    @State private var scaleFactor: CGFloat = 1.0
    @State private var showChrome: Bool = true
    @State private var isLoading: Bool = true

    // Feature states
    @State private var searchVM = SearchViewModel()
    @State private var outlineVM = OutlineViewModel()
    @State private var thumbnailVM = ThumbnailStripViewModel()

    // Sheet states
    @State private var showOutline = false
    @State private var showThumbnails = false
    @State private var showDisplayMode = false

    // Display settings
    @State private var appearanceMode: AppearanceMode = .auto
    @State private var scrollMode: ScrollMode = .continuous

    // Bookmark
    @State private var isCurrentPageBookmarked = false
    @State private var bookmarkService: BookmarkService?

    // Navigation triggers
    @State private var navigateToSelection: PDFSelection?
    @State private var navigateToDestination: PDFDestination?

    // Progress save debounce
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if let document {
                PDFKitView(
                    document: document,
                    currentPageIndex: $currentPageIndex,
                    scaleFactor: $scaleFactor,
                    displayMode: scrollMode == .continuous ? .singlePageContinuous : .singlePage,
                    navigateToSelection: navigateToSelection,
                    navigateToDestination: navigateToDestination
                )
                .ignoresSafeArea()
                .onTapGesture {
                    if !searchVM.isActive {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showChrome.toggle()
                        }
                    }
                }

                if showChrome && !searchVM.isActive {
                    chromeOverlay
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if searchVM.isActive {
                    SearchOverlayView(viewModel: searchVM)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            } else if isLoading {
                ProgressView("Opening...")
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(appearanceMode.colorScheme)
        .onChange(of: currentPageIndex) { _, newValue in
            navigateToSelection = nil
            navigateToDestination = nil
            debounceSaveProgress()
            updateBookmarkState()
        }
        .onChange(of: searchVM.currentIndex) {
            navigateToSelection = searchVM.currentResult
        }
        .task {
            await loadDocument()
        }
        .onDisappear {
            saveProgress()
        }
        .sheet(isPresented: $showOutline) {
            OutlineView(items: outlineVM.items) { destination in
                navigateToDestination = destination
            }
        }
        .sheet(isPresented: $showThumbnails) {
            ThumbnailStripView(viewModel: thumbnailVM) { pageIndex in
                currentPageIndex = pageIndex
            }
        }
        .sheet(isPresented: $showDisplayMode) {
            DisplayModeSheet(
                appearanceMode: $appearanceMode,
                scrollMode: $scrollMode
            )
        }
    }

    private var chromeOverlay: some View {
        VStack {
            HStack {
                BackButton()
                Spacer()
                PageIndicatorView(
                    current: currentPageIndex + 1,
                    total: document?.pageCount ?? 0
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            ReaderToolbar(
                onSearch: {
                    withAnimation { searchVM.isActive = true }
                },
                onOutline: {
                    if outlineVM.hasOutline { showOutline = true }
                },
                onThumbnails: {
                    thumbnailVM.currentPageIndex = currentPageIndex
                    showThumbnails = true
                },
                onBookmark: {
                    toggleBookmark()
                },
                onDisplayMode: {
                    showDisplayMode = true
                },
                isBookmarked: isCurrentPageBookmarked
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func loadDocument() async {
        let url = record.pdfURL
        let doc = PDFDocument(url: url)
        document = doc
        currentPageIndex = record.lastReadPage

        searchVM.setDocument(doc)
        outlineVM.buildOutline(from: doc?.outlineRoot)
        thumbnailVM.setDocument(doc)

        if let container = try? record.modelContext?.container {
            bookmarkService = BookmarkService(modelContainer: container)
        }
        updateBookmarkState()

        isLoading = false
    }

    private func toggleBookmark() {
        guard let bookmarkService else { return }
        if isCurrentPageBookmarked {
            bookmarkService.removeBookmark(pageIndex: currentPageIndex, document: record)
        } else {
            bookmarkService.addBookmark(pageIndex: currentPageIndex, document: record)
        }
        isCurrentPageBookmarked.toggle()
    }

    private func updateBookmarkState() {
        guard let bookmarkService else { return }
        isCurrentPageBookmarked = bookmarkService.hasBookmark(pageIndex: currentPageIndex, document: record)
    }

    private func debounceSaveProgress() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            saveProgress()
        }
    }

    private func saveProgress() {
        record.lastReadPage = currentPageIndex
        record.lastOpenedDate = .now
    }
}

private struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .padding(10)
        }
        .glassEffect(in: .circle)
    }
}
