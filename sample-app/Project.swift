import ProjectDescription

let project = Project(
    name: "SampleApp",
    packages: [
        .remote(
            url: "https://github.com/magnit-tech/mads-ios-sdk",
            requirement: .upToNextMajor(from: "0.0.1")
        )
    ],
    targets: [
        .target(
            name: "MadSDKSampleApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mads.SampleApp",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                ]
            ),
            sources: ["SampleApp/Sources/**"],
            resources: ["SampleApp/Resources/**"],
            dependencies: [
                .package(product: "MadSDK", type: .runtime)
            ]
        ),
        .target(
            name: "SampleAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.SampleAppTests",
            infoPlist: .default,
            sources: ["SampleApp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "MadSDKSampleApp")]
        ),
    ]
)
