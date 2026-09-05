// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoveMenuCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "MoveMenuCore", targets: ["MoveMenuCore"])],
    targets: [
        .target(name: "MoveMenuCore", path: "MoveMenu/Core"),
        .testTarget(name: "MoveMenuCoreTests", dependencies: ["MoveMenuCore"], path: "Tests/MoveMenuCoreTests")
    ]
)
