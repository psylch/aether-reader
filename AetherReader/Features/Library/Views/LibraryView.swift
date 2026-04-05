import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PDFDocumentRecord.lastOpenedDate, order: .reverse) private var documents: [PDFDocumentRecord]
    @State private var isImporting = false

    var body: some View {
        Group {
            if documents.isEmpty {
                emptyState
            } else {
                documentGrid
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isImporting = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No PDFs Yet", systemImage: "doc.richtext")
        } description: {
            Text("Import PDF files to start reading")
        } actions: {
            Button("Import PDF") {
                isImporting = true
            }
        }
    }

    private var documentGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                ForEach(documents) { record in
                    NavigationLink(value: record.id) {
                        PDFGridItemView(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationDestination(for: UUID.self) { documentID in
            if let record = documents.first(where: { $0.id == documentID }) {
                ReaderView(record: record)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        let fileService = FileService()
        Task {
            for url in urls {
                do {
                    let info = try await fileService.importPDF(from: url)
                    let record = PDFDocumentRecord(
                        fileName: url.deletingPathExtension().lastPathComponent,
                        storagePath: info.storagePath,
                        pageCount: info.pageCount,
                        fileSize: info.fileSize
                    )
                    record.thumbnailData = info.thumbnailData
                    modelContext.insert(record)
                } catch {
                    print("Failed to import \(url.lastPathComponent): \(error)")
                }
            }
            try? modelContext.save()
        }
    }
}
