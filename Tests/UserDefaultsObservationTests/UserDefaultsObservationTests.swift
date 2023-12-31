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
    func testUserDefaultsObservationStandardStoreMacro() throws {
        #if canImport(UserDefaultsObservationMacros)
        assertMacroExpansion(
            """
class Model {
    @ObservableUserDefaults(key: "username")
    var name: String = "User"
}
""",
            expandedSource: #"""
class Model {
    var name: String = "User" {
        @storageRestrictions(initializes: _name)
        init(initialValue) {
            _name = initialValue
        }
        get {
            access(keyPath: \.name)
            let store: UserDefaults = .standard
            return (store.value(forKey: "username") as? String) ?? _name
        }
        set {
            withMutation(keyPath: \.name) {
                let store: UserDefaults = .standard
                store.set(newValue, forKey: "username")
            }
        }
    }

    @ObservationIgnored private let _name: String
}
"""#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testUserDefaultsObservationCustomStoreMacro() throws {
        #if canImport(UserDefaultsObservationMacros)
        assertMacroExpansion(
            """
class Model {
    @ObservableUserDefaults(key: "value", store: .init(suiteName: "Store")!)
    var val: Int = 1
}
""",
            expandedSource: #"""
class Model {
    var val: Int = 1 {
        @storageRestrictions(initializes: _val)
        init(initialValue) {
            _val = initialValue
        }
        get {
            access(keyPath: \.val)
            let store: UserDefaults = .init(suiteName: "Store")!
            return (store.value(forKey: "value") as? Int) ?? _val
        }
        set {
            withMutation(keyPath: \.val) {
                let store: UserDefaults = .init(suiteName: "Store")!
                store.set(newValue, forKey: "value")
            }
        }
    }

    @ObservationIgnored private let _val: Int
}
"""#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
