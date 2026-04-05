import SwiftUI
import SwiftData
import PDFKit

struct BookmarkSidebarView: View {
    let viewModel: ReaderViewModel
    let documentModel: PDFDocumentModel
    @Environment(\.modelContext) private var modelContext

    @State private var editingBookmark: BookmarkModel?
    @State private var editLabel: String = ""

    private var sortedBookmarks: [BookmarkModel] {
        documentModel.bookmarks.sorted { $0.pageIndex < $1.pageIndex }
    }

    var body: some View {
        Group {
            if sortedBookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks Yet",
                    systemImage: "bookmark",
                    description: Text("Tap the button below to bookmark the current page.")
                )
            } else {
                List {
                    ForEach(sortedBookmarks, id: \.id) { bookmark in
                        bookmarkRow(bookmark)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.goToPage(bookmark.pageIndex)
                            }
                            .contextMenu {
                                Button {
                                    editingBookmark = bookmark
                                    editLabel = bookmark.label
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    deleteBookmark(bookmark)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteBookmark(bookmark)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom) {
            addBookmarkButton
                .padding(12)
        }
        .alert("Rename Bookmark", isPresented: isEditingBinding) {
            TextField("Label", text: $editLabel)
            Button("Cancel", role: .cancel) {
                editingBookmark = nil
            }
            Button("Save") {
                if let bookmark = editingBookmark {
                    bookmark.label = editLabel
                    editingBookmark = nil
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func bookmarkRow(_ bookmark: BookmarkModel) -> some View {
        let isCurrentPage = bookmark.pageIndex == viewModel.currentPageIndex

        HStack(spacing: 10) {
            Image(systemName: isCurrentPage ? "bookmark.fill" : "bookmark")
                .foregroundStyle(isCurrentPage ? Color.accentColor : .secondary)
                .imageScale(.medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.label)
                    .fontWeight(isCurrentPage ? .semibold : .regular)
                    .lineLimit(1)

                Text("Page \(bookmark.pageIndex + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var addBookmarkButton: some View {
        Button {
            addBookmarkAtCurrentPage()
        } label: {
            Label("Bookmark This Page", systemImage: "bookmark.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isCurrentPageBookmarked)
    }

    // MARK: - Helpers

    private var isCurrentPageBookmarked: Bool {
        documentModel.bookmarks.contains { $0.pageIndex == viewModel.currentPageIndex }
    }

    private var isEditingBinding: Binding<Bool> {
        Binding(
            get: { editingBookmark != nil },
            set: { if !$0 { editingBookmark = nil } }
        )
    }

    private func addBookmarkAtCurrentPage() {
        let bookmark = BookmarkModel(pageIndex: viewModel.currentPageIndex)
        documentModel.bookmarks.append(bookmark)
        modelContext.insert(bookmark)
    }

    private func deleteBookmark(_ bookmark: BookmarkModel) {
        documentModel.bookmarks.removeAll { $0.id == bookmark.id }
        modelContext.delete(bookmark)
    }
}
