// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KlipySDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KlipyCore",
            targets: ["KlipyCore"]
        ),
        .library(
            name: "KlipyUI",
            targets: ["KlipyUI"]
        ),
        .library(
            name: "KlipyTray",
            targets: ["KlipyTray"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.23.1")),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.0.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KlipyCore",
            path: "Sources/KlipyCore"
        ),
        .target(
            name: "KlipyUI",
            dependencies: ["KlipyCore", "SDWebImageSwiftUI", "SDWebImageWebPCoder"],
            path: "Sources/KlipyUI",
            resources: [.process("Resources/Media.xcassets")]
        ),
        .target(
            name: "KlipyTray",
            dependencies: [
              "KlipyCore",
              "KlipyUI",
              "SDWebImageSwiftUI",
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/KlipyTray",
            resources: [.process("Resources/Media.xcassets")]
        ),
        .testTarget(
            name: "KlipyCoreTests",
            dependencies: ["KlipyCore", "Mocker"]
        ),
    ]
)
