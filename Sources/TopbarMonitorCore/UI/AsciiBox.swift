enum AsciiBox {
    static func top(title: String, status: String, width: Int) -> String {
        let left = "+-[ \(title) ]"
        let right = "[ \(status) ]-+"
        return left + String(repeating: "-", count: max(width - left.count - right.count, 1)) + right
    }

    static func row(_ content: String, width: Int) -> String {
        "|  " + content.padded(width - 5) + " |"
    }

    static func bottom(width: Int) -> String {
        "+" + String(repeating: "-", count: width - 2) + "+"
    }
}
