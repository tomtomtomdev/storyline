import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Manages audio playback with thread-safe operations using Swift actors
actor PlaybackManager {
    // MARK: - Properties

    /// The AVPlayer instance for audio playback
    private let player: AVPlayer

    /// Current playback state
    private(set) var playbackState: PlaybackState = .stopped

    /// Current playback rate (speed)
    private(set) var playbackRate: Float = PlaybackConstants.defaultPlaybackSpeed

    /// Current time observer token
    private var timeObserver: Any?

    /// Audio session configuration
    private let audioSession = AVAudioSession.sharedInstance()

    /// Currently loaded audiobook
    private(set) var currentAudiobook: Audiobook?

    /// Sleep timer end time
    private(set) var sleepTimerEndTime: Date?

    /// Sleep timer task
    private var sleepTimerTask: Task<Void, Never>?

    /// Publisher for playback time updates
    @Published private(set) var currentTime: TimeInterval = 0

    /// Publisher for duration
    @Published private(set) var duration: TimeInterval = 0

    /// Publisher for buffering state
    @Published private(set) var isBuffering: Bool = false

    // MARK: - Initialization

    init() {
        self.player = AVPlayer()

        Task {
            await configureAudioSession()
            await setupPlayerObservers()
        }
    }

    deinit {
        Task {
            await removeTimeObserver()
            await invalidateSleepTimer()
        }
    }

    // MARK: - Playback Control

    /// Loads an audiobook for playback
    /// - Parameter audiobook: The audiobook to load
    func loadAudiobook(_ audiobook: Audiobook) async {
        // Remove time observer for previous audiobook
        await removeTimeObserver()

        // Create player item
        let playerItem = AVPlayerItem(url: audiobook.audioFileURL)

        // Load the new item
        await MainActor.run {
            player.replaceCurrentItem(with: playerItem)
        }

        currentAudiobook = audiobook

        // Update duration
        if let duration = player.currentItem?.asset.duration.seconds {
            self.duration = duration.isFinite ? duration : audiobook.duration
        } else {
            self.duration = audiobook.duration
        }

        // Restore position
        if audiobook.currentPosition > 0 {
            await seekToTime(audiobook.currentPosition)
        }

        // Setup time observer for new item
        await setupTimeObserver()

        // Update now playing info
        await updateNowPlayingInfo()
    }

    /// Starts or resumes playback
    func play() async {
        guard player.currentItem != nil else {
            print("No audiobook loaded")
            return
        }

        player.rate = playbackRate
        playbackState = .playing

        // Update now playing info
        await updateNowPlayingInfo()

        // Configure audio session for playback
        do {
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }

    /// Pauses playback
    func pause() async {
        player.pause()
        playbackState = .paused

        // Save current position
        if let audiobook = currentAudiobook {
            audiobook.updatePosition(currentTime)
        }

        // Update now playing info
        await updateNowPlayingInfo()
    }

    /// Stops playback and resets position
    func stop() async {
        player.pause()
        playbackState = .stopped

        // Save position
        if let audiobook = currentAudiobook {
            audiobook.updatePosition(currentTime)
        }

        // Reset to beginning
        await seekToTime(0)

        // Deactivate audio session
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    /// Toggles between play and pause
    func togglePlayPause() async {
        switch playbackState {
        case .playing:
            await pause()
        case .paused, .stopped, .buffering:
            await play()
        }
    }

    /// Seeks to a specific time
    /// - Parameter time: Time in seconds
    func seekToTime(_ time: TimeInterval) async {
        let clampedTime = max(0, min(time, duration))

        await MainActor.run {
            let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        currentTime = clampedTime

        // Update audiobook position
        if let audiobook = currentAudiobook {
            audiobook.updatePosition(clampedTime)
        }
    }

    /// Skips forward by the default interval
    func skipForward() async {
        await seekToTime(currentTime + PlaybackConstants.defaultSkipInterval)
    }

    /// Skips backward by the default interval
    func skipBackward() async {
        await seekToTime(currentTime - PlaybackConstants.defaultSkipInterval)
    }

    /// Sets the playback speed
    /// - Parameter speed: The new playback speed
    func setPlaybackSpeed(_ speed: Float) async {
        playbackRate = speed

        // Apply speed if currently playing
        if playbackState == .playing {
            player.rate = speed
        }
    }

    /// Sets the sleep timer
    /// - Parameter minutes: Number of minutes until sleep, or -1 for end of chapter
    func setSleepTimer(minutes: Int) async {
        await invalidateSleepTimer()

        if minutes == SleepTimerConstants.endOfChapterOption {
            // End of chapter - handle when chapter changes
            sleepTimerEndTime = nil
        } else if minutes > 0 {
            // Set timer for specified minutes
            sleepTimerEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))

            sleepTimerTask = Task {
                while !Task.isCancelled {
                    if let endTime = sleepTimerEndTime {
                        if Date() >= endTime {
                            await pause()
                            await invalidateSleepTimer()
                            // Notify user that sleep timer triggered
                            await NotificationCenter.default.post(
                                name: .sleepTimerDidEnd,
                                object: nil
                            )
                            break
                        }
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
                }
            }
        }
    }

    /// Cancels the sleep timer
    func cancelSleepTimer() async {
        await invalidateSleepTimer()
    }

    /// Gets the current sleep timer remaining time in seconds
    /// - Returns: Remaining time in seconds, or nil if no timer is set
    func getSleepTimerRemainingTime() async -> TimeInterval? {
        guard let endTime = sleepTimerEndTime else { return nil }
        return max(0, endTime.timeIntervalSinceNow)
    }

    // MARK: - Audio Session Configuration

    /// Configures the audio session for background playback
    private func configureAudioSession() async {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [
                    .allowBluetooth,
                    .allowAirPlay,
                    .allowBluetoothA2DP,
                    .interruptSpokenAudioAndMixWithOthers
                ]
            )
            try audioSession.setActive(true)

            // Register for audio interruption notifications
            await registerForAudioInterruptions()
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    /// Registers for audio interruption notifications
    private func registerForAudioInterruptions() async {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleAudioInterruption(notification)
            }
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleRouteChange(notification)
            }
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereLostNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleMediaServicesLost(notification)
            }
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleMediaServicesReset(notification)
            }
        }
    }

    /// Handles audio interruptions
    private func handleAudioInterruption(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let interruptionTypeRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRaw) else {
            return
        }

        let wasPlaying = playbackState == .playing

        switch interruptionType {
        case .began:
            // Audio interruption began - pause playback
            await pause()
            print("Audio interruption began - playback paused")

        case .ended:
            // Audio interruption ended
            if let interruptionOptionRaw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let interruptionOption = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionRaw)
                if interruptionOption.contains(.shouldResume) && wasPlaying {
                    // Resume playback if option allows and was playing before interruption
                    await play()
                    print("Audio interruption ended - playback resumed")
                } else {
                    print("Audio interruption ended - playback not resumed")
                }
            }

        @unknown default:
            break
        }
    }

    /// Handles route changes (e.g., headphones unplugged)
    private func handleRouteChange(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let routeChangeReasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let routeChangeReason = AVAudioSession.RouteChangeReason(rawValue: routeChangeReasonRaw) else {
            return
        }

        switch routeChangeReason {
        case .oldDeviceUnavailable:
            // Headphones unplugged - pause playback
            await pause()
            print("Route changed: Device unavailable - playback paused")

        case .newDeviceAvailable:
            // Headphones plugged in
            print("Route changed: New device available")

        case .categoryChange:
            print("Route changed: Category changed")

        case .override:
            print("Route changed: Override")

        case .wakeFromSleep:
            print("Route changed: Wake from sleep")

        case .noSuitableRouteForCategory:
            print("Route changed: No suitable route")

        case .routeConfigurationChange:
            print("Route changed: Configuration change")

        @unknown default:
            print("Route changed: Unknown reason")
        }
    }

    /// Handles media services loss
    private func handleMediaServicesLost(_ notification: Notification) async {
        print("Media services were lost")
        await stop()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Handles media services reset
    private func handleMediaServicesReset(_ notification: Notification) async {
        print("Media services were reset")
        // Reconfigure audio session
        await configureAudioSession()
        // Update now playing info if needed
        if currentAudiobook != nil {
            await updateNowPlayingInfo()
        }
    }

    // MARK: - Player Observers

    /// Sets up player observers for time updates and state changes
    private func setupPlayerObservers() async {
        // Observe time changes
        await setupTimeObserver()

        // Observe player item changes
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handlePlaybackDidFinish()
            }
        }

        // Setup remote command center
        await setupRemoteCommandCenter()
    }

    /// Sets up time observer for tracking playback progress
    private func setupTimeObserver() async {
        await removeTimeObserver()

        let interval = CMTime(
            seconds: PlaybackConstants.timeObserverInterval,
            preferredTimescale: 600
        )

        let observer = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                Task {
                    await self.updateCurrentTime(time.seconds)

                    // Auto-save progress periodically
                    if Int(time.seconds) % Int(PlaybackConstants.progressAutoSaveInterval) == 0 {
                        let audiobook = await self.currentAudiobook
                        audiobook?.updatePosition(time.seconds)
                    }
                }
            }
        }

        timeObserver = observer
    }

    /// Updates current time from main actor
    private func updateCurrentTime(_ time: TimeInterval) async {
        currentTime = time
    }

    /// Removes the time observer
    private func removeTimeObserver() async {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    /// Handles playback finishing
    private func handlePlaybackDidFinish() async {
        playbackState = .stopped

        // Mark audiobook as finished
        if let audiobook = currentAudiobook {
            audiobook.markAsFinished()
        }

        // Invalidate sleep timer
        await invalidateSleepTimer()

        // Update now playing info
        await updateNowPlayingInfo()
    }

    /// Invalidates the sleep timer
    private func invalidateSleepTimer() async {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerEndTime = nil
    }

    // MARK: - Now Playing Info

    /// Updates the now playing info in the control center and lock screen
    private func updateNowPlayingInfo() async {
        guard let audiobook = currentAudiobook else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = audiobook.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = audiobook.author
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = audiobook.narrator?.map { "Narrated by \($0)" }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackState == .playing ? playbackRate : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = PlaybackConstants.defaultPlaybackSpeed

        // Add progress information
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = audiobook.progress

        // Add artwork if available
        if let artworkData = audiobook.artworkData,
           let image = UIImage(data: artworkData) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: image.size
            ) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // Update playback state in control center
        await updatePlaybackStateInControlCenter()
    }

    /// Updates the playback state in the Control Center
    private func updatePlaybackStateInControlCenter() async {
        let playbackInfoCenter = MPNowPlayingInfoCenter.default()

        switch playbackState {
        case .playing:
            playbackInfoCenter.playbackState = .playing
        case .paused:
            playbackInfoCenter.playbackState = .paused
        case .stopped:
            playbackInfoCenter.playbackState = .stopped
        case .buffering:
            playbackInfoCenter.playbackState = .interrupted
        }
    }

    // MARK: - Remote Command Center

    /// Sets up remote command center for system controls
    private func setupRemoteCommandCenter() async {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task {
                await self?.play()
            }
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task {
                await self?.pause()
            }
            return .success
        }

        // Stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            Task {
                await self?.stop()
            }
            return .success
        }

        // Toggle Play/Pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task {
                await self?.togglePlayPause()
            }
            return .success
        }

        // Skip forward command
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: PlaybackConstants.defaultSkipInterval)]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            Task {
                await self?.skipForward()
            }
            return .success
        }

        // Skip backward command
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: PlaybackConstants.defaultSkipInterval)]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            Task {
                await self?.skipBackward()
            }
            return .success
        }

        // Next track (for switching audiobooks)
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.addTarget { _ in
            return .commandFailed
        }

        // Previous track (for switching audiobooks)
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.addTarget { _ in
            return .commandFailed
        }

        // Change playback position command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            Task {
                await self?.seekToTime(event.positionTime)
            }
            return .success
        }

        // Change playback rate command
        commandCenter.changePlaybackRateCommand.isEnabled = true
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = PlaybackConstants.playbackSpeeds.map { NSNumber(value: $0) }
        commandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else {
                return .commandFailed
            }

            Task {
                await self?.setPlaybackSpeed(event.playbackRate)
            }
            return .success
        }

        // Enable feedback for headphones
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true
    }
}

// MARK: - Supporting Types

/// Represents the current playback state
enum PlaybackState {
    case stopped
    case playing
    case paused
    case buffering
}

// MARK: - Notifications

extension Notification.Name {
    static let sleepTimerDidEnd = Notification.Name("sleepTimerDidEnd")
}

// MARK: - AVAsset Extension

extension AVAsset {
    /// Returns the duration in seconds
    var durationInSeconds: TimeInterval {
        return duration.seconds.isFinite ? duration.seconds : 0
    }
}