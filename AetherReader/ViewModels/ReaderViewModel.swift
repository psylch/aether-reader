import SwiftUI
import PDFKit

@MainActor
@Observable
final class ReaderViewModel {
    // Document
    let documentModel: PDFDocumentModel
    private(set) var pdfDocument: PDFDocument?

    // Page navigation
    private(set) var currentPageIndex: Int = 0
    private(set) var totalPages: Int = 0

    // Display
    var displayMode: DisplayMode = .singlePageContinuous {
        didSet { applyDisplayMode() }
    }
    var scaleFactor: CGFloat = 1.0
    var autoScales: Bool = true

    // Search
    var searchText: String = ""
    private(set) var searchResults: [PDFSelection] = []
    private(set) var currentSearchIndex: Int = 0

    // Internal reference to PDFView (set by PDFKitView)
    weak var pdfView: PDFView?

    // Zoom limits
    private let minScale: CGFloat = 0.25
    private let maxScale: CGFloat = 5.0
    private let zoomStep: CGFloat = 0.25

    init(documentModel: PDFDocumentModel) {
        self.documentModel = documentModel
        self.currentPageIndex = documentModel.lastReadPage
    }

    // MARK: - Document Loading

    func loadDocument(from url: URL) {
        guard let document = PDFDocument(url: url) else { return }
        self.pdfDocument = document
        self.totalPages = document.pageCount

        if currentPageIndex > 0, currentPageIndex < totalPages,
           let page = document.page(at: currentPageIndex) {
            pdfView?.go(to: page)
        }
    }

    // MARK: - Page Navigation

    func nextPage() {
        guard let pdfView, pdfView.canGoToNextPage else { return }
        pdfView.goToNextPage(nil)
    }

    func previousPage() {
        guard let pdfView, pdfView.canGoToPreviousPage else { return }
        pdfView.goToPreviousPage(nil)
    }

    func goToPage(_ index: Int) {
        guard let doc = pdfDocument, index >= 0, index < totalPages,
              let page = doc.page(at: index) else { return }
        pdfView?.go(to: page)
    }

    func updateCurrentPage(_ page: PDFPage) {
        guard let doc = pdfDocument,
              let index = doc.index(for: page) as Int? else { return }
        currentPageIndex = index
        documentModel.lastReadPage = index
        documentModel.readingProgress = totalPages > 0
            ? Double(index) / Double(totalPages - 1)
            : 0.0
    }

    // MARK: - Zoom

    func zoomIn() {
        let newScale = min(scaleFactor + zoomStep, maxScale)
        setScale(newScale)
    }

    func zoomOut() {
        let newScale = max(scaleFactor - zoomStep, minScale)
        setScale(newScale)
    }

    func resetZoom() {
        setScale(1.0)
    }

    func fitToWidth() {
        guard let pdfView else { return }
        pdfView.autoScales = true
        autoScales = true
        scaleFactor = pdfView.scaleFactor
    }

    func fitToPage() {
        guard let pdfView else { return }
        let fitScale = pdfView.scaleFactorForSizeToFit
        if fitScale > 0 {
            setScale(fitScale)
        }
    }

    private func setScale(_ scale: CGFloat) {
        autoScales = false
        scaleFactor = scale
        pdfView?.scaleFactor = scale
    }

    // MARK: - Display Mode

    private func applyDisplayMode() {
        guard let pdfView else { return }
        switch displayMode {
        case .singlePage:
            pdfView.displayMode = .singlePage
        case .singlePageContinuous:
            pdfView.displayMode = .singlePageContinuous
        case .twoUp:
            pdfView.displayMode = .twoUp
        case .twoUpContinuous:
            pdfView.displayMode = .twoUpContinuous
        }
    }

    // MARK: - Search

    func performSearch() {
        guard !searchText.isEmpty, let doc = pdfDocument else {
            searchResults = []
            return
        }
        searchResults = doc.findString(searchText, withOptions: .caseInsensitive)
        currentSearchIndex = 0
        navigateToCurrentSearchResult()
    }

    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        navigateToCurrentSearchResult()
    }

    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        navigateToCurrentSearchResult()
    }

    private func navigateToCurrentSearchResult() {
        guard currentSearchIndex < searchResults.count else { return }
        let selection = searchResults[currentSearchIndex]
        pdfView?.setCurrentSelection(selection, animate: true)
        pdfView?.scrollSelectionToVisible(nil)
    }

    // MARK: - Zoom Percentage

    var zoomPercentage: Int {
        Int(scaleFactor * 100)
    }

    var readingProgressPercentage: Int {
        Int(documentModel.readingProgress * 100)
    }
}
