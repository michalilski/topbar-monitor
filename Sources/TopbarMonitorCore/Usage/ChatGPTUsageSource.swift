import Foundation

/// Fetches ChatGPT plan limits using the in-app ChatGPT sign-in.
public struct ChatGPTUsageSource: UsageSource {
    private static let endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!
    private let auth: ChatGPTAuth

    public init(auth: ChatGPTAuth) {
        self.auth = auth
    }

    public func fetch() async throws -> UsageSnapshot {
        let tokens = try await auth.validTokens()
        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        if let accountId = tokens.accountId {
            request.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        }
        return try ChatGPTUsageParser.parse(try await HTTPClient.get(request))
    }
}

enum ChatGPTUsageParser {
    static func parse(_ data: Data, now: Date = Date()) throws -> UsageSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let payload = try? decoder.decode(Payload.self, from: data) else { throw UsageError.invalidResponse }
        return UsageSnapshot(
            session: payload.rateLimit?.primaryWindow.map { window($0, now: now) },
            weekly: payload.rateLimit?.secondaryWindow.map { window($0, now: now) }
        )
    }

    private static func window(_ raw: Payload.Window, now: Date) -> UsageWindow {
        let resetsAt = raw.resetAt.map(Date.init(timeIntervalSince1970:))
            ?? raw.resetAfterSeconds.map(now.addingTimeInterval)
        return UsageWindow(percent: raw.usedPercent, resetsAt: resetsAt)
    }

    private struct Payload: Decodable {
        struct Window: Decodable {
            let usedPercent: Double
            let resetAt: Double?
            let resetAfterSeconds: Double?
        }
        struct RateLimit: Decodable {
            let primaryWindow: Window?
            let secondaryWindow: Window?
        }
        let rateLimit: RateLimit?
    }
}
