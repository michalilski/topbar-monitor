import Foundation

@MainActor
public final class NetworkMonitor: Refreshable {
    private static let historyLength = 60

    public let interval: TimeInterval = 1
    public let startedAt: Date
    public private(set) var downloadRate: Double = 0
    public private(set) var uploadRate: Double = 0
    public private(set) var downloadHistory: [Double] = []
    public private(set) var uploadHistory: [Double] = []
    public private(set) var received: UInt64 = 0
    public private(set) var sent: UInt64 = 0
    private let reader: () -> InterfaceCounters
    private var last: InterfaceCounters
    private var lastSampledAt: Date

    public init(reader: @escaping () -> InterfaceCounters = InterfaceStats.read, now: Date = Date()) {
        self.reader = reader
        self.last = reader()
        self.lastSampledAt = now
        self.startedAt = now
    }

    public func refresh() async {
        sample(at: Date())
    }

    func sample(at now: Date) {
        let current = reader()
        let elapsed = max(now.timeIntervalSince(lastSampledAt), 0.001)
        let down = current.received.delta(from: last.received)
        let up = current.sent.delta(from: last.sent)
        downloadRate = Double(down) / elapsed
        uploadRate = Double(up) / elapsed
        downloadHistory = Array((downloadHistory + [downloadRate]).suffix(Self.historyLength))
        uploadHistory = Array((uploadHistory + [uploadRate]).suffix(Self.historyLength))
        received += down
        sent += up
        last = current
        lastSampledAt = now
    }
}

private extension UInt64 {
    func delta(from previous: UInt64) -> UInt64 {
        self >= previous ? self - previous : 0
    }
}
