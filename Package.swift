// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MadSDK",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "MadSDK", targets: ["MadSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "MadSDK",
            path: "MadSDK.xcframework"
        )
    ]
)
