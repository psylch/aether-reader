import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if let document = appState.activeDocument {
                ReaderView(document: document)
            } else {
                LibraryView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
