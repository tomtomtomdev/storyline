import SwiftUI

struct AudiobookCard: View {
    let audiobook: Audiobook
    let playbackManager: PlaybackManager?
    let onTap: () -> Void

    @State private var isCurrentlyPlaying = false

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallPadding) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill(Color.cardBackground)
                    .aspectRatio(1, contentMode: .fit)

                if audiobook.hasArtwork {
                    // TODO: Load and display artwork
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.themePrimary)
                } else {
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.themePrimary)
                }

                // Progress indicator
                VStack {
                    Spacer()
                    HStack {
                        ProgressView(value: audiobook.progress)
                            .tint(Color.forProgress(audiobook.progress))
                            .scaleEffect(x: 1, y: 0.5, anchor: .center)
                    }
                    .padding(8)
                }
            }

            // Title and Author
            VStack(alignment: .leading, spacing: 4) {
                Text(audiobook.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(audiobook.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let narrator = audiobook.narrator {
                    Text("Narrated by \(narrator)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Progress and duration
            HStack {
                Text(audiobook.progressPercentage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.progressColor)

                Spacer()

                Text(audiobook.durationFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Tags
            if !audiobook.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(audiobook.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .scaleEffect(isCurrentlyPlaying ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isCurrentlyPlaying)
        .onAppear {
            checkIfPlaying()
        }
    }

    private func checkIfPlaying() {
        Task {
            // TODO: Check if this audiobook is currently playing
            // This would require the PlaybackManager to expose current playing state
        }
    }
}

#Preview {
    let sampleBook = Audiobook.preview
    sampleBook.updatePosition(1800) // Halfway through

    return LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
        AudiobookCard(
            audiobook: sampleBook,
            playbackManager: nil,
            onTap: {}
        )
    }
    .padding()
}