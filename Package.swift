// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MadSDK",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "MadSDK", targets: ["MadSDK"]),
        .library(name: "MadSDKSentry", targets: ["MadSDKSentry"]),
        .library(name: "MadSDKKingfisher", targets: ["MadSDKKingfisher"]),
        .library(name: "MadSDKDefaults", targets: ["MadSDKDefaults"])
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", "8.0.0"..<"10.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "MadSDK",
            path: "MadSDK.xcframework"
        ),
        .target(
            name: "MadSDKSentry",
            dependencies: [
                "MadSDK",
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "MadSDKSentry/Sources"
        ),
        .target(
            name: "MadSDKKingfisher",
            dependencies: [
                "MadSDK",
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "MadSDKKingfisher/Sources"
        ),
        .target(
            name: "MadSDKDefaults",
            dependencies: ["MadSDK", "MadSDKSentry", "MadSDKKingfisher"],
            path: "MadSDKDefaults/Sources"
        )
    ]
)
