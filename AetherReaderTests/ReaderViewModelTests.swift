import Testing
@testable import AetherReader

@Suite("ReaderViewModel Tests")
@MainActor
struct ReaderViewModelTests {

    // MARK: - Helpers

    private func makeDocument(
        lastReadPage: Int = 0,
        readingProgress: Double = 0.0
    ) -> PDFDocumentModel {
        let doc = PDFDocumentModel(
            fileName: "test.pdf",
            filePath: "/docs/test.pdf",
            fileSize: 1024,
            pageCount: 10,
            title: "Test Document"
        )
        doc.lastReadPage = lastReadPage
        doc.readingProgress = readingProgress
        return doc
    }

    // MARK: - Init State

    @Test("Initial currentPageIndex matches documentModel.lastReadPage")
    func initCurrentPageIndex() {
        let doc = makeDocument(lastReadPage: 5)
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.currentPageIndex == 5)
    }

    @Test("Initial currentPageIndex is 0 when lastReadPage is 0")
    func initCurrentPageIndexDefault() {
        let doc = makeDocument()
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.currentPageIndex == 0)
    }

    @Test("totalPages is 0 before loading a document")
    func totalPagesBeforeLoad() {
        let doc = makeDocument()
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.totalPages == 0)
    }

    @Test("pdfDocument is nil before loading")
    func pdfDocumentNilBeforeLoad() {
        let doc = makeDocument()
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.pdfDocument == nil)
    }

    // MARK: - Display Mode

    @Test("Default displayMode is singlePageContinuous")
    func defaultDisplayMode() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        #expect(vm.displayMode == .singlePageContinuous)
    }

    @Test("displayMode can be changed")
    func changeDisplayMode() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.displayMode = .twoUp
        #expect(vm.displayMode == .twoUp)

        vm.displayMode = .singlePage
        #expect(vm.displayMode == .singlePage)

        vm.displayMode = .twoUpContinuous
        #expect(vm.displayMode == .twoUpContinuous)
    }

    // MARK: - Zoom

    @Test("Initial scaleFactor is 1.0")
    func initialScaleFactor() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        #expect(vm.scaleFactor == 1.0)
    }

    @Test("zoomIn increases scaleFactor by 0.25")
    func zoomInStep() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.zoomIn()
        #expect(vm.scaleFactor == 1.25)

        vm.zoomIn()
        #expect(vm.scaleFactor == 1.5)
    }

    @Test("zoomOut decreases scaleFactor by 0.25")
    func zoomOutStep() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.zoomOut()
        #expect(vm.scaleFactor == 0.75)

        vm.zoomOut()
        #expect(vm.scaleFactor == 0.5)
    }

    @Test("scaleFactor cannot go below 0.25")
    func zoomOutMinimum() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        // Zoom out from 1.0 four times: 0.75, 0.50, 0.25, 0.25
        for _ in 0..<10 {
            vm.zoomOut()
        }

        #expect(vm.scaleFactor == 0.25)
    }

    @Test("scaleFactor cannot exceed 5.0")
    func zoomInMaximum() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        // Zoom in many times past the limit
        for _ in 0..<50 {
            vm.zoomIn()
        }

        #expect(vm.scaleFactor == 5.0)
    }

    @Test("zoomIn disables autoScales")
    func zoomInDisablesAutoScales() {
        let vm = ReaderViewModel(documentModel: makeDocument())
        #expect(vm.autoScales == true)

        vm.zoomIn()
        #expect(vm.autoScales == false)
    }

    @Test("zoomOut disables autoScales")
    func zoomOutDisablesAutoScales() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.zoomOut()
        #expect(vm.autoScales == false)
    }

    @Test("resetZoom re-enables autoScales")
    func resetZoomEnablesAutoScales() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.zoomIn()
        #expect(vm.autoScales == false)

        vm.resetZoom()
        #expect(vm.autoScales == true)
    }

    // MARK: - Zoom Percentage

    @Test("zoomPercentage reflects scaleFactor * 100")
    func zoomPercentageComputation() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        #expect(vm.zoomPercentage == 100)

        vm.zoomIn()
        #expect(vm.zoomPercentage == 125)

        vm.zoomOut() // back to 1.0
        vm.zoomOut()
        #expect(vm.zoomPercentage == 75)
    }

    @Test("zoomPercentage at limits")
    func zoomPercentageAtLimits() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        for _ in 0..<50 {
            vm.zoomIn()
        }
        #expect(vm.zoomPercentage == 500)

        for _ in 0..<50 {
            vm.zoomOut()
        }
        #expect(vm.zoomPercentage == 25)
    }

    // MARK: - Search

    @Test("Empty searchText yields empty results")
    func emptySearchText() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.searchText = ""
        vm.performSearch()

        #expect(vm.searchResults.isEmpty)
    }

    @Test("Search without loaded document yields empty results")
    func searchWithoutDocument() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.searchText = "hello"
        vm.performSearch()

        #expect(vm.searchResults.isEmpty)
    }

    @Test("Initial searchText is empty")
    func initialSearchTextEmpty() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        #expect(vm.searchText.isEmpty)
        #expect(vm.searchResults.isEmpty)
    }

    // MARK: - Reading Progress

    @Test("readingProgressPercentage reflects documentModel.readingProgress")
    func readingProgressPercentage() {
        let doc = makeDocument(readingProgress: 0.75)
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.readingProgressPercentage == 75)
    }

    @Test("readingProgressPercentage is 0 for new document")
    func readingProgressPercentageZero() {
        let doc = makeDocument(readingProgress: 0.0)
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.readingProgressPercentage == 0)
    }

    @Test("readingProgressPercentage is 100 for fully read document")
    func readingProgressPercentageFull() {
        let doc = makeDocument(readingProgress: 1.0)
        let vm = ReaderViewModel(documentModel: doc)

        #expect(vm.readingProgressPercentage == 100)
    }

    // MARK: - Page Navigation (without PDFView)

    @Test("nextPage does nothing without pdfView")
    func nextPageWithoutPdfView() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.nextPage()
        #expect(vm.currentPageIndex == 0)
    }

    @Test("previousPage does nothing without pdfView")
    func previousPageWithoutPdfView() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.previousPage()
        #expect(vm.currentPageIndex == 0)
    }

    @Test("goToPage does nothing without loaded pdfDocument")
    func goToPageWithoutDocument() {
        let vm = ReaderViewModel(documentModel: makeDocument())

        vm.goToPage(3)
        #expect(vm.currentPageIndex == 0)
    }
}
