import SwiftUI
import PDFKit

struct OutlineSidebarView: View {
    let viewModel: ReaderViewModel

    var body: some View {
        if let root = viewModel.pdfDocument?.outlineRoot,
           root.numberOfChildren > 0 {
            List {
                OutlineNodeView(
                    outline: root,
                    viewModel: viewModel
                )
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        } else {
            ContentUnavailableView(
                "No Outline Available",
                systemImage: "list.bullet.indent",
                description: Text("This document does not contain a table of contents.")
            )
        }
    }
}

// MARK: - Recursive Outline Node

private struct OutlineNodeView: View {
    let outline: PDFOutline
    let viewModel: ReaderViewModel

    var body: some View {
        ForEach(0..<outline.numberOfChildren, id: \.self) { index in
            if let child = outline.child(at: index) {
                outlineEntry(child)
            }
        }
    }

    @ViewBuilder
    private func outlineEntry(_ item: PDFOutline) -> some View {
        let pageIndex = pageIndex(for: item)
        let isCurrentPage = pageIndex.map { $0 == viewModel.currentPageIndex } ?? false

        if item.numberOfChildren > 0 {
            DisclosureGroup {
                OutlineNodeView(outline: item, viewModel: viewModel)
            } label: {
                outlineLabel(item, pageIndex: pageIndex, isCurrentPage: isCurrentPage)
            }
        } else {
            outlineLabel(item, pageIndex: pageIndex, isCurrentPage: isCurrentPage)
        }
    }

    @ViewBuilder
    private func outlineLabel(
        _ item: PDFOutline,
        pageIndex: Int?,
        isCurrentPage: Bool
    ) -> some View {
        Button {
            if let index = pageIndex {
                viewModel.goToPage(index)
            }
        } label: {
            HStack {
                Text(item.label ?? "Untitled")
                    .foregroundStyle(isCurrentPage ? Color.accentColor : .primary)
                    .fontWeight(isCurrentPage ? .semibold : .regular)

                Spacer()

                if let index = pageIndex {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func pageIndex(for item: PDFOutline) -> Int? {
        guard let page = item.destination?.page,
              let document = viewModel.pdfDocument else {
            return nil
        }
        return document.index(for: page)
    }
}
