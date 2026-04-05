import Foundation
import SwiftData

@Model
final class Bookmark {
    var id: UUID
    var pageIndex: Int
    var createdDate: Date
    var label: String?
    var document: PDFDocumentRecord?

    init(
        id: UUID = UUID(),
        pageIndex: Int,
        label: String? = nil,
        document: PDFDocumentRecord? = nil
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.createdDate = .now
        self.label = label
        self.document = document
    }
}
