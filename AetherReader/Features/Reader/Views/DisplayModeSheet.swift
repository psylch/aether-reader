import SwiftUI

struct DisplayModeSheet: View {
    @Binding var appearanceMode: AppearanceMode
    @Binding var scrollMode: ScrollMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                scrollSection
            }
            .navigationTitle("Display")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            appearanceRow(.auto)
            appearanceRow(.light)
            appearanceRow(.dark)
        }
    }

    private func appearanceRow(_ mode: AppearanceMode) -> some View {
        Button {
            appearanceMode = mode
        } label: {
            HStack {
                Text(mode.rawValue)
                    .foregroundStyle(.primary)
                Spacer()
                if appearanceMode == mode {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private var scrollSection: some View {
        Section("Scroll Mode") {
            scrollRow(.continuous)
            scrollRow(.singlePage)
        }
    }

    private func scrollRow(_ mode: ScrollMode) -> some View {
        Button {
            scrollMode = mode
        } label: {
            HStack {
                Text(mode.rawValue)
                    .foregroundStyle(.primary)
                Spacer()
                if scrollMode == mode {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}
