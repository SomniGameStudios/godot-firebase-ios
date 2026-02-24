@preconcurrency import SwiftGodotRuntime
import FirebaseCore

@Godot
class FirebaseCorePlugin: RefCounted, @unchecked Sendable {
    @Signal var firebase_initialized: SimpleSignal
    @Signal("message") var firebase_error: SignalWithArguments<String>

    private var isInitialized = false

    @Callable
    func initialize() {
        guard !isInitialized else { return }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            firebase_error.emit("GoogleService-Info.plist not found in app bundle. Add it to the Xcode project target.")
            return
        }
        FirebaseApp.configure(options: options)
        isInitialized = true
        firebase_initialized.emit()
    }

    @Callable
    func is_initialized() -> Bool {
        return isInitialized
    }
}
