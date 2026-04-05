import SwiftUI
@preconcurrency import PDFKit

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPageIndex: Int
    @Binding var scaleFactor: CGFloat
    var displayMode: PDFDisplayMode = .singlePageContinuous
    var navigateToSelection: PDFSelection?
    var navigateToDestination: PDFDestination?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = displayMode
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.document = document

        context.coordinator.pdfView = pdfView
        context.coordinator.startObserving()

        if let doc = document, currentPageIndex > 0,
           let page = doc.page(at: currentPageIndex) {
            pdfView.go(to: page)
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        let coordinator = context.coordinator
        coordinator.isUpdatingFromSwiftUI = true
        defer { coordinator.isUpdatingFromSwiftUI = false }

        if pdfView.document !== document {
            pdfView.document = document
        }

        if pdfView.displayMode != displayMode {
            pdfView.displayMode = displayMode
        }

        if let doc = document,
           let targetPage = doc.page(at: currentPageIndex),
           pdfView.currentPage !== targetPage {
            pdfView.go(to: targetPage)
        }

        if abs(pdfView.scaleFactor - scaleFactor) > 0.01 {
            pdfView.scaleFactor = scaleFactor
        }

        if let selection = navigateToSelection {
            pdfView.setCurrentSelection(selection, animate: true)
            if let firstPage = selection.pages.first {
                let bounds = selection.bounds(for: firstPage)
                pdfView.go(to: bounds, on: firstPage)
            }
        }

        if let destination = navigateToDestination {
            pdfView.go(to: destination)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject {
        var parent: PDFKitView
        var isUpdatingFromSwiftUI = false
        weak var pdfView: PDFView?
        private var observers: [NSObjectProtocol] = []

        init(_ parent: PDFKitView) {
            self.parent = parent
            super.init()
        }

        func startObserving() {
            let pageObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: pdfView,
                queue: .main
            ) { [weak self] _ in
                self?.handlePageChanged()
            }

            let scaleObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewScaleChanged,
                object: pdfView,
                queue: .main
            ) { [weak self] _ in
                self?.handleScaleChanged()
            }

            observers = [pageObserver, scaleObserver]
        }

        private func handlePageChanged() {
            guard !isUpdatingFromSwiftUI,
                  let pdfView,
                  let page = pdfView.currentPage,
                  let index = pdfView.document?.index(for: page),
                  index != parent.currentPageIndex
            else { return }
            parent.currentPageIndex = index
        }

        private func handleScaleChanged() {
            guard !isUpdatingFromSwiftUI,
                  let pdfView,
                  abs(pdfView.scaleFactor - parent.scaleFactor) > 0.01
            else { return }
            parent.scaleFactor = pdfView.scaleFactor
        }

        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }
}
