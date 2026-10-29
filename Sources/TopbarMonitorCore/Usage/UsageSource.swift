import Foundation

public struct UsageWindow: Equatable, Sendable {
    public let percent: Double
    public let resetsAt: Date?
}

public struct UsageSnapshot: Equatable, Sendable {
    public let session: UsageWindow?
    public let weekly: UsageWindow?
}

public protocol UsageSource: Sendable {
    func fetch() async throws -> UsageSnapshot
}

public enum UsageError: Error, Equatable {
    case missingCredentials
    case http(Int)
    case invalidResponse
    case signInFailed

    var label: String {
        switch self {
        case .missingCredentials: return "SIGNED OUT"
        case .http(let status): return "HTTP \(status)"
        case .invalidResponse: return "BAD DATA"
        case .signInFailed: return "LOGIN FAILED"
        }
    }
}

enum HTTPClient {
    static func get(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw UsageError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw UsageError.http(http.statusCode) }
        return data
    }
}
