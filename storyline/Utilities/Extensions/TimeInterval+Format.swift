import Foundation

extension TimeInterval {
    /// Formats a time interval as a duration string
    /// - Returns: Formatted string (e.g., "1:23:45" or "23:45")
    func formatAsDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formats a time interval as a short duration string
    /// - Returns: Short formatted string (e.g., "1h 23m" or "23m")
    func formatAsShortDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Formats a time interval as a remaining time string
    /// - Returns: Formatted string with "remaining" prefix
    func formatAsRemainingTime() -> String {
        let duration = formatAsDuration()
        return "-\(duration)"
    }

    /// Formats a time interval for display in player UI
    /// - Parameter totalDuration: Total duration for calculating percentage
    /// - Returns: Tuple of (currentTimeString, remainingTimeString, percentage)
    func formatForPlayer(totalDuration: TimeInterval) -> (current: String, remaining: String, percentage: Double) {
        let currentString = formatAsDuration()
        let remainingString = (totalDuration - self).formatAsRemainingTime()
        let percentage = totalDuration > 0 ? self / totalDuration : 0

        return (currentString, remainingString, percentage)
    }
}