// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EndlessRunner",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EndlessRunner",
            targets: ["EndlessRunner"]
        )
    ],
    targets: [
        .target(
            name: "EndlessRunner",
            dependencies: [],
            path: "Sources"
        )
    ]
)
