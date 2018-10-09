// swift-tools-version:4.2
// Managed by ice

import PackageDescription

let package = Package(
    name: "VideoPlayerManager",
    products: [
        .library(name: "VideoPlayerManager", targets: ["VideoPlayerManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "4.3.1"),
    ],
    targets: [
        .target(name: "VideoPlayerManager", dependencies: ["RxSwift", "RxCocoa"]),
        .testTarget(name: "VideoPlayerManagerTests", dependencies: ["VideoPlayerManager", "RxSwift", "RxCocoa", "RxTest"]),
    ]
)
