import AppKit

enum Theme {
    static let menuWidth = 56
    static let barFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
    static let menuFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    static let headerFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
    static let alertColor = NSColor.systemOrange

    static let banner = [
        #" _____ ___  ___ ___   _   ___ "#,
        #"|_   _/ _ \| _ \ _ ) /_\ | _ \"#,
        #"  | || (_) |  _/ _ \/ _ \|   /"#,
        #"  |_| \___/|_| |___/_/ \_\_|_\"#,
    ]

    static func text(_ string: String, font: NSFont = menuFont, color: NSColor = .labelColor) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
    }
}
