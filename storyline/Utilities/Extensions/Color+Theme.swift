import SwiftUI

extension Color {
    // MARK: - Theme Colors

    /// Primary accent color (BookBeat-inspired purple)
    static let themePrimary = Color("ThemePrimary")

    /// Secondary accent color
    static let themeSecondary = Color("ThemeSecondary")

    /// Background color for cards and modals
    static let cardBackground = Color(.systemBackground)

    /// Secondary background for grouped content
    static let secondaryCardBackground = Color(.secondarySystemBackground)

    /// Tertiary background for nested content
    static let tertiaryCardBackground = Color(.tertiarySystemBackground)

    /// Progress color for playback indicators
    static let progressColor = Color.accentColor

    /// Color for finished/completed items
    static let completedColor = Color.green

    /// Color for warning states
    static let warningColor = Color.orange

    /// Color for error states
    static let errorColor = Color.red

    // MARK: - Dynamic Colors

    /// Adaptive text color based on color scheme
    static let adaptiveText = Color.primary

    /// Adaptive secondary text color
    static let adaptiveSecondaryText = Color.secondary

    /// Adaptive border color
    static let adaptiveBorder = Color(.separator)

    // MARK: - Gradient Colors

    /// Gradient for player background
    static let playerGradient = LinearGradient(
        colors: [Color.black.opacity(0.8), Color.black.opacity(0.4)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gradient for empty state
    static let emptyStateGradient = LinearGradient(
        colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Custom Colors for Specific Uses

    /// Color for play button
    static let playButtonColor = Color.accentColor

    /// Color for pause button
    static let pauseButtonColor = Color.accentColor

    /// Color for skip buttons
    static let skipButtonColor = Color.secondary

    /// Color for speed button
    static let speedButtonColor = Color.accentColor

    /// Color for sleep timer when active
    static let sleepTimerActiveColor = Color.orange

    /// Color for sleep timer when inactive
    static let sleepTimerInactiveColor = Color.secondary

    // MARK: - Accessibility Colors

    /// High contrast color for accessibility
    static let highContrast = Color.primary

    /// Color for VoiceOver indicators
    static let voiceOverIndicator = Color.accentColor

    // MARK: - Initialization for Custom Colors

    /// Creates a color with proper light/dark mode support
    /// - Parameters:
    ///   - light: Color to use in light mode
    ///   - dark: Color to use in dark mode
    /// - Returns: Dynamic color that adapts to color scheme
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// Creates a color for books with different states
    /// - Parameter isPlaying: Whether the book is currently playing
    /// - Returns: Color representing the book's state
    static func forBookState(isPlaying: Bool) -> Color {
        if isPlaying {
            return playButtonColor
        } else {
            return adaptiveSecondaryText
        }
    }

    /// Creates a color for progress indication
    /// - Parameter progress: Progress value between 0 and 1
    /// - Returns: Color based on progress
    static func forProgress(_ progress: Double) -> Color {
        switch progress {
        case 0..<0.25:
            return progressColor
        case 0.25..<0.5:
            return progressColor.opacity(0.8)
        case 0.5..<0.75:
            return progressColor.opacity(0.6)
        case 0.75..<1.0:
            return completedColor
        default:
            return completedColor
        }
    }
}