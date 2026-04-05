import SwiftUI
import SwiftData

@main
struct AetherReaderApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: [PDFDocumentModel.self, BookmarkModel.self])
        .commands {
            AppCommands(appState: appState)
        }
    }
}
