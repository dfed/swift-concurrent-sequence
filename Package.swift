// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-concurrent-sequence",
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "SwiftConcurrentSequence",
            targets: ["SwiftConcurrentSequence"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftConcurrentSequence",
            dependencies: [],
			swiftSettings: [
				.swiftLanguageMode(.v6),
			]
        ),
        .testTarget(
            name: "SwiftConcurrentSequenceTests",
            dependencies: ["SwiftConcurrentSequence"],
			swiftSettings: [
				.swiftLanguageMode(.v6),
			]
        ),
    ]
)
