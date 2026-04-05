import SwiftUI

/// Bottom status bar registered via safeAreaBar — the system handles
/// scroll-edge effects and glass integration automatically.
struct StatusBarView: View {
    let viewModel: ReaderViewModel

    @State private var showPagePopover = false
    @State private var pageInputText = ""

    var body: some View {
        HStack(spacing: 0) {
            pageIndicator
            statusDivider
            fileName
            statusDivider
            readingProgress
            statusDivider
            zoomIndicator
            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Sections

    private var pageIndicator: some View {
        Button {
            pageInputText = "\(viewModel.currentPageIndex + 1)"
            showPagePopover = true
        } label: {
            Text("Page \(viewModel.currentPageIndex + 1) / \(viewModel.totalPages)")
                .monospacedDigit()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .popover(isPresented: $showPagePopover, arrowEdge: .top) {
            pageInputPopover
        }
    }

    private var fileName: some View {
        Text(viewModel.documentModel.fileName)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: 200)
            .padding(.horizontal, 10)
    }

    private var readingProgress: some View {
        HStack(spacing: 6) {
            Text("\(viewModel.readingProgressPercentage)%")
                .monospacedDigit()

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.tertiary)
                        .frame(height: 3)
                    Capsule()
                        .fill(.secondary)
                        .frame(
                            width: geometry.size.width
                                * CGFloat(viewModel.readingProgressPercentage) / 100.0,
                            height: 3
                        )
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(width: 48)
        }
        .padding(.horizontal, 10)
    }

    private var zoomIndicator: some View {
        Text("\(viewModel.zoomPercentage)%")
            .monospacedDigit()
            .padding(.horizontal, 10)
    }

    // MARK: - Helpers

    private var statusDivider: some View {
        Rectangle()
            .fill(.separator)
            .frame(width: 1, height: 14)
    }

    private var pageInputPopover: some View {
        VStack(spacing: 8) {
            Text("Go to Page")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Page number", text: $pageInputText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.center)
                .onSubmit {
                    if let page = Int(pageInputText),
                       page >= 1, page <= viewModel.totalPages {
                        viewModel.goToPage(page - 1)
                    }
                    showPagePopover = false
                }
        }
        .padding(12)
    }
}
