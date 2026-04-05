import SwiftUI

struct AppCommands: Commands {
    let appState: AppState

    var body: some Commands {
        // File menu
        CommandGroup(after: .newItem) {
            Button("Import PDF...") {
                appState.showFileImporter = true
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        // View menu
        CommandMenu("View") {
            Menu("Display Mode") {
                ForEach(DisplayMode.allCases) { mode in
                    Button(mode.label) {
                        appState.readerViewModel?.displayMode = mode
                    }
                    .keyboardShortcut(mode.shortcutKey, modifiers: mode.shortcutModifiers)
                }
            }

            Divider()

            Button("Zoom In") {
                appState.readerViewModel?.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                appState.readerViewModel?.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Actual Size") {
                appState.readerViewModel?.resetZoom()
            }
            .keyboardShortcut("0", modifiers: .command)

            Divider()

            Button("Toggle Sidebar") {
                appState.showSidebar.toggle()
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }

        // Go menu
        CommandMenu("Go") {
            Button("Next Page") {
                appState.readerViewModel?.nextPage()
            }
            .keyboardShortcut(.downArrow, modifiers: [])

            Button("Previous Page") {
                appState.readerViewModel?.previousPage()
            }
            .keyboardShortcut(.upArrow, modifiers: [])

            Divider()

            Button("Go to Page...") {
                appState.showGoToPage = true
            }
            .keyboardShortcut("g", modifiers: .command)
        }
    }
}
