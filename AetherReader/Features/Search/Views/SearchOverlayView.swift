import SwiftUI

struct SearchOverlayView: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search in document", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            viewModel.search()
                        }
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

                if viewModel.hasResults {
                    resultNavigation
                }

                Button("Done") {
                    viewModel.dismiss()
                }
                .fontWeight(.medium)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .glassEffect(in: .rect(cornerRadius: 16))

            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private var resultNavigation: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button { viewModel.previousResult() } label: {
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
            }
            Button { viewModel.nextResult() } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
        }
    }
}
