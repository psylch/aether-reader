import Foundation
import PDFKit
import UIKit

final class FileService: FileServiceProtocol, @unchecked Sendable {
    private let fileManager = FileManager.default

    private var pdfDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = documents.appendingPathComponent("PDFs", isDirectory: true)
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
                thumbnailData = image.jpegData(compressionQuality: 0.7)
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
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(storagePath)
    }
}
