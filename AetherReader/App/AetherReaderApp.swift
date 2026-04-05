import SwiftUI
import SwiftData

@main
struct AetherReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PDFDocumentRecord.self, Bookmark.self])
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LibraryView()
        }
    }
}
