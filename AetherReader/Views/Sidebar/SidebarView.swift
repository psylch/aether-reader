import SwiftUI
import PDFKit

struct SidebarView: View {
    let viewModel: ReaderViewModel
    @State private var selectedTab: SidebarTab = .thumbnails

    var body: some View {
        // Direct content — no VStack wrapper, no custom backgrounds.
        // NavigationSplitView handles glass automatically.
        Group {
            switch selectedTab {
            case .thumbnails:
                ThumbnailSidebarView(viewModel: viewModel)
            case .outline:
                OutlineSidebarView(viewModel: viewModel)
            case .bookmarks:
                BookmarkSidebarView(
                    viewModel: viewModel,
                    documentModel: viewModel.documentModel
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("View", selection: $selectedTab) {
                    ForEach(SidebarTab.allCases) { tab in
                        Label(tab.label, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
