// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PhysioNudge",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PhysioNudge",
            path: "Sources/PhysioNudge"
        )
    ]
)
