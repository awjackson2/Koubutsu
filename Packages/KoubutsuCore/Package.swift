// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KoubutsuCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "KoubutsuCore", targets: ["KoubutsuCore"]),
    ],
    targets: [
        .target(name: "KoubutsuCore"),
        .testTarget(name: "KoubutsuCoreTests", dependencies: ["KoubutsuCore"]),
    ]
)
