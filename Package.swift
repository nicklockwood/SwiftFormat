// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftFormat",
    products: [
        .executable(name: "swiftformat", targets: ["CommandLineTool"]),
        .library(name: "SwiftFormat", targets: ["SwiftFormat"]),
        .plugin(name: "SwiftFormatPlugin", targets: ["SwiftFormatPlugin"]),
        .plugin(name: "SwiftFormatLinterBuildToolPlugin", targets: ["SwiftFormatLinterBuildToolPlugin"]),
    ],
    targets: [
        .plugin(
            name: "SwiftFormatLinterBuildToolPlugin",
            capability: .buildTool(),
            dependencies: [.target(name: "CommandLineTool")],
            path: "Plugins/SwiftFormatLinterBuildToolPlugin"
        ),
        .executableTarget(
            name: "CommandLineTool", dependencies: ["SwiftFormat"], path: "CommandLineTool",
            exclude: ["swiftformat"]
        ),
        .target(name: "SwiftFormat", path: "Sources", exclude: ["Info.plist"]),
        .testTarget(
            name: "SwiftFormatTests",
            dependencies: ["SwiftFormat"],
            path: "Tests",
            exclude: ["GlobTest[5].txt"]
        ),
        .plugin(
            name: "SwiftFormatPlugin",
            capability: .command(
                intent: .custom(
                    verb: "swiftformat", description: "Formats Swift source files using SwiftFormat"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "This command reformats source files"),
                ]
            ),
            dependencies: [.target(name: "CommandLineTool")]
        ),
    ]
)
