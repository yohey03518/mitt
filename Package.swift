// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mac-ocr-capture",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mac-ocr-capture", targets: ["mac-ocr-capture"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "mac-ocr-capture",
            dependencies: []),
        .testTarget(
            name: "mac-ocr-captureTests",
            dependencies: ["mac-ocr-capture"])
    ]
)
