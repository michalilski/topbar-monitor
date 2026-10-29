import Foundation

/// Fetches Claude plan limits using the Claude Code OAuth token stored in the keychain.
public struct ClaudeUsageSource: UsageSource {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let keychainService = "Claude Code-credentials"
    private let keychain: KeychainReader

    public init(keychain: KeychainReader = KeychainReader()) {
        self.keychain = keychain
    }

    public func fetch() async throws -> UsageSnapshot {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(try accessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        return try ClaudeUsageParser.parse(try await HTTPClient.get(request))
    }

    private func accessToken() throws -> String {
        guard let raw = keychain.password(service: Self.keychainService),
              let credentials = try? JSONDecoder().decode(Credentials.self, from: Data(raw.utf8))
        else { throw UsageError.missingCredentials }
        return credentials.claudeAiOauth.accessToken
    }

    private struct Credentials: Decodable {
        struct OAuth: Decodable { let accessToken: String }
        let claudeAiOauth: OAuth
    }
}

enum ClaudeUsageParser {
    static func parse(_ data: Data) throws -> UsageSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let payload = try? decoder.decode(Payload.self, from: data) else { throw UsageError.invalidResponse }
        return UsageSnapshot(session: payload.fiveHour.map(window), weekly: payload.sevenDay.map(window))
    }

    private static func window(_ raw: Payload.Window) -> UsageWindow {
        UsageWindow(percent: raw.utilization, resetsAt: raw.resetsAt.flatMap(ISODate.parse))
    }

    private struct Payload: Decodable {
        struct Window: Decodable {
            let utilization: Double
            let resetsAt: String?
        }
        let fiveHour: Window?
        let sevenDay: Window?
    }
}
