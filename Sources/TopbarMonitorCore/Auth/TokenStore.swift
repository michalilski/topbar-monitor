import Foundation

public struct ChatGPTTokens: Codable, Equatable, Sendable {
    let idToken: String
    let accessToken: String
    let refreshToken: String

    var accountId: String? {
        let auth = JWT.claims(idToken)["https://api.openai.com/auth"] as? [String: Any]
        return auth?["chatgpt_account_id"] as? String
    }
}

/// Persists tokens in a user-only (0600) file under Application Support.
public struct TokenStore: Sendable {
    private let fileURL: URL

    public init(fileURL: URL = TokenStore.defaultURL) {
        self.fileURL = fileURL
    }

    public static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "TopbarMonitor/chatgpt-auth.json")
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    func load() -> ChatGPTTokens? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(ChatGPTTokens.self, from: data)
    }

    func save(_ tokens: ChatGPTTokens) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(tokens).write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
