// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MadSDK",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "MadSDK", targets: ["MadSDK"]),
        .library(name: "MadSDKSentry", targets: ["MadSDKSentry"])
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", "8.0.0"..<"10.0.0")
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
        )
    ]
)
