import Foundation
import SwiftData

@Model
final class PDFDocumentRecord {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var storagePath: String
    var importDate: Date
    var lastOpenedDate: Date?
    var pageCount: Int
    var lastReadPage: Int
    var fileSize: Int64
    @Attribute(.externalStorage) var thumbnailData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Bookmark.document)
    var bookmarks: [Bookmark] = []

    init(
        id: UUID = UUID(),
        fileName: String,
        storagePath: String,
        importDate: Date = .now,
        pageCount: Int,
        fileSize: Int64
    ) {
        self.id = id
        self.fileName = fileName
        self.storagePath = storagePath
        self.importDate = importDate
        self.lastOpenedDate = nil
        self.pageCount = pageCount
        self.lastReadPage = 0
        self.fileSize = fileSize
        self.thumbnailData = nil
    }

    var readingProgress: Double {
        guard pageCount > 0 else { return 0 }
        return Double(lastReadPage + 1) / Double(pageCount)
    }

    var pdfURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("AetherReader/\(storagePath)")
    }
}
