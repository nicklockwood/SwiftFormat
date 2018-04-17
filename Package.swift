// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftFormat",
    products: [
        .executable(name: "swiftFormat", targets: ["CommandLineTool"]),
        .library(
            name: "SwiftFormat",
            targets: ["SwiftFormat"]
        ),
    ],
    targets: [
        .target(name: "CommandLineTool", dependencies: ["SwiftFormat"], path: "CommandLineTool"),
        .target(name: "SwiftFormat", path: "Sources"),
        .testTarget(name: "Tests", dependencies: ["SwiftFormat"], path: "Tests"),
    ]
)
