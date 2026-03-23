import SwiftUI

enum Theme {
    static let primaryTeal = Color(red: 0.102, green: 0.478, blue: 0.431)
    static let primaryLight = Color(red: 0.910, green: 0.961, blue: 0.953)
    static let accent = Color(red: 0.957, green: 0.643, blue: 0.259)

    // Adaptive colours — work in both light and dark mode
    static let backgroundMain = Color(.systemGroupedBackground)
    static let cardBackground = Color(.systemBackground)
    static let inputBackground = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let border = Color(.separator)
}
