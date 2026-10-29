import Foundation
import Testing
@testable import TopbarMonitorCore

struct AuthTests {
    @Test func pkceMatchesRFC7636Example() {
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func readsJWTClaims() {
        let token = Self.jwt(["exp": 1_800_000_000, "https://api.openai.com/auth": ["chatgpt_account_id": "acc-1"]])
        #expect(JWT.expiry(token) == Date(timeIntervalSince1970: 1_800_000_000))
        #expect(ChatGPTTokens(idToken: token, accessToken: "a", refreshToken: "r").accountId == "acc-1")
        #expect(JWT.claims("garbage").isEmpty)
    }

    @Test func authorizeURLCarriesPKCEAndState() {
        let url = ChatGPTAuth.authorizeURL(pkce: PKCE(verifier: "v"), state: "s1").absoluteString
        #expect(url.hasPrefix("https://auth.openai.com/oauth/authorize?"))
        #expect(url.contains("code_challenge_method=S256"))
        #expect(url.contains("state=s1"))
        #expect(url.contains("redirect_uri=http://localhost:1455/auth/callback"))
    }

    @Test func parsesCallbackRequest() throws {
        let ok = OAuthCallbackServer.code(fromRequest: "GET /auth/callback?code=abc&state=s1 HTTP/1.1", path: "/auth/callback", state: "s1")
        #expect(try ok?.get() == "abc")
        let forged = OAuthCallbackServer.code(fromRequest: "GET /auth/callback?code=abc&state=bad HTTP/1.1", path: "/auth/callback", state: "s1")
        #expect(throws: OAuthCallbackError.self) { try forged?.get() }
        #expect(OAuthCallbackServer.code(fromRequest: "GET /favicon.ico HTTP/1.1", path: "/auth/callback", state: "s1") == nil)
    }

    @Test func tokenStoreRoundTripsWithPrivatePermissions() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + "/auth.json")
        let store = TokenStore(fileURL: url)
        let tokens = ChatGPTTokens(idToken: "i", accessToken: "a", refreshToken: "r")
        try store.save(tokens)
        #expect(store.load() == tokens)
        let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
        #expect(permissions == 0o600)
        store.delete()
        #expect(!store.exists)
    }

    private static func jwt(_ claims: [String: Any]) -> String {
        let payload = try! JSONSerialization.data(withJSONObject: claims)
        return "e30." + Base64URL.encode(payload) + ".sig"
    }
}
