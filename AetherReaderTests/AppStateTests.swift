import Testing
@testable import AetherReader

@Suite("AppState Tests")
@MainActor
struct AppStateTests {

    // MARK: - Helpers

    private func makeDocument(
        fileName: String = "test.pdf"
    ) -> PDFDocumentModel {
        PDFDocumentModel(
            fileName: fileName,
            filePath: "/docs/\(fileName)",
            fileSize: 2048,
            pageCount: 20
        )
    }

    // MARK: - Initial State

    @Test("Initial state has no activeDocument")
    func initialNoActiveDocument() {
        let state = AppState()

        #expect(state.activeDocument == nil)
    }

    @Test("Initial state has showSidebar true")
    func initialShowSidebar() {
        let state = AppState()

        #expect(state.showSidebar == true)
    }

    @Test("Initial toolbarMode is .reading")
    func initialToolbarMode() {
        let state = AppState()

        #expect(state.toolbarMode == .reading)
    }

    @Test("Initial readerViewModel is nil")
    func initialReaderViewModel() {
        let state = AppState()

        #expect(state.readerViewModel == nil)
    }

    @Test("Initial appearance is .system")
    func initialAppearance() {
        let state = AppState()

        #expect(state.appearance == .system)
    }

    @Test("Initial showFileImporter is false")
    func initialShowFileImporter() {
        let state = AppState()

        #expect(state.showFileImporter == false)
    }

    // MARK: - openDocument

    @Test("openDocument sets activeDocument")
    func openDocumentSetsActive() {
        let state = AppState()
        let doc = makeDocument()

        state.openDocument(doc)

        #expect(state.activeDocument === doc)
    }

    @Test("openDocument replaces previous activeDocument")
    func openDocumentReplaces() {
        let state = AppState()
        let doc1 = makeDocument(fileName: "first.pdf")
        let doc2 = makeDocument(fileName: "second.pdf")

        state.openDocument(doc1)
        #expect(state.activeDocument === doc1)

        state.openDocument(doc2)
        #expect(state.activeDocument === doc2)
    }

    // MARK: - closeDocument

    @Test("closeDocument clears activeDocument")
    func closeDocumentClearsActive() {
        let state = AppState()
        let doc = makeDocument()

        state.openDocument(doc)
        #expect(state.activeDocument != nil)

        state.closeDocument()
        #expect(state.activeDocument == nil)
    }

    @Test("closeDocument clears readerViewModel")
    func closeDocumentClearsReader() {
        let state = AppState()
        let doc = makeDocument()

        state.openDocument(doc)
        state.readerViewModel = ReaderViewModel(documentModel: doc)
        #expect(state.readerViewModel != nil)

        state.closeDocument()
        #expect(state.readerViewModel == nil)
    }

    @Test("closeDocument resets toolbarMode to .reading")
    func closeDocumentResetsToolbarMode() {
        let state = AppState()
        let doc = makeDocument()

        state.openDocument(doc)
        state.toolbarMode = .reading // only mode for now, but test the reset
        // Simulate a future mode change by directly setting
        state.closeDocument()

        #expect(state.toolbarMode == .reading)
    }

    @Test("closeDocument is safe to call without an open document")
    func closeDocumentWhenNoneOpen() {
        let state = AppState()

        state.closeDocument()

        #expect(state.activeDocument == nil)
        #expect(state.readerViewModel == nil)
        #expect(state.toolbarMode == .reading)
    }

    // MARK: - Sidebar Toggle

    @Test("showSidebar can be toggled")
    func toggleSidebar() {
        let state = AppState()

        state.showSidebar = false
        #expect(state.showSidebar == false)

        state.showSidebar = true
        #expect(state.showSidebar == true)
    }

    // MARK: - Appearance

    @Test("Appearance can be changed")
    func changeAppearance() {
        let state = AppState()

        state.appearance = .dark
        #expect(state.appearance == .dark)

        state.appearance = .sepia
        #expect(state.appearance == .sepia)

        state.appearance = .light
        #expect(state.appearance == .light)
    }
}
