import SwiftGodotRuntime

#initSwiftExtension(
    cdecl: "swift_entry_point", 
    types: [
        FirebaseCorePlugin.self,
        FirebaseAuthPlugin.self,
        FirebaseFirestorePlugin.self
    ],
    registerDocs: false
)