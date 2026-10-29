import CryptoKit
import Foundation

struct PKCE {
    let verifier: String
    let challenge: String

    init(verifier: String = PKCE.randomToken(byteCount: 64)) {
        self.verifier = verifier
        self.challenge = Base64URL.encode(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    static func randomToken(byteCount: Int) -> String {
        Base64URL.encode(Data((0..<byteCount).map { _ in UInt8.random(in: .min ... .max) }))
    }
}
