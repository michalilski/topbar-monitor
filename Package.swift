// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "TopbarMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "TopbarMonitorCore"),
        .executableTarget(name: "TopbarMonitor", dependencies: ["TopbarMonitorCore"]),
        .testTarget(name: "TopbarMonitorCoreTests", dependencies: ["TopbarMonitorCore"]),
    ]
)
