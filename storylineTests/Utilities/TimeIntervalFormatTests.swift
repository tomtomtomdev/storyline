import Testing
import Foundation
@testable import storyline

@Suite("TimeInterval+Format Tests")
struct TimeIntervalFormatTests {
    @Test("Format duration - hours, minutes, seconds")
    func testFormatDurationWithHours() throws {
        let timeInterval: TimeInterval = 3665 // 1:01:05
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "1:01:05")
    }

    @Test("Format duration - minutes, seconds")
    func testFormatDurationWithoutHours() throws {
        let timeInterval: TimeInterval = 125 // 2:05
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "2:05")
    }

    @Test("Format duration - single digits")
    func testFormatDurationSingleDigits() throws {
        let timeInterval: TimeInterval = 65 // 1:05
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "1:05")
    }

    @Test("Format duration - zero")
    func testFormatDurationZero() throws {
        let timeInterval: TimeInterval = 0
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "0:00")
    }

    @Test("Format duration - large values")
    func testFormatDurationLargeValues() throws {
        let timeInterval: TimeInterval = 86461 // 24:01:01 (more than 24 hours)
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "24:01:01")
    }

    @Test("Format short duration - with hours")
    func testFormatShortDurationWithHours() throws {
        let timeInterval: TimeInterval = 3900 // 1 hour 5 minutes
        let formatted = timeInterval.formatAsShortDuration()
        #expect(formatted == "1h 5m")
    }

    @Test("Format short duration - without hours")
    func testFormatShortDurationWithoutHours() throws {
        let timeInterval: TimeInterval = 125 // 2 minutes 5 seconds
        let formatted = timeInterval.formatAsShortDuration()
        #expect(formatted == "2m")
    }

    @Test("Format short duration - zero")
    func testFormatShortDurationZero() throws {
        let timeInterval: TimeInterval = 0
        let formatted = timeInterval.formatAsShortDuration()
        #expect(formatted == "0m")
    }

    @Test("Format remaining time")
    func testFormatRemainingTime() throws {
        let timeInterval: TimeInterval = 125 // 2:05
        let formatted = timeInterval.formatAsRemainingTime()
        #expect(formatted == "-2:05")
    }

    @Test("Format remaining time - zero")
    func testFormatRemainingTimeZero() throws {
        let timeInterval: TimeInterval = 0
        let formatted = timeInterval.formatAsRemainingTime()
        #expect(formatted == "-0:00")
    }

    @Test("Format for player UI")
    func testFormatForPlayer() throws {
        let currentTime: TimeInterval = 1800 // 30 minutes
        let totalDuration: TimeInterval = 3600 // 1 hour
        let result = currentTime.formatForPlayer(totalDuration: totalDuration)

        #expect(result.current == "30:00")
        #expect(result.remaining == "-30:00")
        #expect(result.percentage == 0.5)
    }

    @Test("Format for player UI - zero duration")
    func testFormatForPlayerZeroDuration() throws {
        let currentTime: TimeInterval = 100
        let totalDuration: TimeInterval = 0
        let result = currentTime.formatForPlayer(totalDuration: totalDuration)

        #expect(result.current == "1:40")
        #expect(result.remaining == "-1:40")
        #expect(result.percentage == 0)
    }

    @Test("Format for player UI - exceeds duration")
    func testFormatForPlayerExceedsDuration() throws {
        let currentTime: TimeInterval = 4000 // More than total
        let totalDuration: TimeInterval = 3600
        let result = currentTime.formatForPlayer(totalDuration: totalDuration)

        #expect(result.current == "1:06:40")
        #expect(result.remaining == "-66:40")
        #expect(result.percentage > 1.0)
    }

    @Test("Format duration with seconds only")
    func testFormatDurationSecondsOnly() throws {
        let timeInterval: TimeInterval = 45 // 0:45
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "0:45")
    }

    @Test("Format duration edge case - exactly one hour")
    func testFormatDurationExactlyOneHour() throws {
        let timeInterval: TimeInterval = 3600 // 1:00:00
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "1:00:00")
    }

    @Test("Format duration edge case - exactly one minute")
    func testFormatDurationExactlyOneMinute() throws {
        let timeInterval: TimeInterval = 60 // 1:00
        let formatted = timeInterval.formatAsDuration()
        #expect(formatted == "1:00")
    }

    @Test("Format short duration edge cases")
    func testFormatShortDurationEdgeCases() throws {
        // Just under an hour
        let timeInterval1: TimeInterval = 3599 // 59:59
        let formatted1 = timeInterval1.formatAsShortDuration()
        #expect(formatted1 == "59m")

        // Exactly an hour
        let timeInterval2: TimeInterval = 3600 // 1:00:00
        let formatted2 = timeInterval2.formatAsShortDuration()
        #expect(formatted2 == "1h 0m")

        // Just over an hour
        let timeInterval3: TimeInterval = 3601 // 1:00:01
        let formatted3 = timeInterval3.formatAsShortDuration()
        #expect(formatted3 == "1h 0m")
    }
}