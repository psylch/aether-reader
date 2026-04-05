import SwiftUI
import PDFKit

struct ReaderView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ReaderViewModel
    @State private var goToPageText: String = ""
    @State private var showInspector: Bool = false

    private let document: PDFDocumentModel

    init(document: PDFDocumentModel) {
        self.document = document
        self._viewModel = State(initialValue: ReaderViewModel(documentModel: document))
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView(columnVisibility: $appState.showSidebar.mapped) {
            SidebarView(viewModel: viewModel)
        } detail: {
            PDFKitView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: [.top, .bottom])
                .overlay(alignment: .bottom) {
                    StatusBarView(viewModel: viewModel)
                }
        }
        .navigationTitle(document.displayName)
        .toolbarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .searchable(
            text: Bindable(viewModel).searchText,
            prompt: "Search in document"
        )
        .onSubmit(of: .search) {
            viewModel.performSearch()
        }
        .searchSuggestions {
            if !viewModel.searchResults.isEmpty {
                searchResultsBar
            }
        }
        .inspector(isPresented: $showInspector) {
            Text("Inspector")
                .frame(minWidth: 200)
        }
        .sheet(isPresented: $appState.showGoToPage) {
            goToPageSheet
        }
        .focusedSceneValue(\.readerViewModel, viewModel)
        .onKeyPress(.space) { handleSpace(shift: false) }
        .onAppear { onAppear() }
        .onDisappear { onDisappear() }
        .onChange(of: appState.appearance) { _, newValue in
            guard let pdfView = viewModel.pdfView else { return }
            PDFKitView.applyAppearance(newValue, to: pdfView)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Leading: back to library
        ToolbarItem(placement: .navigation) {
            Button {
                appState.closeDocument()
            } label: {
                Label("Library", systemImage: "chevron.left")
            }
            .help("Back to Library")
        }

        // Trailing: appearance, display mode, sidebar
        ToolbarItem(placement: .secondaryAction) {
            appearancePicker
        }

        ToolbarItem(placement: .secondaryAction) {
            zoomControls
        }

        ToolbarItem(placement: .secondaryAction) {
            displayModePicker
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                appState.showSidebar.toggle()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.right")
            }
            .help("Toggle Sidebar")
        }
    }

    // MARK: - Display Mode Picker

    private var displayModePicker: some View {
        Menu {
            ForEach(DisplayMode.allCases) { mode in
                Button {
                    viewModel.displayMode = mode
                } label: {
                    Label(mode.label, systemImage: mode.icon)
                }
                .keyboardShortcut(mode.shortcutKey, modifiers: mode.shortcutModifiers)
            }
        } label: {
            Label("Display Mode", systemImage: viewModel.displayMode.icon)
        }
        .help(viewModel.displayMode.label)
    }

    // MARK: - Zoom Controls

    private var zoomControls: some View {
        Menu {
            ForEach([25, 50, 75, 100, 125, 150, 200], id: \.self) { percent in
                Button("\(percent)%") {
                    let scale = CGFloat(percent) / 100.0
                    viewModel.autoScales = false
                    viewModel.scaleFactor = scale
                    viewModel.pdfView?.scaleFactor = scale
                }
            }
            Divider()
            Button("Fit Page") {
                viewModel.fitToPage()
            }
            Button("Fit Width") {
                viewModel.fitToWidth()
            }
            Button("Actual Size") {
                viewModel.resetZoom()
            }
        } label: {
            Label("\(viewModel.zoomPercentage)%", systemImage: "magnifyingglass")
        }
        .help("Zoom: \(viewModel.zoomPercentage)%")
    }

    // MARK: - Appearance Picker

    private var appearancePicker: some View {
        Menu {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    appState.appearance = mode
                } label: {
                    Label(mode.label, systemImage: mode.icon)
                }
            }
        } label: {
            Label("Appearance", systemImage: appState.appearance.icon)
        }
        .help("Appearance Mode")
    }

    // MARK: - Search Results Bar

    private var searchResultsBar: some View {
        HStack {
            Text("\(viewModel.currentSearchIndex + 1) of \(viewModel.searchResults.count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button {
                viewModel.previousSearchResult()
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)

            Button {
                viewModel.nextSearchResult()
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Go To Page Sheet

    private var goToPageSheet: some View {
        VStack(spacing: 16) {
            Text("Go to Page")
                .font(.headline)

            TextField("Page number", text: $goToPageText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .onSubmit { submitGoToPage() }

            Text("of \(viewModel.totalPages)")
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") {
                    appState.showGoToPage = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Go") {
                    submitGoToPage()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .onAppear {
            goToPageText = "\(viewModel.currentPageIndex + 1)"
        }
    }

    // MARK: - Actions

    private func submitGoToPage() {
        if let page = Int(goToPageText), page >= 1, page <= viewModel.totalPages {
            viewModel.goToPage(page - 1)
        }
        appState.showGoToPage = false
    }

    private func handleSpace(shift: Bool) -> KeyPress.Result {
        if shift {
            viewModel.previousPage()
        } else {
            viewModel.nextPage()
        }
        return .handled
    }

    private func onAppear() {
        appState.readerViewModel = viewModel

        Task {
            let url = await FileService.shared.pdfURL(for: document.filePath)
            viewModel.loadDocument(from: url)
        }

        document.lastOpenedDate = Date()
    }

    private func onDisappear() {
        appState.readerViewModel = nil
    }
}

// MARK: - NavigationSplitViewVisibility Binding Helper

private extension Binding where Value == Bool {
    var mapped: Binding<NavigationSplitViewVisibility> {
        Binding<NavigationSplitViewVisibility>(
            get: { self.wrappedValue ? .all : .detailOnly },
            set: { self.wrappedValue = ($0 != .detailOnly) }
        )
    }
}

// MARK: - Focused Value Key

private struct ReaderViewModelKey: FocusedValueKey {
    typealias Value = ReaderViewModel
}

extension FocusedValues {
    var readerViewModel: ReaderViewModel? {
        get { self[ReaderViewModelKey.self] }
        set { self[ReaderViewModelKey.self] = newValue }
    }
}
