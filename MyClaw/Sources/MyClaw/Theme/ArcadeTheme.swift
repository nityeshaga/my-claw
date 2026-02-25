import SwiftUI

/// Design tokens for the Arcade dark theme — BOLD edition.
enum Theme {

    // MARK: - Accent Colors (from app icon palette)

    static let coral = Color(red: 1.0, green: 0.42, blue: 0.42)           // #FF6B6B
    static let terracotta = Color(red: 0.878, green: 0.478, blue: 0.373)  // #E07A5F
    static let cream = Color(red: 1.0, green: 0.945, blue: 0.902)         // #FFF1E6

    // MARK: - Neon Accents

    static let neonCyan = Color(red: 0.306, green: 0.804, blue: 0.769)    // #4ECDC4
    static let neonAmber = Color(red: 1.0, green: 0.851, blue: 0.239)     // #FFD93D
    static let neonPurple = Color(red: 0.655, green: 0.545, blue: 0.98)   // #A78BFA

    // MARK: - Semantic Colors

    static let success = Color(red: 0.204, green: 0.827, blue: 0.6)       // #34D399
    static let error = Color(red: 0.973, green: 0.443, blue: 0.443)       // #F87171
    static let warning = Color(red: 0.984, green: 0.749, blue: 0.141)     // #FBBF24

    // MARK: - Surface Colors (custom painted — NOT system dark)

    /// Deep background — near-black with hint of purple/warm
    static let bgDeep = Color(red: 0.06, green: 0.055, blue: 0.09)
    /// Card/panel backgrounds
    static let surfaceDark = Color(red: 0.10, green: 0.09, blue: 0.14)
    /// Hover/active/elevated surfaces
    static let surfaceElevated = Color(red: 0.14, green: 0.13, blue: 0.19)
    /// Text fields, input areas
    static let surfaceInput = Color(red: 0.08, green: 0.07, blue: 0.11)

    // MARK: - Text Colors

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.3)

    // MARK: - Typography

    static let displayMono: Font = .system(.largeTitle, design: .monospaced).bold()
    static let titleMono: Font = .system(.title2, design: .monospaced).weight(.semibold)
    static let headingMono: Font = .system(.headline, design: .monospaced).weight(.medium)
    static let bodyText: Font = .system(.body)
    static let dataMono: Font = .system(.callout, design: .monospaced)
    static let captionMono: Font = .system(.caption, design: .monospaced)
    static let codeMono: Font = .system(.caption2, design: .monospaced)

    // MARK: - Big numbers (for scoreboard)

    static let scoreFont: Font = .system(size: 28, weight: .bold, design: .monospaced)
}
