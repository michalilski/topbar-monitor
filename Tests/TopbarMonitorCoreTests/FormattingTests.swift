import Foundation
import Testing
@testable import TopbarMonitorCore

struct FormattingTests {
    @Test func asciiBarFillsProportionally() {
        #expect(AsciiBar.render(50, width: 10) == "[#####.....]")
        #expect(AsciiBar.render(150, width: 4) == "[####]")
        #expect(AsciiBar.render(nil, width: 3) == "[...]")
    }

    @Test func percentHasUnit() {
        #expect(Percent.text(7) == "7%")
        #expect(Percent.text(100) == "100%")
        #expect(Percent.text(nil) == "--")
    }

    @Test func bytesHaveUnits() {
        #expect(ByteFormat.size(512) == "512 B")
        #expect(ByteFormat.size(1536) == "1.5 KB")
        #expect(ByteFormat.size(50 * 1024 * 1024) == "50 MB")
        #expect(ByteFormat.size(3.4 * 1024 * 1024 * 1024) == "3.4 GB")
        #expect(ByteFormat.rate(84 * 1024) == "84 KB/s")
    }

    @Test func sparklineScalesToPeak() {
        #expect(Sparkline.render([0, 5, 10], width: 3) == "[ +@]")
        #expect(Sparkline.render([10], width: 3) == "[  @]")
        #expect(Sparkline.render([], width: 2) == "[  ]")
    }

    @Test func asciiBoxLinesShareWidth() {
        let width = 30
        #expect(AsciiBox.top(title: "01 CLAUDE", status: "OK", width: width).count == width)
        #expect(AsciiBox.row("SESSION", width: width).count == width)
        #expect(AsciiBox.bottom(width: width).count == width)
    }

    @Test func remainingDurationIsHumanReadable() {
        let now = Date(timeIntervalSince1970: 0)
        #expect(DurationFormat.remaining(until: now.addingTimeInterval(45 * 60), now: now) == "45m")
        #expect(DurationFormat.remaining(until: now.addingTimeInterval(133 * 60), now: now) == "2h13m")
        #expect(DurationFormat.remaining(until: now.addingTimeInterval(28 * 3600), now: now) == "1d04h")
        #expect(DurationFormat.remaining(until: now.addingTimeInterval(-60), now: now) == "now")
        #expect(DurationFormat.remaining(until: nil, now: now) == "--")
    }
}
