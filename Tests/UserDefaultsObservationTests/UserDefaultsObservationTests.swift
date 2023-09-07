import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(UserDefaultsObservationMacros)
import UserDefaultsObservationMacros

let testMacros: [String: Macro.Type] = [
    "ObservableUserDefaults": UserDefaultsObservationMacro.self
]
#endif

final class UserDefaultsObservationTests: XCTestCase {
    func testUserDefaultsObservationMacro() throws {
        #if canImport(UserDefaultsObservationMacros)
        assertMacroExpansion(
            """
class Model {
    @ObservableUserDefaults(key: "username", defaultValue: "Name")
    var name: String
}
""",
            expandedSource: #"""
class Model {
    var name: String {
        get {
            access(keyPath: \.name)
            let store: UserDefaults = .standard
            return (store.value(forKey: "username") as? String) ?? "Name"
        }
        set {
            withMutation(keyPath: \.name) {
                let store: UserDefaults = .standard
                store.set(newValue, forKey: "username")
            }
        }
    }
}
"""#,
            macros: testMacros
        )
        assertMacroExpansion(
            """
class Model {
    @ObservableUserDefaults(key: "value", defaultValue: 1, store: .init(suiteName: "Store")!)
    var val: Int
}
""",
            expandedSource: #"""
class Model {
    var val: Int {
        get {
            access(keyPath: \.val)
            let store: UserDefaults = .init(suiteName: "Store")!
            return (store.value(forKey: "value") as? Int) ?? 1
        }
        set {
            withMutation(keyPath: \.val) {
                let store: UserDefaults = .init(suiteName: "Store")!
                store.set(newValue, forKey: "value")
            }
        }
    }
}
"""#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
