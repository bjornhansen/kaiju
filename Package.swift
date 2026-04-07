// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Kaiju",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "KaijuLib", targets: ["Kaiju"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "Kaiju",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                "KeychainAccess",
            ],
            path: "Sources/Kaiju",
            exclude: ["App/KaijuApp.swift"]
        ),
        .testTarget(
            name: "KaijuTests",
            dependencies: ["Kaiju"],
            path: "Tests/KaijuTests"
        ),
    ]
)
