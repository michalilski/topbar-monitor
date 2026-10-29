import AppKit

@MainActor
enum TitleRenderer {
    private static let metricSeparator = "  |  "
    private static let placeholder = "[ TBM ]"

    static func render(_ metrics: [Metric]) -> NSAttributedString {
        guard !metrics.isEmpty else { return Theme.text(placeholder, font: Theme.barFont) }
        let title = NSMutableAttributedString()
        for (index, metric) in metrics.enumerated() {
            if index > 0 { title.append(Theme.text(metricSeparator, font: Theme.barFont, color: .tertiaryLabelColor)) }
            title.append(render(metric.barSegments))
        }
        return title
    }

    private static func render(_ segments: [BarSegment]) -> NSAttributedString {
        let text = NSMutableAttributedString()
        for (index, segment) in segments.enumerated() {
            if index > 0 { text.append(Theme.text(" ", font: Theme.barFont)) }
            text.append(Theme.text(segment.label + " ", font: Theme.barFont, color: .secondaryLabelColor))
            text.append(Theme.text(segment.value, font: Theme.barFont, color: segment.alert ? Theme.alertColor : .labelColor))
        }
        return text
    }
}
