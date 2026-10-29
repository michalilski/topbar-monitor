import Foundation

enum Base64URL {
    static func encode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decode(_ string: String) -> Data? {
        var base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}

enum JWT {
    static func claims(_ token: String) -> [String: Any] {
        let parts = token.split(separator: ".")
        guard parts.count >= 2,
              let data = Base64URL.decode(String(parts[1])),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return claims
    }

    static func expiry(_ token: String) -> Date? {
        (claims(token)["exp"] as? Double).map(Date.init(timeIntervalSince1970:))
    }
}
