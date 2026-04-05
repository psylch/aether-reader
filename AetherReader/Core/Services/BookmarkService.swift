import Foundation
import SwiftData

@MainActor
final class BookmarkService: BookmarkServiceProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func bookmarks(for documentID: UUID) -> [Bookmark] {
        let context = modelContainer.mainContext
        let predicate = #Predicate<Bookmark> { bookmark in
            bookmark.document?.id == documentID
        }
        let descriptor = FetchDescriptor<Bookmark>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.pageIndex)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func addBookmark(pageIndex: Int, document: PDFDocumentRecord) {
        let context = modelContainer.mainContext
        let bookmark = Bookmark(pageIndex: pageIndex, document: document)
        context.insert(bookmark)
        try? context.save()
    }

    func removeBookmark(pageIndex: Int, document: PDFDocumentRecord) {
        let context = modelContainer.mainContext
        let documentID = document.id
        let predicate = #Predicate<Bookmark> { bookmark in
            bookmark.document?.id == documentID && bookmark.pageIndex == pageIndex
        }
        let descriptor = FetchDescriptor<Bookmark>(predicate: predicate)
        if let existing = try? context.fetch(descriptor) {
            for bookmark in existing {
                context.delete(bookmark)
            }
            try? context.save()
        }
    }

    func hasBookmark(pageIndex: Int, document: PDFDocumentRecord) -> Bool {
        let context = modelContainer.mainContext
        let documentID = document.id
        let predicate = #Predicate<Bookmark> { bookmark in
            bookmark.document?.id == documentID && bookmark.pageIndex == pageIndex
        }
        var descriptor = FetchDescriptor<Bookmark>(predicate: predicate)
        descriptor.fetchLimit = 1
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }
}
