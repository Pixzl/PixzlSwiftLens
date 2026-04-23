// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PixzlSwiftLens",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
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
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "PixzlSwiftLensTests",
            dependencies: ["PixzlSwiftLens"],
            path: "Tests/PixzlSwiftLensTests"
        )
    ]
)
