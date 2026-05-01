// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GodotFirebaseiOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GodotFirebaseiOS", type: .dynamic, targets: ["GodotFirebaseiOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "48112dd50fffe01f0af78e445a16991ecdc6bc94"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0")
    ],
    targets: [
        .target(
            name: "GodotFirebaseiOS",
            dependencies: [
                .product(name: "SwiftGodotRuntimeStatic", package: "SwiftGodot"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
        )
    ]
)
