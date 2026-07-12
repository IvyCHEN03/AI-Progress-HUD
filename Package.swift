// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIProgressHUD",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "AIProgressHUD", targets: ["AIProgressHUD"])],
    targets: [
        .executableTarget(
            name: "AIProgressHUD",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Network"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(name: "AIProgressHUDTests", dependencies: ["AIProgressHUD"])
    ]
)
