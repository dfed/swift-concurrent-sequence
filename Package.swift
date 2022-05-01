// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-concurrent-sequence",
    products: [
        .library(
            name: "SwiftConcurrentSequence",
            targets: ["SwiftConcurrentSequence"]),
    ],
    targets: [
        .target(
            name: "SwiftConcurrentSequence",
            dependencies: []),
        .testTarget(
            name: "SwiftConcurrentSequenceTests",
            dependencies: ["SwiftConcurrentSequence"]),
    ]
)
