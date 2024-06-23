// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "user-defaults-observation",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v17)],
    products: [
        .library(
            name: "UserDefaultsObservation",
            targets: ["UserDefaultsObservation"]
        ),
        .executable(
            name: "UserDefaultsObservationClient",
            targets: ["UserDefaultsObservationClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0")
    ],
    targets: [
        .macro(
            name: "UserDefaultsObservationMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "UserDefaultsObservation",
            dependencies: ["UserDefaultsObservationMacros"]
        ),
        .executableTarget(
            name: "UserDefaultsObservationClient",
            dependencies: ["UserDefaultsObservation"]
        ),
        .testTarget(
            name: "UserDefaultsObservationTests",
            dependencies: [
                "UserDefaultsObservation",
                "UserDefaultsObservationMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
