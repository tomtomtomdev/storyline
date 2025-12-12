import Testing
import Foundation
@testable import storyline
import SwiftData

@Suite("Audiobook Model Tests")
struct AudiobookTests {
    @Test("Progress calculation")
    func testProgressCalculation() throws {
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: 3600, // 1 hour
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Test initial progress
        #expect(audiobook.progress == 0.0)

        // Test half progress
        audiobook.updatePosition(1800) // 30 minutes
        #expect(audiobook.progress == 0.5)

        // Test full progress
        audiobook.updatePosition(3600) // 1 hour
        #expect(audiobook.progress == 1.0)

        // Test progress doesn't exceed 1.0
        audiobook.updatePosition(4000) // Beyond duration
        #expect(audiobook.progress == 1.0)
    }

    @Test("Remaining time calculation")
    func testRemainingTimeCalculation() throws {
        let duration: TimeInterval = 3600 // 1 hour
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: duration,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Test initial remaining time
        #expect(audiobook.remainingTime == duration)

        // Test remaining time after 30 minutes
        audiobook.updatePosition(1800)
        #expect(audiobook.remainingTime == 1800)

        // Test remaining time near end
        audiobook.updatePosition(3590)
        #expect(audiobook.remainingTime == 10)

        // Test remaining time at end
        audiobook.updatePosition(3600)
        #expect(audiobook.remainingTime == 0)

        // Test remaining time doesn't go negative
        audiobook.updatePosition(3700)
        #expect(audiobook.remainingTime == 0)
    }

    @Test("Position updates")
    func testPositionUpdates() throws {
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: 3600,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Test position update
        audiobook.updatePosition(1000)
        #expect(audiobook.currentPosition == 1000)
        #expect(audiobook.lastPlayedDate != nil)

        // Test position below minimum
        audiobook.updatePosition(-100)
        #expect(audiobook.currentPosition == 0)

        // Test position above maximum
        audiobook.updatePosition(4000)
        #expect(audiobook.currentPosition == 3600)
    }

    @Test("Finished state")
    func testFinishedState() throws {
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: 3600,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Test initial state
        #expect(audiobook.isFinished == false)

        // Test near end - should mark as finished
        audiobook.updatePosition(3595) // 5 seconds before end
        #expect(audiobook.isFinished == true)

        // Test manual mark as finished
        audiobook.reset()
        #expect(audiobook.isFinished == false)
        audiobook.markAsFinished()
        #expect(audiobook.isFinished == true)
        #expect(audiobook.currentPosition == audiobook.duration)
    }

    @Test("Reset functionality")
    func testReset() throws {
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: 3600,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Update position and mark as finished
        audiobook.updatePosition(1800)
        audiobook.markAsFinished()

        // Reset
        audiobook.reset()

        // Verify reset
        #expect(audiobook.currentPosition == 0)
        #expect(audiobook.isFinished == false)
    }

    @Test("Tag management")
    func testTagManagement() throws {
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: 3600,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Test initial tags
        #expect(audiobook.tags.isEmpty)

        // Test adding tags
        audiobook.addTag("Fiction")
        audiobook.addTag("Adventure")
        #expect(audiobook.tags.count == 2)
        #expect(audiobook.hasTag("Fiction"))
        #expect(audiobook.hasTag("Adventure"))

        // Test adding duplicate tag
        audiobook.addTag("Fiction")
        #expect(audiobook.tags.count == 2)

        // Test removing tags
        audiobook.removeTag("Fiction")
        #expect(audiobook.tags.count == 1)
        #expect(!audiobook.hasTag("Fiction"))
        #expect(audiobook.hasTag("Adventure"))

        // Test removing non-existent tag
        audiobook.removeTag("Non-existent")
        #expect(audiobook.tags.count == 1)
    }

    @Test("Computed properties")
    func testComputedProperties() throws {
        let audiobook = Audiobook(
            title: "The Great Adventure",
            author: "John Smith",
            narrator: "Jane Doe",
            duration: 3665, // 1:01:05
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )

        // Test display name
        #expect(audiobook.displayName == "The Great Adventure - John Smith")

        // Test progress percentage
        audiobook.updatePosition(1832.5) // Halfway
        #expect(audiobook.progressPercentage == "50%")

        // Test formatted strings
        #expect(audiobook.durationFormatted == "1:01:05")
        audiobook.updatePosition(125) // 2:05
        #expect(audiobook.currentPositionFormatted == "2:05")
        #expect(audiobook.remainingTimeFormatted == "-58:59")

        // Test has artwork
        #expect(audiobook.hasArtwork == false)

        audiobook.artworkURL = URL(string: "https://example.com/artwork.jpg")
        #expect(audiobook.hasArtwork == true)

        audiobook.artworkURL = nil
        audiobook.artworkData = Data()
        #expect(audiobook.hasArtwork == true)
    }

    @Test("Edge cases")
    func testEdgeCases() throws {
        // Test zero duration
        let zeroDurationBook = Audiobook(
            title: "Zero Duration",
            author: "Test",
            duration: 0,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )
        #expect(zeroDurationBook.progress == 0.0)

        // Test very short duration
        let shortBook = Audiobook(
            title: "Short Book",
            author: "Test",
            duration: 1,
            audioFileURL: URL(fileURLWithPath: "/test/path")
        )
        shortBook.updatePosition(0.5)
        #expect(shortBook.progress > 0.0 && shortBook.progress <= 1.0)

        // Test nil optional values
        let bookWithNilOptions = Audiobook(
            title: "Minimal Book",
            author: "Test",
            duration: 100,
            audioFileURL: URL(fileURLWithPath: "/test/path"),
            narrator: nil,
            artworkURL: nil
        )
        #expect(bookWithNilOptions.narrator == nil)
        #expect(bookWithNilOptions.artworkURL == nil)
    }

    @Test("Initialization")
    func testInitialization() throws {
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            narrator: "Test Narrator",
            duration: 3600,
            audioFileURL: URL(fileURLWithPath: "/test/path"),
            tags: ["Fiction", "Adventure"]
        )

        #expect(audiobook.title == "Test Book")
        #expect(audiobook.author == "Test Author")
        #expect(audiobook.narrator == "Test Narrator")
        #expect(audiobook.duration == 3600)
        #expect(audiobook.audioFileURL.lastPathComponent == "path")
        #expect(audiobook.tags == ["Fiction", "Adventure"])
        #expect(audiobook.currentPosition == 0)
        #expect(audiobook.isFinished == false)
        #expect(audiobook.dateAdded != nil)
        #expect(audiobook.createdAt != nil)
        #expect(audiobook.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
}