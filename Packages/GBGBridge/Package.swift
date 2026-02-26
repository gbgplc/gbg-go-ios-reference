// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GBGBridge",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "GBGBridge", targets: ["GBGBridge"])
    ],
    targets: [
        .target(
            name: "GBGBridge",
            path: "Sources/GBGBridge"
        )
    ]
)
