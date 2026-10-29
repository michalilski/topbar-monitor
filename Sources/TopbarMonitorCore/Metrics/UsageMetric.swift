import Foundation

@MainActor
public final class UsageMetric: Metric, Refreshable {
    private static let alertThreshold = 80.0

    public let id: String
    public let name: String
    public let interval: TimeInterval
    private let tag: String
    private let source: UsageSource
    private let account: AccountProvider?
    private var snapshot: UsageSnapshot?
    private var error: Error?
    private var isSigningIn = false

    public init(id: String, name: String, tag: String, source: UsageSource, interval: TimeInterval, account: AccountProvider? = nil) {
        self.id = id
        self.name = name
        self.tag = tag
        self.source = source
        self.interval = interval
        self.account = account
    }

    public func refresh() async {
        do {
            snapshot = try await source.fetch()
            error = nil
        } catch {
            self.error = error
        }
    }

    public var status: String {
        if isSigningIn { return "CHECK BROWSER" }
        guard let error else { return snapshot == nil ? "WAIT" : "OK" }
        return (error as? UsageError)?.label ?? "OFFLINE"
    }

    public var barSegments: [BarSegment] {
        guard let snapshot else { return [BarSegment(label: tag, value: placeholder)] }
        return [
            BarSegment(label: tag + " S", value: Percent.text(snapshot.session?.percent), alert: isAlerting(snapshot.session)),
            BarSegment(label: "W", value: Percent.text(snapshot.weekly?.percent), alert: isAlerting(snapshot.weekly)),
        ]
    }

    public var detailLines: [String] {
        [row("SESSION", snapshot?.session), row("WEEKLY", snapshot?.weekly)]
    }

    public var actions: [MetricAction] {
        guard let account, !isSigningIn else { return [] }
        if account.isSignedIn {
            return [MetricAction(title: "LOG OUT OF \(account.serviceName)") { await self.signOut(account) }]
        }
        return [MetricAction(title: "LOG IN TO \(account.serviceName)") { await self.signIn(account) }]
    }

    private var placeholder: String {
        switch error {
        case nil: return "..."
        case UsageError.missingCredentials?: return "LOGIN"
        default: return "ERR"
        }
    }

    private func signIn(_ account: AccountProvider) async {
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            try await account.signIn()
            await refresh()
        } catch {
            self.error = UsageError.signInFailed
        }
    }

    private func signOut(_ account: AccountProvider) async {
        await account.signOut()
        snapshot = nil
        error = UsageError.missingCredentials
    }

    private func row(_ label: String, _ window: UsageWindow?) -> String {
        let percent = Percent.text(window?.percent).leftPadded(4)
        let reset = DurationFormat.remaining(until: window?.resetsAt).leftPadded(6)
        return "\(label.padded(8)) \(AsciiBar.render(window?.percent)) \(percent)  RST \(reset)"
    }

    private func isAlerting(_ window: UsageWindow?) -> Bool {
        (window?.percent ?? 0) >= Self.alertThreshold
    }
}
