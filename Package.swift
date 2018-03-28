// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SwiftFormat",
    products: [
        .executable(name: "swiftformat", targets: ["CLI"]),
        .library(name: "SwiftFormat", targets: ["SwiftFormat"]),
    ],
    targets: [
        .target(name: "CLI", dependencies: ["SwiftFormat"], path: "CommandLineTool"),
        .target(name: "SwiftFormat", path: "Sources"),
        .testTarget(name: "Tests", dependencies: ["SwiftFormat"], path: "Tests"),
    ]
)
