import SwiftUI

// MARK: - Toolbar Mode (extensible by future phases)

enum ToolbarMode: String, CaseIterable, Identifiable {
    case reading
    // Phase 2: case annotating
    // Phase 4: case editing
    // Phase 5: case form
    // Phase 7: case measuring

    var id: String { rawValue }
}

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable, Identifiable {
    case singlePage
    case singlePageContinuous
    case twoUp
    case twoUpContinuous

    var id: String { rawValue }

    var label: String {
        switch self {
        case .singlePage: "Single Page"
        case .singlePageContinuous: "Continuous"
        case .twoUp: "Two Pages"
        case .twoUpContinuous: "Two Pages Continuous"
        }
    }

    var icon: String {
        switch self {
        case .singlePage: "doc.text"
        case .singlePageContinuous: "scroll"
        case .twoUp: "book.pages"
        case .twoUpContinuous: "book.pages.fill"
        }
    }

    var shortcutKey: KeyEquivalent {
        switch self {
        case .singlePage: "1"
        case .singlePageContinuous: "2"
        case .twoUp: "3"
        case .twoUpContinuous: "4"
        }
    }

    var shortcutModifiers: EventModifiers { [.command] }
}

// MARK: - Appearance

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    case sepia

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        case .sepia: "Sepia"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        case .sepia: "eyeglasses"
        }
    }
}

// MARK: - Sidebar Section

enum SidebarTab: String, CaseIterable, Identifiable {
    case thumbnails
    case outline
    case bookmarks
    // Phase 2: case annotations

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thumbnails: "Thumbnails"
        case .outline: "Table of Contents"
        case .bookmarks: "Bookmarks"
        }
    }

    var icon: String {
        switch self {
        case .thumbnails: "square.grid.2x2"
        case .outline: "list.bullet.indent"
        case .bookmarks: "bookmark"
        }
    }
}

// MARK: - Library Sort

enum LibrarySortOrder: String, CaseIterable, Identifiable {
    case name
    case dateImported
    case dateOpened
    case size

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name: "Name"
        case .dateImported: "Date Imported"
        case .dateOpened: "Last Opened"
        case .size: "Size"
        }
    }
}
