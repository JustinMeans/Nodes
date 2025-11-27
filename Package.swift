// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nodes",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "Nodes", targets: ["Nodes"]),
    ],
    targets: [
        .target(
            name: "Nodes",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "NodesTests",
            dependencies: ["Nodes"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
