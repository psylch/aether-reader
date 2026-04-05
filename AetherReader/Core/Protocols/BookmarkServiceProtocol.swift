import Foundation

@MainActor
protocol BookmarkServiceProtocol {
    func bookmarks(for documentID: UUID) -> [Bookmark]
    func addBookmark(pageIndex: Int, document: PDFDocumentRecord)
    func removeBookmark(pageIndex: Int, document: PDFDocumentRecord)
    func hasBookmark(pageIndex: Int, document: PDFDocumentRecord) -> Bool
}
