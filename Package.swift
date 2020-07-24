// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SwiftyCVPixelBuffer",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v11),
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "SwiftyCVPixelBuffer",
                 targets: ["SwiftyCVPixelBuffer"]),
    ],
    targets: [
        .target(name: "SwiftyCVPixelBuffer",
                path: "Sources",
                exclude: [],
                sources: nil,
                publicHeadersPath: nil,
                cSettings: nil,
                cxxSettings: nil,
                swiftSettings: nil,
                linkerSettings: [
                    .linkedFramework("CoreVideo")
                ]),
        .testTarget(name: "SwiftyCVPixelBufferTests",
                    dependencies: ["SwiftyCVPixelBuffer"])
    ]
)
