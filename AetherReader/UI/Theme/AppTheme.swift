import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case auto = "Auto"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum ScrollMode: String, CaseIterable {
    case continuous = "Continuous"
    case singlePage = "Single Page"
}
