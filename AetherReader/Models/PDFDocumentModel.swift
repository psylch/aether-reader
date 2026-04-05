import SwiftUI
import SwiftData
import PDFKit

@Model
final class PDFDocumentModel {
    var id: UUID
    var fileName: String
    var filePath: String  // Relative to Application Support
    var fileSize: Int64
    var pageCount: Int
    var title: String?
    var author: String?
    var creationDate: Date?
    var importDate: Date
    var lastOpenedDate: Date?
    var lastReadPage: Int
    var readingProgress: Double  // 0.0 ~ 1.0

    @Relationship(deleteRule: .cascade)
    var bookmarks: [BookmarkModel]

    init(
        fileName: String,
        filePath: String,
        fileSize: Int64 = 0,
        pageCount: Int = 0,
        title: String? = nil,
        author: String? = nil,
        creationDate: Date? = nil
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.title = title
        self.author = author
        self.creationDate = creationDate
        self.importDate = Date()
        self.lastOpenedDate = nil
        self.lastReadPage = 0
        self.readingProgress = 0.0
        self.bookmarks = []
    }

    var displayName: String {
        title ?? fileName.replacingOccurrences(of: ".pdf", with: "")
    }
}

@Model
final class BookmarkModel {
    var id: UUID
    var pageIndex: Int
    var label: String
    var createdDate: Date

    var document: PDFDocumentModel?

    init(pageIndex: Int, label: String = "") {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.label = label.isEmpty ? "Page \(pageIndex + 1)" : label
        self.createdDate = Date()
    }
}
