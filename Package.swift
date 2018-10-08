// swift-tools-version:4.2
// Managed by ice

import PackageDescription

let package = Package(
    name: "RxAVPlayer",
    products: [
        .library(name: "RxAVPlayer", targets: ["RxAVPlayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "4.3.1"),
    ],
    targets: [
        .target(name: "RxAVPlayer", dependencies: ["RxSwift", "RxCocoa"]),
        .testTarget(name: "RxAVPlayerTests", dependencies: ["RxAVPlayer", "RxSwift", "RxCocoa", "RxTest"]),
    ]
)
