// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GodotFirebaseiOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GodotFirebaseiOS", type: .dynamic, targets: ["GodotFirebaseiOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "61f258c8a679ca8e2b637befb77daf1a640a5349"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0")
    ],
    targets: [
        .target(
            name: "GodotFirebaseiOS",
            dependencies: [
                .product(name: "SwiftGodotRuntimeStatic", package: "SwiftGodot"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
        )
    ]
)
