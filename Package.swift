// swift-tools-version:4.2
// Managed by ice

import PackageDescription

let package = Package(
    name: "VideoPlayer",
    products: [
        .library(name: "VideoPlayer", targets: ["VideoPlayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "4.3.1"),
    ],
    targets: [
        .target(name: "VideoPlayer", dependencies: ["RxSwift", "RxCocoa"]),
        .testTarget(name: "VideoPlayerTests", dependencies: ["VideoPlayer", "RxSwift", "RxCocoa", "RxTest"]),
    ]
)
