import Foundation

@MainActor
public final class NetworkSpeedMetric: Metric {
    private static let sparklineWidth = 24

    public let id = "network.speed"
    public let name = "NET SPEED"
    public let status = "LIVE"
    private let monitor: NetworkMonitor

    public init(monitor: NetworkMonitor) {
        self.monitor = monitor
    }

    public var barSegments: [BarSegment] {
        [
            BarSegment(label: "DN", value: ByteFormat.rate(monitor.downloadRate).leftPadded(9)),
            BarSegment(label: "UP", value: ByteFormat.rate(monitor.uploadRate).leftPadded(9)),
        ]
    }

    public var detailLines: [String] {
        [
            row("DOWN", monitor.downloadRate, monitor.downloadHistory),
            row("UP", monitor.uploadRate, monitor.uploadHistory),
        ]
    }

    private func row(_ label: String, _ rate: Double, _ history: [Double]) -> String {
        "\(label.padded(8)) \(ByteFormat.rate(rate).leftPadded(10))  \(Sparkline.render(history, width: Self.sparklineWidth))"
    }
}

@MainActor
public final class NetworkUsageMetric: Metric {
    public let id = "network.usage"
    public let name = "DATA USAGE"
    private let monitor: NetworkMonitor

    public init(monitor: NetworkMonitor) {
        self.monitor = monitor
    }

    public var status: String {
        "SINCE " + monitor.startedAt.formatted(date: .omitted, time: .shortened)
    }

    public var barSegments: [BarSegment] {
        [BarSegment(label: "DATA", value: ByteFormat.size(total))]
    }

    public var detailLines: [String] {
        [
            row("RECV", Double(monitor.received)),
            row("SENT", Double(monitor.sent)),
            row("TOTAL", total),
        ]
    }

    private func row(_ label: String, _ bytes: Double) -> String {
        "\(label.padded(8)) \(ByteFormat.size(bytes).leftPadded(10))"
    }

    private var total: Double {
        Double(monitor.received + monitor.sent)
    }
}
