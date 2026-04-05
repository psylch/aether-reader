import SwiftUI

struct ThumbnailStripView: View {
    @Bindable var viewModel: ThumbnailStripViewModel
    let onPageSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(0..<viewModel.pageCount, id: \.self) { index in
                            thumbnailCell(for: index)
                                .id(index)
                                .onAppear {
                                    viewModel.loadThumbnail(at: index)
                                }
                                .onTapGesture {
                                    onPageSelect(index)
                                    dismiss()
                                }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    proxy.scrollTo(viewModel.currentPageIndex, anchor: .center)
                }
            }
            .navigationTitle("Pages")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func thumbnailCell(for index: Int) -> some View {
        VStack(spacing: 4) {
            Group {
                if let image = viewModel.thumbnails[index] {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(width: 80, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(index == viewModel.currentPageIndex ? Color.accentColor : .clear, lineWidth: 2)
            )

            Text("\(index + 1)")
                .font(.caption2)
                .foregroundStyle(index == viewModel.currentPageIndex ? .primary : .secondary)
        }
    }
}
