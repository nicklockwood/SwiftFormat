// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "SwiftFormat",
    products: [
        .executable(name: "swiftformat", targets: ["CommandLineTool"]),
        .library(name: "SwiftFormat", targets: ["SwiftFormat"]),
    ],
    targets: [
        .target(name: "CommandLineTool", dependencies: ["SwiftFormat"], path: "CommandLineTool"),
        .target(name: "SwiftFormat", path: "Sources"),
        .testTarget(name: "SwiftFormatTests", dependencies: ["SwiftFormat"], path: "Tests"),
    ]
)
