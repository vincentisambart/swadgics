// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swadgics",
    // macOS 13 to be able to use `Regex`.
    // (It should not be hard to support older versions of macOS using `NSRegularExpression` if needed)
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "swadgics", targets: ["Swadgics"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
    ],
    targets: [
        .executableTarget(
            name: "Swadgics",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [
                .embedInCode("Resources/alpha_badge_dark.png"),
                .embedInCode("Resources/alpha_badge_light.png"),
                .embedInCode("Resources/beta_badge_dark.png"),
                .embedInCode("Resources/beta_badge_light.png"),
            ]
        ),
    ]
)
