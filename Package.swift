// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Worklifebalance",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Worklifebalance",
            path: "Sources/Worklifebalance",
            linkerSettings: [.linkedFramework("Carbon")]
        ),
    ]
)
