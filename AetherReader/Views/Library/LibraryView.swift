import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [PDFDocumentModel]

    @State private var viewModel = LibraryViewModel()
    @State private var selectedDocumentID: UUID?
    @State private var propertiesDocument: PDFDocumentModel?

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 16)
    ]

    var body: some View {
        @Bindable var appState = appState

        Group {
            if documents.isEmpty && viewModel.searchText.isEmpty {
                emptyState
            } else {
                libraryGrid
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search library")
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.showFileImporter = true
                } label: {
                    Label("Import", systemImage: "plus")
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            ToolbarItem(placement: .automatic) {
                sortMenu
            }
        }
        .fileImporter(
            isPresented: $appState.showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .sheet(item: $propertiesDocument) { document in
            PropertiesSheet(document: document)
        }
    }

    // MARK: - Library Grid

    private var libraryGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                let sorted = viewModel.sortedDocuments(documents)
                ForEach(sorted) { document in
                    LibraryGridItem(
                        document: document,
                        isSelected: selectedDocumentID == document.id
                    )
                    .onTapGesture {
                        selectedDocumentID = document.id
                    }
                    .onTapGesture(count: 2) {
                        openDocument(document)
                    }
                    .contextMenu {
                        contextMenu(for: document)
                    }
                }
            }
            .padding()
        }
        .onDrop(of: [.pdf], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No PDFs in Library")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Drag & drop PDF files here to import")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Import PDFs") {
                appState.showFileImporter = true
            }
            .controlSize(.large)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.pdf], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(LibrarySortOrder.allCases) { order in
                Button {
                    viewModel.sortOrder = order
                } label: {
                    if viewModel.sortOrder == order {
                        Label(order.label, systemImage: "checkmark")
                    } else {
                        Text(order.label)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for document: PDFDocumentModel) -> some View {
        Button("Open") {
            openDocument(document)
        }

        Divider()

        Button("Reveal in Finder") {
            Task {
                await FileService.shared.revealInFinder(relativePath: document.filePath)
            }
        }

        Button("Properties") {
            propertiesDocument = document
        }

        Divider()

        Button("Delete", role: .destructive) {
            Task {
                if selectedDocumentID == document.id {
                    selectedDocumentID = nil
                }
                await viewModel.deleteDocument(document, modelContext: modelContext)
            }
        }
    }

    // MARK: - Actions

    private func openDocument(_ document: PDFDocumentModel) {
        document.lastOpenedDate = Date()
        appState.openDocument(document)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await viewModel.importFiles(urls: urls, modelContext: modelContext)
            }
        case .failure(let error):
            print("File import failed: \(error)")
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    await viewModel.importFiles(urls: [url], modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Properties Sheet

private struct PropertiesSheet: View {
    let document: PDFDocumentModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.title2)
                .fontWeight(.semibold)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
                propertyRow("Title", value: document.title ?? "Untitled")
                propertyRow("File Name", value: document.fileName)

                if let author = document.author {
                    propertyRow("Author", value: author)
                }

                propertyRow("Pages", value: "\(document.pageCount)")
                propertyRow("Size", value: formattedSize(document.fileSize))
                propertyRow("Imported", value: document.importDate.formatted(date: .abbreviated, time: .shortened))

                if let lastOpened = document.lastOpenedDate {
                    propertyRow("Last Opened", value: lastOpened.formatted(date: .abbreviated, time: .shortened))
                }

                if document.readingProgress > 0 {
                    propertyRow("Progress", value: "\(Int(document.readingProgress * 100))%")
                }
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
    }

    @ViewBuilder
    private func propertyRow(_ label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .textSelection(.enabled)
        }
    }

    private func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
