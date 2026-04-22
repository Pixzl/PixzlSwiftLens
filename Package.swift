// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PixzlSwiftLens",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PixzlSwiftLens",
            targets: ["PixzlSwiftLens"]
        )
    ],
    targets: [
        .target(
            name: "PixzlSwiftLens",
            path: "Sources/PixzlSwiftLens",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PixzlSwiftLensTests",
            dependencies: ["PixzlSwiftLens"],
            path: "Tests/PixzlSwiftLensTests"
        )
    ]
)
