import SwiftUI
import SwiftData
import PDFKit

@MainActor
@Observable
final class LibraryViewModel {
    var sortOrder: LibrarySortOrder = .dateImported
    var searchText: String = ""

    // MARK: - Import

    func importFiles(urls: [URL], modelContext: ModelContext) async {
        for url in urls {
            do {
                let result = try await FileService.shared.importPDF(from: url)
                let document = PDFDocumentModel(
                    fileName: result.fileName,
                    filePath: result.relativePath,
                    fileSize: result.fileSize,
                    pageCount: result.pageCount,
                    title: result.title,
                    author: result.author
                )
                modelContext.insert(document)
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }
    }

    // MARK: - Delete

    func deleteDocument(_ document: PDFDocumentModel, modelContext: ModelContext) async {
        do {
            try await FileService.shared.deletePDF(relativePath: document.filePath)
        } catch {
            print("Failed to delete file: \(error)")
        }
        modelContext.delete(document)
    }

    // MARK: - Sort & Filter

    func sortedDocuments(_ documents: [PDFDocumentModel]) -> [PDFDocumentModel] {
        let filtered: [PDFDocumentModel]
        if searchText.isEmpty {
            filtered = documents
        } else {
            let query = searchText.lowercased()
            filtered = documents.filter { doc in
                doc.displayName.lowercased().contains(query)
                || (doc.author?.lowercased().contains(query) ?? false)
                || doc.fileName.lowercased().contains(query)
            }
        }

        return filtered.sorted { a, b in
            switch sortOrder {
            case .name:
                return a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
            case .dateImported:
                return a.importDate > b.importDate
            case .dateOpened:
                return (a.lastOpenedDate ?? .distantPast) > (b.lastOpenedDate ?? .distantPast)
            case .size:
                return a.fileSize > b.fileSize
            }
        }
    }
}
