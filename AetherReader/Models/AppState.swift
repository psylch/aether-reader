import SwiftUI
import PDFKit

@Observable
final class AppState {
    // Navigation
    var activeDocument: PDFDocumentModel?
    var showSidebar: Bool = true
    var showFileImporter: Bool = false
    var showGoToPage: Bool = false

    // Toolbar
    var toolbarMode: ToolbarMode = .reading

    // Reader (set when ReaderView appears)
    var readerViewModel: ReaderViewModel?

    // Appearance
    var appearance: AppearanceMode = .system

    func openDocument(_ document: PDFDocumentModel) {
        activeDocument = document
    }

    func closeDocument() {
        activeDocument = nil
        readerViewModel = nil
        toolbarMode = .reading
    }
}
