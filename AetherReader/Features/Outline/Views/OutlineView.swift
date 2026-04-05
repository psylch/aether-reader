import SwiftUI
@preconcurrency import PDFKit

struct OutlineView: View {
    let items: [OutlineItem]
    let onSelect: (PDFDestination) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { node in
                    OutlineNodeView(node: node, onSelect: { dest in
                        onSelect(dest)
                        dismiss()
                    })
                }
            }
            .navigationTitle("Table of Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct OutlineNodeView: View {
    let node: OutlineItem
    let onSelect: (PDFDestination) -> Void

    var body: some View {
        if node.children.isEmpty {
            Button {
                if let dest = node.destination { onSelect(dest) }
            } label: {
                Text(node.label)
                    .foregroundStyle(.primary)
            }
        } else {
            DisclosureGroup {
                ForEach(node.children) { child in
                    OutlineNodeView(node: child, onSelect: onSelect)
                }
            } label: {
                Button {
                    if let dest = node.destination { onSelect(dest) }
                } label: {
                    Text(node.label)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
