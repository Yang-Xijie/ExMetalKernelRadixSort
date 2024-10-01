// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ExMetalKernelSortUInt32",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ExMetalKernelSortUInt32",
            targets: [
                "ExMetalKernelSortUInt32",
            ]
        ),
    ],
    targets: [
        .target(
            name: "ExMetalKernelSortUInt32",
            resources: [
                .process("radix-sort.metal"),
            ]
        ),
        .testTarget(
            name: "ExMetalKernelSortUInt32Tests",
            dependencies: [
                "ExMetalKernelSortUInt32",
            ]
        ),
    ]
)
