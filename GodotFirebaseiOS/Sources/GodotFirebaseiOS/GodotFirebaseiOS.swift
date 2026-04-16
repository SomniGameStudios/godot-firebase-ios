import SwiftGodotRuntime

#initSwiftExtension(
    cdecl: "swift_entry_point", 
    types: [
        FirebaseCorePlugin.self,
        FirebaseAuthPlugin.self,
        FirebaseFirestorePlugin.self,
        FirebaseRemoteConfigPlugin.self,
        FirebaseAnalyticsPlugin.self,
        FirebaseCloudMessagingPlugin.self
    ],
    registerDocs: false
)