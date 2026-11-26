// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DinkyCalCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "DinkyCalCore", targets: ["DinkyCalCore"])],
    targets: [
        .target(name: "DinkyCalCore"),
        .testTarget(name: "DinkyCalCoreTests", dependencies: ["DinkyCalCore"]),
    ]
)
