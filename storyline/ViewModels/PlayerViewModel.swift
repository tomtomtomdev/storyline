import Foundation
import SwiftData
import Combine
import UIKit

/// Manages the player UI state and interacts with PlaybackManager
@MainActor
@Observable
final class PlayerViewModel {
    // MARK: - Properties

    /// The playback manager instance
    private let playbackManager: PlaybackManager

    /// Currently loaded audiobook
    var currentAudiobook: Audiobook?

    /// Current playback state
    var playbackState: PlaybackState = .stopped

    /// Current playback time in seconds
    var currentTime: TimeInterval = 0

    /// Total duration in seconds
    var duration: TimeInterval = 0

    /// Current playback speed
    var playbackSpeed: Float = PlaybackConstants.defaultPlaybackSpeed

    /// Buffering state
    var isBuffering: Bool = false

    /// Sleep timer remaining time in seconds
    var sleepTimerRemainingTime: TimeInterval?

    /// Whether sleep timer is active
    var isSleepTimerActive: Bool = false

    /// Model context for saving data
    private let modelContext: ModelContext?

    // MARK: - Computed Properties

    /// Playback progress as a value between 0 and 1
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    /// Formatted current time string
    var currentTimeString: String {
        currentTime.formatAsDuration()
    }

    /// Formatted duration string
    var durationString: String {
        duration.formatAsDuration()
    }

    /// Formatted remaining time string
    var remainingTimeString: String {
        (duration - currentTime).formatAsRemainingTime()
    }

    /// Formatted progress percentage
    var progressPercentage: String {
        String(format: "%.0f%%", progress * 100)
    }

    /// Whether an audiobook is currently loaded
    var hasAudiobook: Bool {
        currentAudiobook != nil
    }

    /// Current chapter information (if available)
    var currentChapter: (title: String, number: Int)? {
        // TODO: Implement chapter tracking
        nil
    }

    // MARK: - Initialization

    init(playbackManager: PlaybackManager, modelContext: ModelContext? = nil) {
        self.playbackManager = playbackManager
        self.modelContext = modelContext

        // Start observing playback manager updates
        Task {
            await observePlaybackManager()
        }
    }

    // MARK: - Player Controls

    /// Loads an audiobook for playback
    /// - Parameter audiobook: The audiobook to load
    func loadAudiobook(_ audiobook: Audiobook) {
        Task {
            currentAudiobook = audiobook
            await playbackManager.loadAudiobook(audiobook)
            await updateFromPlaybackManager()

            // Save last played date
            audiobook.lastPlayedDate = Date()
            try? modelContext?.save()
        }
    }

    /// Toggles between play and pause
    func togglePlayPause() {
        Task {
            await playbackManager.togglePlayPause()
            await updateFromPlaybackManager()
        }
    }

    /// Starts playback
    func play() {
        Task {
            await playbackManager.play()
            await updateFromPlaybackManager()
        }
    }

    /// Pauses playback
    func pause() {
        Task {
            await playbackManager.pause()
            await updateFromPlaybackManager()
        }
    }

    /// Stops playback
    func stop() {
        Task {
            await playbackManager.stop()
            await updateFromPlaybackManager()
        }
    }

    /// Skips forward by the default interval
    func skipForward() {
        Task {
            await playbackManager.skipForward()
            await updateFromPlaybackManager()

            // Add haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    /// Skips backward by the default interval
    func skipBackward() {
        Task {
            await playbackManager.skipBackward()
            await updateFromPlaybackManager()

            // Add haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    /// Seeks to a specific time
    /// - Parameter time: Time in seconds
    func seekToTime(_ time: TimeInterval) {
        Task {
            await playbackManager.seekToTime(time)
            await updateFromPlaybackManager()
        }
    }

    /// Sets the playback speed
    /// - Parameter speed: The new playback speed
    func setPlaybackSpeed(_ speed: Float) {
        Task {
            playbackSpeed = speed
            await playbackManager.setPlaybackSpeed(speed)
            await updateFromPlaybackManager()

            // Add haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    /// Sets the sleep timer
    /// - Parameter minutes: Number of minutes until sleep, or -1 for end of chapter
    func setSleepTimer(minutes: Int) {
        Task {
            isSleepTimerActive = true
            await playbackManager.setSleepTimer(minutes: minutes)
            await updateSleepTimerStatus()
        }
    }

    /// Cancels the sleep timer
    func cancelSleepTimer() {
        Task {
            isSleepTimerActive = false
            sleepTimerRemainingTime = nil
            await playbackManager.cancelSleepTimer()

            // Add haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }

    /// Restarts the current audiobook from the beginning
    func restartAudiobook() {
        Task {
            await seekToTime(0)

            // Add haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }

    /// Marks the current audiobook as finished
    func markAsFinished() {
        guard let audiobook = currentAudiobook else { return }

        audiobook.markAsFinished()
        try? modelContext?.save()

        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    /// Adds or removes the current audiobook from favorites
    func toggleFavorite() {
        guard let audiobook = currentAudiobook else { return }

        if audiobook.hasTag("Favorites") {
            audiobook.removeTag("Favorites")
        } else {
            audiobook.addTag("Favorites")
        }

        try? modelContext?.save()

        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    // MARK: - Private Methods

    /// Observes playback manager updates
    private func observePlaybackManager() {
        Task {
            // This would be implemented with proper async observation
            // For now, we'll poll periodically
            while !Task.isCancelled {
                await updateFromPlaybackManager()
                await updateSleepTimerStatus()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }

    /// Updates state from playback manager
    private func updateFromPlaybackManager() async {
        playbackState = await playbackManager.playbackState
        currentTime = await playbackManager.currentTime
        duration = await playbackManager.duration
        playbackSpeed = await playbackManager.playbackRate
        isBuffering = await playbackManager.isBuffering
    }

    /// Updates sleep timer status
    private func updateSleepTimerStatus() async {
        if let remaining = await playbackManager.getSleepTimerRemainingTime() {
            sleepTimerRemainingTime = remaining
            isSleepTimerActive = true
        } else {
            sleepTimerRemainingTime = nil
            isSleepTimerActive = false
        }
    }

    /// Formats sleep timer remaining time
    /// - Parameter seconds: Remaining time in seconds
    /// - Returns: Formatted string
    func formatSleepTimerTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(ceil(seconds / 60))
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Playback Speed Convenience

extension PlayerViewModel {
    /// Gets the display string for the current playback speed
    var playbackSpeedDisplay: String {
        String(format: "%.1fx", playbackSpeed)
    }

    /// Gets the next playback speed in the cycle
    var nextPlaybackSpeed: Float {
        guard let currentIndex = PlaybackConstants.playbackSpeeds.firstIndex(of: playbackSpeed) else {
            return PlaybackConstants.defaultPlaybackSpeed
        }
        let nextIndex = (currentIndex + 1) % PlaybackConstants.playbackSpeeds.count
        return PlaybackConstants.playbackSpeeds[nextIndex]
    }

    /// Cycles to the next playback speed
    func cyclePlaybackSpeed() {
        setPlaybackSpeed(nextPlaybackSpeed)
    }
}

// MARK: - Chapter Support (Future Enhancement)

extension PlayerViewModel {
    /// Gets all chapters for the current audiobook
    var chapters: [Chapter] {
        // TODO: Implement chapter retrieval
        []
    }

    /// Navigates to the next chapter
    func nextChapter() {
        // TODO: Implement chapter navigation
    }

    /// Navigates to the previous chapter
    func previousChapter() {
        // TODO: Implement chapter navigation
    }

    /// Jumps to a specific chapter
    /// - Parameter chapter: The chapter to jump to
    func goToChapter(_ chapter: Chapter) {
        Task {
            await seekToTime(chapter.startTime)
        }
    }
}