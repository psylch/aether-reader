import Foundation
import PDFKit
import SwiftData

actor FileService {
    static let shared = FileService()

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AetherReader/PDFs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func importPDF(from sourceURL: URL) throws -> (fileName: String, relativePath: String, fileSize: Int64, pageCount: Int, title: String?, author: String?) {
        let fileName = sourceURL.lastPathComponent
        let destinationName = uniqueFileName(fileName)
        let destinationURL = storageURL.appendingPathComponent(destinationName)

        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing { sourceURL.stopAccessingSecurityScopedResource() }
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        var pageCount = 0
        var title: String?
        var author: String?

        if let doc = PDFDocument(url: destinationURL) {
            pageCount = doc.pageCount
            title = doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
            author = doc.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        }

        return (fileName, destinationName, fileSize, pageCount, title, author)
    }

    func pdfURL(for relativePath: String) -> URL {
        storageURL.appendingPathComponent(relativePath)
    }

    func deletePDF(relativePath: String) throws {
        let url = storageURL.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: url)
    }

    func revealInFinder(relativePath: String) {
        let url = storageURL.appendingPathComponent(relativePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func uniqueFileName(_ name: String) -> String {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = name
        var counter = 1

        while FileManager.default.fileExists(atPath: storageURL.appendingPathComponent(candidate).path) {
            candidate = "\(base) (\(counter)).\(ext)"
            counter += 1
        }
        return candidate
    }
}
