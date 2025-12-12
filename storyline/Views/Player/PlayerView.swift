import SwiftUI

struct PlayerView: View {
    let audiobook: Audiobook
    let playbackManager: PlaybackManager?

    @State private var viewModel: PlayerViewModel?
    @State private var isPresented = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: UIConstants.largePadding) {
                // Artwork
                ArtworkView(audiobook: audiobook, progress: viewModel?.progress ?? 0)

                // Title and metadata
                VStack(spacing: UIConstants.smallPadding) {
                    Text(audiobook.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(audiobook.author)
                        .font(.title3)
                        .foregroundColor(.secondary)

                    if let narrator = audiobook.narrator {
                        Text("Narrated by \(narrator)")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Time slider
                TimeSlider(
                    currentTime: viewModel?.currentTime ?? 0,
                    duration: viewModel?.duration ?? audiobook.duration,
                    onSeek: { time in
                        viewModel?.seekToTime(time)
                    }
                )
                .padding(.horizontal)

                // Time labels
                HStack {
                    Text(viewModel?.currentTimeString ?? "0:00")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(viewModel?.remainingTimeString ?? "-0:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Playback controls
                PlaybackControlsView(
                    playbackState: viewModel?.playbackState ?? .stopped,
                    onPlayPause: {
                        viewModel?.togglePlayPause()
                    },
                    onSkipBackward: {
                        viewModel?.skipBackward()
                    },
                    onSkipForward: {
                        viewModel?.skipForward()
                    }
                )

                // Speed control
                Button(action: {
                    viewModel?.cyclePlaybackSpeed()
                }) {
                    HStack {
                        Image(systemName: "speedometer")
                        Text(viewModel?.playbackSpeedDisplay ?? "1.0x")
                    }
                    .font(.callout)
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, UIConstants.standardPadding)
                    .padding(.vertical, UIConstants.smallPadding)
                    .background(Color.themePrimary.opacity(0.1))
                    .cornerRadius(UIConstants.buttonCornerRadius)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel?.toggleFavorite()
                        }) {
                            Label(
                                audiobook.hasTag("Favorites") ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: audiobook.hasTag("Favorites") ? "heart.fill" : "heart"
                            )
                        }

                        Button(action: {
                            viewModel?.setSleepTimer(minutes: 15) // 15 minutes for demo
                        }) {
                            Label("Set Sleep Timer", systemImage: "bed.double")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                setupViewModel()
            }
            .onDisappear {
                cleanupViewModel()
            }
        }
    }

    private func setupViewModel() {
        if let playbackManager = playbackManager {
            viewModel = PlayerViewModel(playbackManager: playbackManager)
            viewModel?.loadAudiobook(audiobook)
        }
    }

    private func cleanupViewModel() {
        // Save current position before dismissing
        if let vm = viewModel {
            Task {
                await vm.pause()
            }
        }
    }
}

// MARK: - Artwork View

struct ArtworkView: View {
    let audiobook: Audiobook
    let progress: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color.cardBackground)
                .aspectRatio(1, contentMode: .fit)
                .shadow(radius: 10)

            if audiobook.hasArtwork {
                // TODO: Load actual artwork
                Image(systemName: "book.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.themePrimary.opacity(0.3))
            } else {
                Image(systemName: "book.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.themePrimary.opacity(0.3))
            }

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .padding(20)
        }
        .padding(.horizontal, UIConstants.largePadding)
    }
}

// MARK: - Time Slider

struct TimeSlider: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    @State private var isDragging = false
    @State private var dragValue: Double?

    private var sliderValue: Double {
        if isDragging, let dragValue = dragValue {
            return dragValue
        }
        return duration > 0 ? currentTime / duration : 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 4)

                // Progress track
                Rectangle()
                    .fill(Color.progressColor)
                    .frame(width: geometry.size.width * sliderValue, height: 4)

                // Thumb
                Circle()
                    .fill(Color.progressColor)
                    .frame(width: 20, height: 20)
                    .offset(x: geometry.size.width * sliderValue - 10)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .shadow(radius: isDragging ? 8 : 2)
            }
        }
        .frame(height: 44)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let newValue = max(0, min(1, value.location.x / value.startLocation.x))
                    dragValue = newValue
                }
                .onEnded { value in
                    let newTime = duration * (max(0, min(1, value.location.x / value.startLocation.x)))
                    onSeek(newTime)
                    isDragging = false
                    dragValue = nil
                }
        )
    }
}

// MARK: - Playback Controls View

struct PlaybackControlsView: View {
    let playbackState: PlaybackState
    let onPlayPause: () -> Void
    let onSkipBackward: () -> Void
    let onSkipForward: () -> Void

    var body: some View {
        HStack(spacing: UIConstants.largePadding) {
            // Skip backward
            Button(action: onSkipBackward) {
                Image(systemName: "gobackward.15")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .frame(width: UIConstants.minTouchTarget, height: UIConstants.minTouchTarget)

            // Play/Pause
            Button(action: onPlayPause) {
                Image(systemName: playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.themePrimary)
            }

            // Skip forward
            Button(action: onSkipForward) {
                Image(systemName: "goforward.15")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .frame(width: UIConstants.minTouchTarget, height: UIConstants.minTouchTarget)
        }
        .padding(.horizontal, UIConstants.largePadding)
    }
}

#Preview {
    PlayerView(
        audiobook: Audiobook.preview,
        playbackManager: nil
    )
}