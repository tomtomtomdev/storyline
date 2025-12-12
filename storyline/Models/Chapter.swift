import Foundation
import SwiftData

@Model
final class Chapter {
    /// Unique identifier for the chapter
    var id: UUID

    /// Title of the chapter
    var title: String

    /// Start time of the chapter in seconds from the beginning of the audiobook
    var startTime: TimeInterval

    /// Duration of the chapter in seconds
    var duration: TimeInterval

    /// Chapter number in the audiobook
    var chapterNumber: Int

    /// The audiobook this chapter belongs to
    var audiobook: Audiobook?

    /// Date of creation
    var createdAt: Date

    init(
        title: String,
        startTime: TimeInterval,
        duration: TimeInterval,
        chapterNumber: Int,
        audiobook: Audiobook? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.chapterNumber = chapterNumber
        self.audiobook = audiobook
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// End time of the chapter in seconds
    var endTime: TimeInterval {
        startTime + duration
    }

    /// Formatted duration string
    var durationFormatted: String {
        duration.formatAsDuration()
    }

    /// Formatted start time string
    var startTimeFormatted: String {
        startTime.formatAsDuration()
    }

    /// Display title with chapter number
    var displayTitle: String {
        "Chapter \(chapterNumber): \(title)"
    }

    /// Checks if a given time is within this chapter
    /// - Parameter time: Time in seconds
    /// - Returns: True if time is within the chapter
    func containsTime(_ time: TimeInterval) -> Bool {
        time >= startTime && time <= endTime
    }
}

// MARK: - Preview Support

extension Chapter {
    /// Creates sample chapters for previews
    static var previews: [Chapter] {
        let audiobook = Audiobook.preview

        return [
            Chapter(
                title: "Introduction",
                startTime: 0,
                duration: 300,
                chapterNumber: 1,
                audiobook: audiobook
            ),
            Chapter(
                title: "The Journey Begins",
                startTime: 300,
                duration: 1800,
                chapterNumber: 2,
                audiobook: audiobook
            ),
            Chapter(
                title: "Discovery",
                startTime: 2100,
                duration: 1500,
                chapterNumber: 3,
                audiobook: audiobook
            ),
            Chapter(
                title: "Conclusion",
                startTime: 3600,
                duration: 600,
                chapterNumber: 4,
                audiobook: audiobook
            )
        ]
    }
}