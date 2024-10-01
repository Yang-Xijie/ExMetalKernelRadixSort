// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExMetalKernelSortUInt32",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ExMetalKernelSortUInt32",
            targets: ["ExMetalKernelSortUInt32"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ExMetalKernelSortUInt32"),
        .testTarget(
            name: "ExMetalKernelSortUInt32Tests",
            dependencies: ["ExMetalKernelSortUInt32"]),
    ]
)
