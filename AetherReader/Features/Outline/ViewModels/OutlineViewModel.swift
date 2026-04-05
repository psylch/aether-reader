import SwiftUI
@preconcurrency import PDFKit

struct OutlineItem: Identifiable {
    let id = UUID()
    let label: String
    let destination: PDFDestination?
    let children: [OutlineItem]
}

@Observable
@MainActor
final class OutlineViewModel {
    var items: [OutlineItem] = []
    var hasOutline: Bool { !items.isEmpty }

    func buildOutline(from root: PDFOutline?) {
        guard let root else {
            items = []
            return
        }
        items = parseChildren(of: root)
    }

    private func parseChildren(of outline: PDFOutline) -> [OutlineItem] {
        (0..<outline.numberOfChildren).compactMap { index in
            guard let child = outline.child(at: index) else { return nil }
            return OutlineItem(
                label: child.label ?? "Untitled",
                destination: child.destination,
                children: parseChildren(of: child)
            )
        }
    }
}
