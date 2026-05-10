// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BlackBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BlackBar", targets: ["BlackBar"])
    ],
    targets: [
        .executableTarget(
            name: "BlackBar",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Security"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("WebKit")
            ]
        )
    ]
)
