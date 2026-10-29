public protocol AccountProvider: Sendable {
    var serviceName: String { get }
    var isSignedIn: Bool { get }
    func signIn() async throws
    func signOut() async
}
