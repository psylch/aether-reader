import SwiftUI
import PDFKit

/// NSViewRepresentable wrapping PDFView from PDFKit.
/// Bridges AppKit's PDFView into SwiftUI and keeps ReaderViewModel in sync
/// with page changes and scale changes via NotificationCenter observers.
struct PDFKitView: NSViewRepresentable {
    let viewModel: ReaderViewModel

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Hand the reference to the view model so it can drive navigation/zoom
        viewModel.pdfView = pdfView

        // Base configuration
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = true
        pdfView.displayDirection = .vertical
        pdfView.maxScaleFactor = 5.0
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit

        applyDisplayMode(to: pdfView)
        PDFKitView.applyAppearanceBackground(to: pdfView, appearance: .system)

        // Assign the document if already loaded
        if let document = viewModel.pdfDocument {
            pdfView.document = document
        }

        // Observe page changes
        context.coordinator.observePageChanged(pdfView: pdfView)
        context.coordinator.observeScaleChanged(pdfView: pdfView)

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update document when it changes
        if pdfView.document !== viewModel.pdfDocument {
            pdfView.document = viewModel.pdfDocument

            // Restore last read page after document assignment
            if let doc = viewModel.pdfDocument,
               viewModel.currentPageIndex > 0,
               viewModel.currentPageIndex < doc.pageCount,
               let page = doc.page(at: viewModel.currentPageIndex) {
                pdfView.go(to: page)
            }

            // Default to actual size (100%)
            DispatchQueue.main.async {
                viewModel.resetZoom()
            }
        }

        // Sync display mode
        applyDisplayMode(to: pdfView)

        // Sync auto-scale vs manual scale
        if viewModel.autoScales {
            pdfView.autoScales = true
        } else if abs(pdfView.scaleFactor - viewModel.scaleFactor) > 0.001 {
            pdfView.scaleFactor = viewModel.scaleFactor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Display Mode

    private func applyDisplayMode(to pdfView: PDFView) {
        let target: PDFDisplayMode = switch viewModel.displayMode {
        case .singlePage: .singlePage
        case .singlePageContinuous: .singlePageContinuous
        case .twoUp: .twoUp
        case .twoUpContinuous: .twoUpContinuous
        }
        if pdfView.displayMode != target {
            pdfView.displayMode = target
        }
    }

    // MARK: - Appearance Background

    /// Applies a background color matching the appearance mode.
    /// Sepia uses a warm tint; other modes defer to default PDFView behavior.
    static func applyAppearance(_ appearance: AppearanceMode, to pdfView: PDFView) {
        applyAppearanceBackground(to: pdfView, appearance: appearance)
    }

    private static func applyAppearanceBackground(to pdfView: PDFView, appearance: AppearanceMode) {
        switch appearance {
        case .sepia:
            pdfView.backgroundColor = NSColor(
                red: 0.96, green: 0.92, blue: 0.84, alpha: 1.0
            )
        case .light:
            pdfView.backgroundColor = NSColor.underPageBackgroundColor
        case .dark:
            pdfView.backgroundColor = NSColor.underPageBackgroundColor
        case .system:
            pdfView.backgroundColor = NSColor.underPageBackgroundColor
        }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject {
        let viewModel: ReaderViewModel
        private nonisolated(unsafe) var pageObserver: NSObjectProtocol?
        private nonisolated(unsafe) var scaleObserver: NSObjectProtocol?

        init(viewModel: ReaderViewModel) {
            self.viewModel = viewModel
        }

        func observePageChanged(pdfView: PDFView) {
            pageObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: pdfView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self,
                          let currentPage = pdfView.currentPage else { return }
                    self.viewModel.updateCurrentPage(currentPage)
                }
            }
        }

        func observeScaleChanged(pdfView: PDFView) {
            scaleObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewScaleChanged,
                object: pdfView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.viewModel.scaleFactor = pdfView.scaleFactor
                }
            }
        }

        deinit {
            if let pageObserver { NotificationCenter.default.removeObserver(pageObserver) }
            if let scaleObserver { NotificationCenter.default.removeObserver(scaleObserver) }
        }
    }
}
