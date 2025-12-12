import Foundation
import SwiftUI

// MARK: - App Constants

struct AppConstants {
    /// App name for display
    static let appName = "Storyline"

    /// App version
    static let appVersion = "1.0.0"

    /// Bundle identifier
    static let bundleIdentifier = "com.storyline"
}

// MARK: - Playback Constants

struct PlaybackConstants {
    /// Default skip interval in seconds
    static let defaultSkipInterval: TimeInterval = 15.0

    /// Available playback speeds
    static let playbackSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5]

    /// Default playback speed
    static let defaultPlaybackSpeed: Float = 1.0

    /// Progress auto-save interval in seconds
    static let progressAutoSaveInterval: TimeInterval = 5.0

    /// Time observer interval for updating UI (in seconds)
    static let timeObserverInterval: TimeInterval = 0.5

    /// Threshold for marking audiobook as finished (seconds before end)
    static let finishedThreshold: TimeInterval = 10.0

    /// Supported audio formats
    static let supportedAudioFormats = ["m4a", "mp3", "wav", "aac", "flac"]

    /// Maximum file size for import (in bytes)
    static let maxFileSize = 500 * 1024 * 1024 // 500MB
}

// MARK: - UI Constants

struct UIConstants {
    /// Corner radius for cards
    static let cornerRadius: CGFloat = 12.0

    /// Corner radius for buttons
    static let buttonCornerRadius: CGFloat = 8.0

    /// Standard padding
    static let standardPadding: CGFloat = 16.0

    /// Small padding
    static let smallPadding: CGFloat = 8.0

    /// Large padding
    static let largePadding: CGFloat = 24.0

    /// Icon size for buttons
    static let iconSize: CGFloat = 24.0

    /// Large icon size for primary buttons
    static let largeIconSize: CGFloat = 32.0

    /// Height for standard rows
    static let rowHeight: CGFloat = 44.0

    /// Height for compact rows
    static let compactRowHeight: CGFloat = 32.0

    /// Minimum touch target size
    static let minTouchTarget: CGFloat = 44.0

    /// Animation duration for standard animations
    static let animationDuration: Double = 0.3

    /// Animation duration for slow animations
    static let slowAnimationDuration: Double = 0.5

    /// Maximum width for compact layouts
    static let maxCompactWidth: CGFloat = 600.0
}

// MARK: - Library Constants

struct LibraryConstants {
    /// Default sort option
    static let defaultSortOption = SortOption.dateAdded

    /// Grid columns for different size classes
    static let gridColumnsCompact = 2
    static let gridColumnsRegular = 3
    static let gridColumnsLarge = 4

    /// Minimum search query length
    static let minSearchLength = 2

    /// Default tags
    static let defaultTags = ["Favorites", "Fiction", "Non-fiction", "Biography", "History", "Science"]
}

// MARK: - Sleep Timer Constants

struct SleepTimerConstants {
    /// Sleep timer options in minutes
    static let timerOptions: [Int] = [5, 10, 15, 30, 60]

    /// Sleep timer option for end of chapter
    static let endOfChapterOption = -1

    /// Notification identifier for sleep timer
    static let notificationIdentifier = "com.storyline.sleepTimer"

    /// Notification title
    static let notificationTitle = "Sleep Timer"

    /// Notification body
    static let notificationBody = "Playback will stop soon"
}

// MARK: - Storage Constants

struct StorageConstants {
    /// Directory name for audiobook storage
    static let audiobookDirectory = "Audiobooks"

    /// Directory name for cached artwork
    static let artworkDirectory = "Artwork"

    /// Maximum cache size for artwork (in bytes)
    static let maxArtworkCacheSize = 50 * 1024 * 1024 // 50MB

    /// File manager directory search options
    static let directorySearchOptions: FileManager.DirectoryEnumerationOptions = [
        .skipsHiddenFiles,
        .skipsPackageDescendants
    ]
}

// MARK: - Settings Constants

struct SettingsConstants {
    /// User preferences keys
    struct UserDefaults {
        static let defaultPlaybackSpeed = "defaultPlaybackSpeed"
        static let defaultSkipInterval = "defaultSkipInterval"
        static let autoPlayNext = "autoPlayNext"
        static let showChapterTitles = "showChapterTitles"
        static let themePreference = "themePreference"
    }

    /// Theme options
    enum ThemePreference: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Identifiable {
    case title = "Title"
    case author = "Author"
    case dateAdded = "Date Added"
    case lastPlayed = "Last Played"
    case progress = "Progress"
    case duration = "Duration"

    var id: String { rawValue }
}

// MARK: - Filter Options

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case unfinished = "Unfinished"
    case finished = "Finished"

    var id: String { rawValue }
}

// MARK: - View Layout Options

enum ViewLayoutOption: String, CaseIterable, Identifiable {
    case grid = "Grid"
    case list = "List"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        }
    }
}

// MARK: - Error Messages

struct ErrorMessages {
    /// General errors
    static let unknownError = "An unknown error occurred. Please try again."
    static let networkError = "Network connection error. Please check your internet connection."

    /// File related errors
    static let fileNotFound = "The audio file could not be found."
    static let invalidFileFormat = "This file format is not supported."
    static let fileSizeExceeded = "The file size exceeds the maximum limit."
    static let fileCorrupted = "The file appears to be corrupted."

    /// Audiobook import errors
    static let importFailed = "Failed to import the audiobook."
    static let downloadFailed = "Failed to download the audiobook."
    static let metadataExtractionFailed = "Could not extract metadata from the file."

    /// Playback errors
    static let playbackFailed = "Failed to start playback."
    static let audioSessionError = "Audio session configuration failed."

    /// Storage errors
    static let storageFull = "Not enough storage space available."
    static let storagePermissionDenied = "Storage permission is required to import audiobooks."
}

// MARK: - Accessibility Identifiers

struct AccessibilityIdentifiers {
    /// General
    static let tabBar = "tabBar"
    static let libraryTab = "libraryTab"
    static let addTab = "addTab"
    static let settingsTab = "settingsTab"

    /// Player
    static let playerView = "playerView"
    static let playButton = "playButton"
    static let pauseButton = "pauseButton"
    static let skipForwardButton = "skipForwardButton"
    static let skipBackwardButton = "skipBackwardButton"
    static let speedButton = "speedButton"
    static let sleepTimerButton = "sleepTimerButton"
    static let progressSlider = "progressSlider"

    /// Library
    static let audiobookCard = "audiobookCard"
    static let searchField = "searchField"
    static let sortOrderButton = "sortOrderButton"
    static let viewLayoutToggle = "viewLayoutToggle"

    /// Add Audiobook
    static let importFromFilesButton = "importFromFilesButton"
    static let importFromURLButton = "importFromURLButton"
    static let manualEntryButton = "manualEntryButton"
}