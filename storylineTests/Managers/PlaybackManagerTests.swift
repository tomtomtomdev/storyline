import Testing
import Foundation
import AVFoundation
@testable import storyline

@Suite("PlaybackManager Tests")
struct PlaybackManagerTests {
    var playbackManager: PlaybackManager

    init() {
        self.playbackManager = PlaybackManager()
    }

    deinit {
        Task {
            await playbackManager.stop()
        }
    }

    @Test("Initial state")
    func testInitialState() async throws {
        let state = await playbackManager.playbackState
        #expect(state == .stopped)

        let rate = await playbackManager.playbackRate
        #expect(rate == PlaybackConstants.defaultPlaybackSpeed)

        let currentTime = await playbackManager.currentTime
        #expect(currentTime == 0)

        let duration = await playbackManager.duration
        #expect(duration == 0)

        let currentBook = await playbackManager.currentAudiobook
        #expect(currentBook == nil)
    }

    @Test("Load audiobook")
    func testLoadAudiobook() async throws {
        // Create a test audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )

        // Load the audiobook
        await playbackManager.loadAudiobook(audiobook)

        // Check if loaded correctly
        let currentBook = await playbackManager.currentAudiobook
        #expect(currentBook?.title == audiobook.title)

        let duration = await playbackManager.duration
        #expect(duration > 0)
    }

    @Test("Play and pause")
    func testPlayPause() async throws {
        // Load an audiobook first
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Test play
        await playbackManager.play()
        let playingState = await playbackManager.playbackState
        #expect(playingState == .playing)

        // Test pause
        await playbackManager.pause()
        let pausedState = await playbackManager.playbackState
        #expect(pausedState == .paused)
    }

    @Test("Toggle play/pause")
    func testTogglePlayPause() async throws {
        // Load an audiobook first
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Initial state is stopped, toggle should play
        await playbackManager.togglePlayPause()
        let playingState = await playbackManager.playbackState
        #expect(playingState == .playing)

        // Toggle again should pause
        await playbackManager.togglePlayPause()
        let pausedState = await playbackManager.playbackState
        #expect(pausedState == .paused)
    }

    @Test("Stop playback")
    func testStop() async throws {
        // Load and play an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)
        await playbackManager.play()

        // Stop playback
        await playbackManager.stop()
        let stoppedState = await playbackManager.playbackState
        #expect(stoppedState == .stopped)

        // Time should reset to 0
        let currentTime = await playbackManager.currentTime
        #expect(currentTime == 0)
    }

    @Test("Seek to time")
    func testSeekToTime() async throws {
        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Seek to 10 seconds
        await playbackManager.seekToTime(10)
        let currentTime = await playbackManager.currentTime
        #expect(abs(currentTime - 10) < 0.1) // Allow small tolerance

        // Test seeking beyond duration
        let duration = await playbackManager.duration
        await playbackManager.seekToTime(duration + 100)
        let clampedTime = await playbackManager.currentTime
        #expect(clampedTime <= duration)

        // Test seeking to negative time
        await playbackManager.seekToTime(-10)
        let negativeTime = await playbackManager.currentTime
        #expect(negativeTime >= 0)
    }

    @Test("Skip forward and backward")
    func testSkipForwardBackward() async throws {
        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 60,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Start at 20 seconds
        await playbackManager.seekToTime(20)

        // Skip forward
        await playbackManager.skipForward()
        let timeAfterForward = await playbackManager.currentTime
        #expect(abs(timeAfterForward - (20 + PlaybackConstants.defaultSkipInterval)) < 0.1)

        // Skip backward
        await playbackManager.skipBackward()
        let timeAfterBackward = await playbackManager.currentTime
        #expect(abs(timeAfterBackward - 20) < 0.1)
    }

    @Test("Change playback speed")
    func testChangePlaybackSpeed() async throws {
        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Test setting different speeds
        for speed in PlaybackConstants.playbackSpeeds {
            await playbackManager.setPlaybackSpeed(speed)
            let currentSpeed = await playbackManager.playbackRate
            #expect(currentSpeed == speed)
        }
    }

    @Test("Sleep timer functionality")
    func testSleepTimer() async throws {
        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Set sleep timer for 1 minute
        await playbackManager.setSleepTimer(1)

        // Check if timer is active
        let remainingTime = await playbackManager.getSleepTimerRemainingTime()
        #expect(remainingTime != nil)
        #expect(remainingTime! > 0 && remainingTime! <= 60)

        // Cancel sleep timer
        await playbackManager.cancelSleepTimer()
        let cancelledTime = await playbackManager.getSleepTimerRemainingTime()
        #expect(cancelledTime == nil)

        // Test end of chapter timer
        await playbackManager.setSleepTimer(PlaybackConstants.endOfChapterOption)
        // This is harder to test without chapters, but we can at least verify it doesn't crash
    }

    @Test("Edge cases")
    func testEdgeCases() async throws {
        // Test play without loaded audiobook
        await playbackManager.play()
        let stateWithoutBook = await playbackManager.playbackState
        #expect(stateWithoutBook != .playing)

        // Test pause without loaded audiobook
        await playbackManager.pause()
        let pausedState = await playbackManager.playbackState
        #expect(pausedState == .stopped || pausedState == .paused)

        // Test speed without loaded audiobook
        await playbackManager.setPlaybackSpeed(2.0)
        let speedWithoutBook = await playbackManager.playbackRate
        #expect(speedWithoutBook == 2.0) // Should still update the rate

        // Test seek without loaded audiobook
        await playbackManager.seekToTime(10)
        let timeWithoutBook = await playbackManager.currentTime
        #expect(timeWithoutBook == 0) // Should remain 0
    }

    @Test("Progress saving")
    func testProgressSaving() async throws {
        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Seek to a position
        await playbackManager.seekToTime(15)

        // The position should be saved to the audiobook
        #expect(audiobook.currentPosition == 15)
        #expect(audiobook.lastPlayedDate != nil)

        // Pause to ensure position is saved
        await playbackManager.pause()
        #expect(audiobook.currentPosition >= 15) // May have progressed slightly
    }
}

// MARK: - Mock Audio Session Tests

@Suite("PlaybackManager Audio Session Tests")
struct PlaybackManagerAudioSessionTests {
    @Test("Audio session configuration")
    func testAudioSessionConfiguration() async throws {
        let playbackManager = PlaybackManager()

        // The audio session should be configured on initialization
        let audioSession = AVAudioSession.sharedInstance()

        // Verify category (this might be different based on system state)
        #expect(audioSession.category == .playback)

        // Clean up
        Task {
            await playbackManager.stop()
        }
    }
}