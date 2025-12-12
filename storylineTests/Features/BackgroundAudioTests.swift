import Testing
import AVFoundation
import MediaPlayer
@testable import storyline

@Suite("Background Audio Tests")
struct BackgroundAudioTests {
    @Test("Audio session configuration")
    func testAudioSessionConfiguration() async throws {
        let playbackManager = PlaybackManager()

        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Audiobook",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Check if audio session is configured
        let audioSession = AVAudioSession.sharedInstance()
        #expect(audioSession.category == .playback)
        #expect(audioSession.mode == .spokenAudio)

        // Clean up
        Task {
            await playbackManager.stop()
        }
    }

    @Test("Now playing info updates")
    func testNowPlayingInfoUpdates() async throws {
        let playbackManager = PlaybackManager()

        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            narrator: "Test Narrator",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Start playback
        await playbackManager.play()

        // Wait a bit for now playing info to update
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Check now playing info
        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        #expect(nowPlayingInfo?[MPMediaItemPropertyTitle] as? String == "Test Book")
        #expect(nowPlayingInfo?[MPMediaItemPropertyArtist] as? String == "Test Author")
        #expect(nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as? String == "Narrated by Test Narrator")

        // Clean up
        Task {
            await playbackManager.stop()
        }
    }

    @Test("Remote command center setup")
    func testRemoteCommandCenterSetup() async throws {
        let playbackManager = PlaybackManager()
        let commandCenter = MPRemoteCommandCenter.shared()

        // Check if commands are enabled
        #expect(commandCenter.playCommand.isEnabled == true)
        #expect(commandCenter.pauseCommand.isEnabled == true)
        #expect(commandCenter.stopCommand.isEnabled == true)
        #expect(commandCenter.togglePlayPauseCommand.isEnabled == true)
        #expect(commandCenter.skipForwardCommand.isEnabled == true)
        #expect(commandCenter.skipBackwardCommand.isEnabled == true)
        #expect(commandCenter.changePlaybackPositionCommand.isEnabled == true)
        #expect(commandCenter.changePlaybackRateCommand.isEnabled == true)
    }

    @Test("Playback state in control center")
    func testPlaybackStateInControlCenter() async throws {
        let playbackManager = PlaybackManager()
        let playbackInfoCenter = MPNowPlayingInfoCenter.default()

        // Load an audiobook
        let audioURL = AudioFileManager.createSampleAudioFile()!
        let audiobook = Audiobook(
            title: "Test Book",
            author: "Test Author",
            duration: 30,
            audioFileURL: audioURL
        )
        await playbackManager.loadAudiobook(audiobook)

        // Test playing state
        await playbackManager.play()
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        // Note: playbackInfoCenter.playbackState is not directly accessible in tests
        // But we can verify it doesn't crash

        // Test paused state
        await playbackManager.pause()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Test stopped state
        await playbackManager.stop()

        // Clean up
    }
}

// MARK: - Device Testing Notes

/*
These tests verify background audio functionality, but full testing requires:
1. Running on a physical device (simulator has limitations)
2. Testing scenarios to verify:
   - Lock screen controls appear
   - Control Center integration works
   - Background playback continues when app is backgrounded
   - Audio interruptions are handled properly
   - Headphone controls work correctly
   - AirPlay streaming works
   - Bluetooth audio device support

To test on device:
1. Build and run on iPhone/iPad
2. Play an audiobook
3. Lock device - verify controls appear on lock screen
4. Open Control Center - verify media controls work
5. Background app - verify playback continues
6. Receive phone call - verify playback pauses and resumes
7. Unplug headphones - verify playback pauses
8. Use headphone buttons - verify they control playback
*/