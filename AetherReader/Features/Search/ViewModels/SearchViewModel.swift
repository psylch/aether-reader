import SwiftUI
@preconcurrency import PDFKit

@Observable
@MainActor
final class SearchViewModel {
    var searchText: String = ""
    var isActive: Bool = false
    var results: [PDFSelection] = []
    var currentIndex: Int = 0

    var totalCount: Int { results.count }
    var hasResults: Bool { !results.isEmpty }
    var currentResult: PDFSelection? {
        guard currentIndex >= 0, currentIndex < results.count else { return nil }
        return results[currentIndex]
    }

    private weak var document: PDFDocument?

    func setDocument(_ document: PDFDocument?) {
        self.document = document
    }

    func search() {
        guard let document, !searchText.isEmpty else {
            clearSearch()
            return
        }

        clearHighlights()
        results = document.findString(searchText, withOptions: .caseInsensitive)
        currentIndex = 0
        applyHighlights()
    }

    func nextResult() {
        guard hasResults else { return }
        currentIndex = (currentIndex + 1) % results.count
    }

    func previousResult() {
        guard hasResults else { return }
        currentIndex = (currentIndex - 1 + results.count) % results.count
    }

    func clearSearch() {
        clearHighlights()
        results = []
        currentIndex = 0
        searchText = ""
    }

    func dismiss() {
        clearSearch()
        isActive = false
    }

    private func applyHighlights() {
        for selection in results {
            selection.pages.forEach { page in
                let highlight = PDFAnnotation(
                    bounds: selection.bounds(for: page),
                    forType: .highlight,
                    withProperties: nil
                )
                highlight.color = UIColor.yellow.withAlphaComponent(0.3)
                highlight.setValue("AetherSearchHighlight", forAnnotationKey: .contents)
                page.addAnnotation(highlight)
            }
        }
    }

    private func clearHighlights() {
        guard let document else { return }
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let toRemove = page.annotations.filter {
                $0.value(forAnnotationKey: .contents) as? String == "AetherSearchHighlight"
            }
            toRemove.forEach { page.removeAnnotation($0) }
        }
    }
}
