import Foundation

public struct BarSegment: Equatable {
    public let label: String
    public let value: String
    public let alert: Bool

    public init(label: String, value: String, alert: Bool = false) {
        self.label = label
        self.value = value
        self.alert = alert
    }
}

public struct MetricAction {
    public let title: String
    public let perform: @MainActor () async -> Void
}

@MainActor
public protocol Metric: AnyObject {
    var id: String { get }
    var name: String { get }
    var status: String { get }
    var barSegments: [BarSegment] { get }
    var detailLines: [String] { get }
    var actions: [MetricAction] { get }
}

public extension Metric {
    var actions: [MetricAction] { [] }
}

@MainActor
public protocol Refreshable: AnyObject {
    var interval: TimeInterval { get }
    func refresh() async
}
