// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyClaw",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MyClaw",
            path: "Sources/MyClaw"
        ),
    ]
)
