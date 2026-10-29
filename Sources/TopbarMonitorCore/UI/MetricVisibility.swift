import Foundation

public final class MetricVisibility {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isVisible(_ id: String) -> Bool {
        defaults.object(forKey: key(id)) as? Bool ?? true
    }

    public func toggle(_ id: String) {
        defaults.set(!isVisible(id), forKey: key(id))
    }

    private func key(_ id: String) -> String {
        "visible.\(id)"
    }
}
