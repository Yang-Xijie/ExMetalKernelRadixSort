// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ExMetalKernelRadixSort",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ExMetalKernelRadixSort",
            targets: [
                "ExMetalKernelRadixSort",
            ]
        ),
    ],
    targets: [
        .target(
            name: "ExMetalKernelRadixSort",
            resources: [
                .process("radix-sort-scan-initilize.metal"),
                .process("radix-sort-scan-reduce.metal"),
                .process("radix-sort-scan-downsweep.metal"),
                .process("radix-sort-assign.metal"),
            ]
        ),
        .testTarget(
            name: "ExMetalKernelRadixSortTests",
            dependencies: [
                "ExMetalKernelRadixSort",
            ]
        ),
    ]
)
