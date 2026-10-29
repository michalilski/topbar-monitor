import Foundation
import Network

enum OAuthCallbackError: Error {
    case timedOut
    case rejected
}

/// One-shot loopback HTTP listener that captures the OAuth `code` from the browser redirect.
final class OAuthCallbackServer {
    private static let timeout: TimeInterval = 300
    private static let successPage = """
        <html><body style="font-family:monospace;background:#111;color:#ddd;padding:40px">
        <pre>[ TOPBAR//MONITOR ]\n\n&gt;&gt; SIGNED IN. YOU CAN CLOSE THIS TAB.</pre></body></html>
        """

    private let port: UInt16
    private let path: String

    init(port: UInt16, path: String) {
        self.port = port
        self.path = path
    }

    func waitForCode(state: String, onReady: @escaping @Sendable () -> Void) async throws -> String {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port)!)
        let listener = try NWListener(using: parameters)
        defer { listener.cancel() }
        return try await withCheckedThrowingContinuation { continuation in
            var finished = false
            let finish: (Result<String, Error>) -> Void = { result in
                guard !finished else { return }
                finished = true
                continuation.resume(with: result)
            }
            listener.stateUpdateHandler = { state in
                if case .ready = state { onReady() }
                if case .failed(let error) = state { finish(.failure(error)) }
            }
            listener.newConnectionHandler = { [path] connection in
                Self.handle(connection, path: path, state: state, finish: finish)
            }
            listener.start(queue: .main)
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout) { finish(.failure(OAuthCallbackError.timedOut)) }
        }
    }

    static func code(fromRequest request: String, path: String, state: String) -> Result<String, Error>? {
        let target = request.split(separator: " ").dropFirst().first.map(String.init) ?? ""
        guard let components = URLComponents(string: "http://localhost" + target), components.path == path else { return nil }
        let items = components.queryItems ?? []
        let value = { (name: String) in items.first { $0.name == name }?.value }
        guard value("state") == state, let code = value("code") else { return .failure(OAuthCallbackError.rejected) }
        return .success(code)
    }

    private static func handle(
        _ connection: NWConnection, path: String, state: String, finish: @escaping (Result<String, Error>) -> Void
    ) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { data, _, _, _ in
            let request = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
            let result = code(fromRequest: request, path: path, state: state)
            let body = result == nil ? "Not found" : successPage
            let response = "HTTP/1.1 \(result == nil ? "404 Not Found" : "200 OK")\r\nContent-Type: text/html\r\n"
                + "Content-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
            if let result { finish(result) }
        }
    }
}
