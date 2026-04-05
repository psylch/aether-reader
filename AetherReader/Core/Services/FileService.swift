import Foundation
import PDFKit
import AppKit

final class FileService: FileServiceProtocol, @unchecked Sendable {
    private let fileManager = FileManager.default

    private var pdfDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AetherReader/PDFs", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func importPDF(from url: URL) async throws -> (storagePath: String, pageCount: Int, fileSize: Int64, thumbnailData: Data?) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let id = UUID().uuidString
        let destinationName = "\(id).pdf"
        let destination = pdfDirectory.appendingPathComponent(destinationName)

        try fileManager.copyItem(at: url, to: destination)

        let attributes = try fileManager.attributesOfItem(atPath: destination.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0

        let storagePath = "PDFs/\(destinationName)"

        var pageCount = 0
        var thumbnailData: Data?

        if let document = PDFDocument(url: destination) {
            pageCount = document.pageCount
            if let firstPage = document.page(at: 0) {
                let size = CGSize(width: 200, height: 280)
                let image = firstPage.thumbnail(of: size, for: .cropBox)
                thumbnailData = image.tiffRepresentation.flatMap {
                    NSBitmapImageRep(data: $0)?.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
                }
            }
        }

        return (storagePath, pageCount, fileSize, thumbnailData)
    }

    func deletePDF(at storagePath: String) throws {
        let url = pdfURL(for: storagePath)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func pdfURL(for storagePath: String) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("AetherReader/\(storagePath)")
    }
}
