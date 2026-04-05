import SwiftUI

struct PDFGridItemView: View {
    let record: PDFDocumentRecord

    var body: some View {
        VStack(spacing: 8) {
            thumbnailView
                .frame(width: 140, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            VStack(spacing: 4) {
                Text(record.fileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                ProgressView(value: record.readingProgress)
                    .tint(.accentColor)
            }
        }
        .frame(width: 140)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = record.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "doc.richtext")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
        }
    }
}
