import AppKit

@MainActor
struct MenuBuilder {
    private let width = Theme.menuWidth

    let metrics: [Metric]
    let visibility: MetricVisibility
    let onToggle: (Metric) -> Void
    let onAction: (MetricAction) -> Void
    let onRefresh: () -> Void

    func populate(_ menu: NSMenu) {
        menu.removeAllItems()
        addBanner(to: menu)
        metrics.enumerated().forEach { addSection(for: $1, index: $0 + 1, to: menu) }
        addToggles(to: menu)
        addControls(to: menu)
    }

    private func addBanner(to menu: NSMenu) {
        Theme.banner.forEach { menu.addItem(line($0, font: Theme.headerFont)) }
        let stamp = Date().formatted(date: .omitted, time: .standard)
        menu.addItem(line(":: MONITOR ::".padded(width - stamp.count) + stamp, color: .secondaryLabelColor))
        menu.addItem(line(" "))
    }

    private func addSection(for metric: Metric, index: Int, to menu: NSMenu) {
        let title = String(format: "%02d %@", index, metric.name)
        menu.addItem(line(AsciiBox.top(title: title, status: metric.status, width: width), font: Theme.headerFont))
        metric.detailLines.forEach { menu.addItem(line(AsciiBox.row($0, width: width))) }
        for action in metric.actions {
            let title = Theme.text(AsciiBox.row(">> " + action.title, width: width), font: Theme.headerFont)
            menu.addItem(ActionMenuItem(title: title) { onAction(action) })
        }
        menu.addItem(line(AsciiBox.bottom(width: width), color: .secondaryLabelColor))
    }

    private func addToggles(to menu: NSMenu) {
        menu.addItem(line(" "))
        menu.addItem(line("DISPLAY IN BAR", font: Theme.headerFont))
        for metric in metrics {
            let mark = visibility.isVisible(metric.id) ? "[x]" : "[ ]"
            menu.addItem(ActionMenuItem(title: Theme.text("  \(mark) \(metric.name)")) { onToggle(metric) })
        }
    }

    private func addControls(to menu: NSMenu) {
        menu.addItem(line(" "))
        menu.addItem(ActionMenuItem(title: Theme.text("  >> REFRESH"), key: "r", handler: onRefresh))
        menu.addItem(ActionMenuItem(title: Theme.text("  >> QUIT"), key: "q") { NSApp.terminate(nil) })
    }

    private func line(_ text: String, font: NSFont = Theme.menuFont, color: NSColor = .labelColor) -> NSMenuItem {
        let item = NSMenuItem()
        item.attributedTitle = Theme.text(text, font: font, color: color)
        item.isEnabled = false
        return item
    }
}
