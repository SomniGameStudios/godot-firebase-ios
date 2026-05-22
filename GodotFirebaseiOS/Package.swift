// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "GodotFirebaseiOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GodotFirebaseiOS", type: .dynamic, targets: ["GodotFirebaseiOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "ead7bffc9546c1740678a36096282e1a811b7da6"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0")
    ],
    targets: [
        .target(
            name: "GodotFirebaseiOS",
            dependencies: [
                .product(name: "SwiftGodotRuntime", package: "SwiftGodot"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .unsafeFlags([
                    "-suppress-warnings",
                    "-Xfrontend", "-internalize-at-link",
                    "-Xfrontend", "-lto=llvm-full",
                    "-Xfrontend", "-conditional-runtime-records"
                ])
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-dead_strip"])
            ]
        )
    ]
)
