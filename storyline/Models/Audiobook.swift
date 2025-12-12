import Foundation
import SwiftData

@Model
final class Audiobook {
    /// Unique identifier for the audiobook
    var id: UUID

    /// Title of the audiobook
    var title: String

    /// Author of the audiobook
    var author: String

    /// Narrator of the audiobook (optional)
    var narrator: String?

    /// Total duration in seconds
    var duration: TimeInterval

    /// URL to artwork image (optional)
    var artworkURL: URL?

    /// Cached cover image data
    var artworkData: Data?

    /// Local file path to audio file
    var audioFileURL: URL

    /// Date when audiobook was added to library
    var dateAdded: Date

    /// Date when audiobook was last played
    var lastPlayedDate: Date?

    /// Current playback position in seconds
    var currentPosition: TimeInterval

    /// Flag indicating if audiobook is finished
    var isFinished: Bool

    /// Tags for categorization (e.g., "Fiction", "Non-fiction", "Favorites")
    var tags: [String]

    /// Date of creation (set automatically)
    var createdAt: Date

    init(
        title: String,
        author: String,
        narrator: String? = nil,
        duration: TimeInterval,
        audioFileURL: URL,
        artworkURL: URL? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.narrator = narrator
        self.duration = duration
        self.audioFileURL = audioFileURL
        self.artworkURL = artworkURL
        self.dateAdded = Date()
        self.currentPosition = 0
        self.isFinished = false
        self.tags = tags
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// Progress as a percentage (0.0 to 1.0)
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentPosition / duration, 1.0)
    }

    /// Remaining time in seconds
    var remainingTime: TimeInterval {
        max(duration - currentPosition, 0)
    }

    /// Formatted progress as percentage string
    var progressPercentage: String {
        String(format: "%.0f%%", progress * 100)
    }

    /// Formatted duration string (e.g., "5:23:45")
    var durationFormatted: String {
        duration.formatAsDuration()
    }

    /// Formatted current position string
    var currentPositionFormatted: String {
        currentPosition.formatAsDuration()
    }

    /// Formatted remaining time string
    var remainingTimeFormatted: String {
        remainingTime.formatAsDuration()
    }

    /// Display name with title and author
    var displayName: String {
        "\(title) - \(author)"
    }

    /// Checks if audiobook has artwork
    var hasArtwork: Bool {
        artworkData != nil || artworkURL != nil
    }

    // MARK: - Methods

    /// Updates the current playback position
    /// - Parameter position: New position in seconds
    func updatePosition(_ position: TimeInterval) {
        currentPosition = max(0, min(position, duration))
        lastPlayedDate = Date()

        // Mark as finished if near the end (within 10 seconds)
        if !isFinished && currentPosition >= duration - 10 {
            isFinished = true
        }
    }

    /// Resets the audiobook to the beginning
    func reset() {
        currentPosition = 0
        isFinished = false
    }

    /// Marks the audiobook as finished
    func markAsFinished() {
        isFinished = true
        currentPosition = duration
    }

    /// Adds a tag to the audiobook
    /// - Parameter tag: Tag to add
    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }

    /// Removes a tag from the audiobook
    /// - Parameter tag: Tag to remove
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    /// Checks if audiobook has a specific tag
    /// - Parameter tag: Tag to check
    /// - Returns: True if audiobook has the tag
    func hasTag(_ tag: String) -> Bool {
        tags.contains(tag)
    }
}

// MARK: - Preview Support

extension Audiobook {
    /// Creates a sample audiobook for previews
    static var preview: Audiobook {
        Audiobook(
            title: "The Great Adventure",
            author: "John Smith",
            narrator: "Jane Doe",
            duration: 3600 * 5, // 5 hours
            audioFileURL: URL(fileURLWithPath: "/sample/path/audiobook.m4a"),
            tags: ["Fiction", "Adventure"]
        )
    }

    /// Creates multiple sample audiobooks for previews
    static var previews: [Audiobook] {
        [
            Audiobook(
                title: "Mystery of the Lost City",
                author: "Sarah Johnson",
                narrator: "Mike Williams",
                duration: 3600 * 8,
                audioFileURL: URL(fileURLWithPath: "/sample/path/mystery.m4a"),
                tags: ["Mystery", "Fiction"]
            ),
            Audiobook(
                title: "Learning Swift Programming",
                author: "Tech Education",
                narrator: "Alex Brown",
                duration: 3600 * 3,
                audioFileURL: URL(fileURLWithPath: "/sample/path/swift.m4a"),
                tags: ["Education", "Programming"]
            ),
            Audiobook(
                title: "History of Ancient Rome",
                author: "Dr. Robert Davis",
                narrator: "Emma Wilson",
                duration: 3600 * 12,
                audioFileURL: URL(fileURLWithPath: "/sample/path/rome.m4a"),
                tags: ["History", "Non-fiction"]
            )
        ]
    }
}