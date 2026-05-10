import SwiftGodotRuntime

#initSwiftExtension(
    cdecl: "swift_entry_point", 
    types: [
        FirebaseCorePlugin.self,
        FirebaseAuthPlugin.self,
        FirebaseFirestorePlugin.self,
        FirebaseDatabasePlugin.self,
        FirebaseRemoteConfigPlugin.self,
        FirebaseAnalyticsPlugin.self
    ],
    registerDocs: false
)