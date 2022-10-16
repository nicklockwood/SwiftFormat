// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "PackageUsingPlugin",
    products: [
        .library(
            name: "PackageUsingPlugin",
            targets: ["PackageUsingPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../"),
    ],
    targets: [
        .target(
            name: "PackageUsingPlugin",
            dependencies: []
        ),
    ]
)
