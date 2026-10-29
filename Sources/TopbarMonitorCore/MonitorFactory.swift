import Foundation

@MainActor
public enum MonitorFactory {
    private static let usageInterval: TimeInterval = 120

    public static func makeController() -> StatusBarController {
        let network = NetworkMonitor()
        let chatGPTAuth = ChatGPTAuth()
        let claude = UsageMetric(id: "claude", name: "CLAUDE", tag: "CLD", source: ClaudeUsageSource(), interval: usageInterval)
        let gpt = UsageMetric(
            id: "gpt", name: "GPT", tag: "GPT",
            source: ChatGPTUsageSource(auth: chatGPTAuth), interval: usageInterval, account: chatGPTAuth
        )
        let metrics: [Metric] = [claude, gpt, NetworkSpeedMetric(monitor: network), NetworkUsageMetric(monitor: network)]
        return StatusBarController(metrics: metrics, refreshers: [claude, gpt, network], visibility: MetricVisibility())
    }
}
