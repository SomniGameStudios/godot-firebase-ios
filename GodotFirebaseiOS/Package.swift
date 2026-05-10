// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "GodotFirebaseiOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GodotFirebaseiOS", type: .dynamic, targets: ["GodotFirebaseiOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "d54c377787fbf9276712de25e1fcd7b709d6bba9"),
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
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            swiftSettings: [
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
