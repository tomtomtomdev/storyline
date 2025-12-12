import Foundation
import AVFoundation

/// Manages audio file operations and sample data
@MainActor
class AudioFileManager {
    /// Creates a sample audio file for testing
    /// - Returns: URL to the created sample file
    static func createSampleAudioFile() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent("sample_audiobook.m4a")

        // Check if file already exists
        if FileManager.default.fileExists(atPath: audioFileURL.path) {
            return audioFileURL
        }

        // Create a simple sine wave audio file
        let sampleRate: Double = 44100
        let duration: Double = 30.0 // 30 seconds
        let frequency: Double = 440 // A4 note

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!,
            frameCapacity: frameCount
        )!

        // Generate sine wave
        for frame in 0..<Int(frameCount) {
            let sample = sin(2 * Double.pi * frequency * Double(frame) / sampleRate)
            buffer.floatChannelData![0][frame] = Float(sample) * 0.5 // Reduce volume
        }

        buffer.frameLength = frameCount

        // Create audio file
        let audioFile = try? AVAudioFile(
            forWriting: audioFileURL,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128000
            ]
        )

        do {
            try audioFile?.write(from: buffer)
            return audioFileURL
        } catch {
            print("Failed to write audio file: \(error)")
            return nil
        }
    }

    /// Gets the URL for bundled sample audiobooks
    /// - Parameter fileName: Name of the audio file
    /// - Returns: URL to the bundled file
    static func getBundledAudioFileURL(fileName: String) -> URL? {
        return Bundle.main.url(forResource: fileName, withExtension: "m4a") ??
               Bundle.main.url(forResource: fileName, withExtension: "mp3") ??
               Bundle.main.url(forResource: fileName, withExtension: "wav")
    }

    /// Validates if an audio file is supported
    /// - Parameter url: URL of the audio file
    /// - Returns: Whether the file is supported
    static func isAudioFileSupported(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return PlaybackConstants.supportedAudioFormats.contains(fileExtension)
    }

    /// Gets the duration of an audio file without loading it fully
    /// - Parameter url: URL of the audio file
    /// - Returns: Duration in seconds, or nil if unavailable
    static func getAudioFileDuration(_ url: URL) async -> TimeInterval? {
        let asset = AVAsset(url: url)

        do {
            let duration = try await asset.load(.duration)
            return duration.seconds.isFinite ? duration.seconds : nil
        } catch {
            print("Failed to load duration: \(error)")
            return nil
        }
    }

    /// Extracts metadata from an audio file
    /// - Parameter url: URL of the audio file
    /// - Returns: Dictionary containing metadata
    static func extractMetadata(from url: URL) async -> [String: Any] {
        let asset = AVAsset(url: url)
        var metadata: [String: Any] = [:]

        do {
            let commonMetadata = try await asset.load(.commonMetadata)

            for item in commonMetadata {
                guard let key = item.commonKey?.rawValue else { continue }

                switch key {
                case AVMetadataKey.commonKeyTitle.rawValue:
                    metadata["title"] = item.stringValue ?? "Unknown Title"
                case AVMetadataKey.commonKeyArtist.rawValue:
                    metadata["author"] = item.stringValue ?? "Unknown Author"
                case "albumArtist":
                    metadata["narrator"] = item.stringValue
                default:
                    break
                }
            }

            // Extract duration
            let duration = try await asset.load(.duration)
            metadata["duration"] = duration.seconds.isFinite ? duration.seconds : 0

            // Extract artwork
            let artworkData = try await extractArtwork(from: asset)
            if artworkData != nil {
                metadata["artworkData"] = artworkData
            }

        } catch {
            print("Failed to extract metadata: \(error)")
        }

        return metadata
    }

    /// Extracts artwork from audio asset
    /// - Parameter asset: The audio asset
    /// - Returns: Artwork data, or nil if not found
    private static func extractArtwork(from asset: AVAsset) async throws -> Data? {
        let artworkMetadata = try await asset.load(.metadata)
            .filter { $0.commonKey == AVMetadataKey.commonKeyArtwork }

        for item in artworkMetadata {
            if let data = item.dataValue {
                return data
            }
        }

        return nil
    }

    /// Gets the file size of an audio file
    /// - Parameter url: URL of the audio file
    /// - Returns: File size in bytes
    static func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("Failed to get file size: \(error)")
            return 0
        }
    }

    /// Deletes an audio file
    /// - Parameter url: URL of the file to delete
    /// - Returns: Whether the deletion was successful
    static func deleteAudioFile(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("Failed to delete audio file: \(error)")
            return false
        }
    }

    /// Copies an audio file to the app's documents directory
    /// - Parameters:
    ///   - sourceURL: Source URL of the audio file
    ///   - fileName: Desired filename
    /// - Returns: URL of the copied file
    static func copyAudioFileToDocuments(from sourceURL: URL, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(fileName)

        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Copy the file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to copy audio file: \(error)")
            return nil
        }
    }
}