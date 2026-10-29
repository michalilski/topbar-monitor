import AppKit

@MainActor
public final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let metrics: [Metric]
    private let refreshers: [Refreshable]
    private let visibility: MetricVisibility
    private var loops: [Task<Void, Never>] = []

    public init(metrics: [Metric], refreshers: [Refreshable], visibility: MetricVisibility) {
        self.metrics = metrics
        self.refreshers = refreshers
        self.visibility = visibility
    }

    public func start() {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        refreshers.forEach(schedule)
        refreshAll()
        render()
    }

    public func menuNeedsUpdate(_ menu: NSMenu) {
        MenuBuilder(
            metrics: metrics,
            visibility: visibility,
            onToggle: { [weak self] in self?.toggle($0) },
            onAction: { [weak self] in self?.perform($0) },
            onRefresh: { [weak self] in self?.refreshAll() }
        ).populate(menu)
    }

    private func schedule(_ refresher: Refreshable) {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refresher.interval))
                await self?.refresh(refresher)
            }
        }
        loops.append(task)
    }

    private func refresh(_ refresher: Refreshable) async {
        await refresher.refresh()
        render()
    }

    private func refreshAll() {
        refreshers.forEach { refresher in Task { await refresh(refresher) } }
    }

    private func perform(_ action: MetricAction) {
        Task {
            render()
            await action.perform()
            render()
        }
    }

    private func toggle(_ metric: Metric) {
        visibility.toggle(metric.id)
        render()
    }

    private func render() {
        let visible = metrics.filter { visibility.isVisible($0.id) }
        statusItem.button?.attributedTitle = TitleRenderer.render(visible)
    }
}
