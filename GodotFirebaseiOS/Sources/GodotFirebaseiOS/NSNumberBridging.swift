import Foundation
import SwiftGodotRuntime

/// Shared NSNumber handling for the Firebase read paths.
///
/// The Firebase SDKs return every numeric value as NSNumber, and NSNumber 0 and 1
/// pass an `as Bool` cast through Swift's bridging, so integer (and double) fields
/// holding 0 or 1 silently change type on read. Only a genuine CFBoolean is a
/// boolean; any other NSNumber is numeric, keyed off its objCType ("f" and "d"
/// are floating point, everything else integral). Checking objCType alone is not
/// enough on arm64, where __NSCFBoolean reports "c".
enum NSNumberBridging {
    static func toAny(_ n: NSNumber) -> Any {
        if CFGetTypeID(n as CFTypeRef) == CFBooleanGetTypeID() {
            return n.boolValue
        }
        switch String(cString: n.objCType) {
        case "f", "d":
            return n.doubleValue
        default:
            return Int(truncating: n)
        }
    }

    static func toVariant(_ n: NSNumber) -> Variant {
        if CFGetTypeID(n as CFTypeRef) == CFBooleanGetTypeID() {
            return Variant(n.boolValue)
        }
        switch String(cString: n.objCType) {
        case "f", "d":
            return Variant(n.doubleValue)
        default:
            return Variant(Int(truncating: n))
        }
    }
}
