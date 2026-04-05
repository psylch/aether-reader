import Foundation

protocol FileServiceProtocol: Sendable {
    func importPDF(from url: URL) async throws -> (storagePath: String, pageCount: Int, fileSize: Int64, thumbnailData: Data?)
    func deletePDF(at storagePath: String) throws
    func pdfURL(for storagePath: String) -> URL
}
