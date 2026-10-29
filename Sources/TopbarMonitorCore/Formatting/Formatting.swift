import Foundation

enum AsciiBar {
    static func render(_ percent: Double?, width: Int = 20) -> String {
        guard let percent else { return "[" + String(repeating: ".", count: width) + "]" }
        let clamped = min(max(percent, 0), 100)
        let filled = Int((clamped / 100 * Double(width)).rounded())
        return "[" + String(repeating: "#", count: filled) + String(repeating: ".", count: width - filled) + "]"
    }
}

enum Sparkline {
    private static let ramp = Array(" .:-=+*#%@")

    static func render(_ values: [Double], width: Int) -> String {
        let recent = Array(values.suffix(width))
        let peak = max(recent.max() ?? 0, 1)
        let glyphs = recent.map { value -> Character in
            let level = Int((value / peak * Double(ramp.count - 1)).rounded())
            return ramp[min(max(level, 0), ramp.count - 1)]
        }
        return "[" + String(repeating: " ", count: width - glyphs.count) + String(glyphs) + "]"
    }
}

enum Percent {
    static func text(_ percent: Double?) -> String {
        guard let percent else { return "--" }
        return String(format: "%.0f%%", percent)
    }
}

enum ByteFormat {
    private static let units = ["B", "KB", "MB", "GB", "TB"]

    static func size(_ bytes: Double) -> String {
        var value = max(bytes, 0)
        var index = 0
        while value >= 1000 && index < units.count - 1 {
            value /= 1024
            index += 1
        }
        let format = value < 10 && index > 0 ? "%.1f" : "%.0f"
        return String(format: format, value) + " " + units[index]
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        size(bytesPerSecond) + "/s"
    }
}

enum DurationFormat {
    static func remaining(until date: Date?, now: Date = Date()) -> String {
        guard let date else { return "--" }
        let minutes = Int(date.timeIntervalSince(now) / 60)
        guard minutes > 0 else { return "now" }
        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        if days > 0 { return String(format: "%dd%02dh", days, hours) }
        if hours > 0 { return String(format: "%dh%02dm", hours, minutes % 60) }
        return "\(minutes)m"
    }
}

enum ISODate {
    static func parse(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }
}

extension String {
    func padded(_ length: Int) -> String {
        padding(toLength: max(length, count), withPad: " ", startingAt: 0)
    }

    func leftPadded(_ length: Int) -> String {
        String(repeating: " ", count: max(length - count, 0)) + self
    }
}
