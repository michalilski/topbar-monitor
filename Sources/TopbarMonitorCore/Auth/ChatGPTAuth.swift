import AppKit
import Foundation

/// ChatGPT sign-in via the OAuth PKCE flow used by the Codex CLI, with automatic token refresh.
public actor ChatGPTAuth: AccountProvider {
    private static let issuer = "https://auth.openai.com"
    private static let clientId = "app_EMoamEEZ73f0CkXaXp7hrann"
    private static let callbackPort: UInt16 = 1455
    private static let callbackPath = "/auth/callback"
    private static let refreshMargin: TimeInterval = 300

    public nonisolated let serviceName = "CHATGPT"
    private let store: TokenStore

    public init(store: TokenStore = TokenStore()) {
        self.store = store
    }

    public nonisolated var isSignedIn: Bool {
        store.exists
    }

    public func signIn() async throws {
        let pkce = PKCE()
        let state = PKCE.randomToken(byteCount: 32)
        let url = Self.authorizeURL(pkce: pkce, state: state)
        let server = OAuthCallbackServer(port: Self.callbackPort, path: Self.callbackPath)
        let code = try await server.waitForCode(state: state) {
            Task { @MainActor in NSWorkspace.shared.open(url) }
        }
        try store.save(try await exchange(code: code, verifier: pkce.verifier))
    }

    public func signOut() async {
        store.delete()
    }

    func validTokens() async throws -> ChatGPTTokens {
        guard let tokens = store.load() else { throw UsageError.missingCredentials }
        guard let expiry = JWT.expiry(tokens.accessToken), expiry < Date().addingTimeInterval(Self.refreshMargin) else {
            return tokens
        }
        return try await refresh(tokens)
    }

    static var redirectURI: String {
        "http://localhost:\(callbackPort)\(callbackPath)"
    }

    static func authorizeURL(pkce: PKCE, state: String) -> URL {
        var components = URLComponents(string: issuer + "/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "openid profile email offline_access"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "id_token_add_organizations", value: "true"),
            URLQueryItem(name: "codex_cli_simplified_flow", value: "true"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "originator", value: "codex_cli_rs"),
        ]
        return components.url!
    }

    private func exchange(code: String, verifier: String) async throws -> ChatGPTTokens {
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "client_id", value: Self.clientId),
            URLQueryItem(name: "code_verifier", value: verifier),
        ]
        let request = Self.tokenRequest(body: Data((form.percentEncodedQuery ?? "").utf8), contentType: "application/x-www-form-urlencoded")
        let response = try Self.decode(try await HTTPClient.get(request))
        guard let id = response.idToken, let access = response.accessToken, let refresh = response.refreshToken else {
            throw UsageError.invalidResponse
        }
        return ChatGPTTokens(idToken: id, accessToken: access, refreshToken: refresh)
    }

    private func refresh(_ tokens: ChatGPTTokens) async throws -> ChatGPTTokens {
        let body = try JSONEncoder().encode([
            "client_id": Self.clientId,
            "grant_type": "refresh_token",
            "refresh_token": tokens.refreshToken,
            "scope": "openid profile email",
        ])
        do {
            let response = try Self.decode(try await HTTPClient.get(Self.tokenRequest(body: body, contentType: "application/json")))
            let refreshed = ChatGPTTokens(
                idToken: response.idToken ?? tokens.idToken,
                accessToken: response.accessToken ?? tokens.accessToken,
                refreshToken: response.refreshToken ?? tokens.refreshToken
            )
            try store.save(refreshed)
            return refreshed
        } catch UsageError.http(let status) where (400..<500).contains(status) {
            store.delete()
            throw UsageError.missingCredentials
        }
    }

    private static func tokenRequest(body: Data, contentType: String) -> URLRequest {
        var request = URLRequest(url: URL(string: issuer + "/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    private static func decode(_ data: Data) throws -> TokenResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let response = try? decoder.decode(TokenResponse.self, from: data) else { throw UsageError.invalidResponse }
        return response
    }

    private struct TokenResponse: Decodable {
        let idToken: String?
        let accessToken: String?
        let refreshToken: String?
    }
}
