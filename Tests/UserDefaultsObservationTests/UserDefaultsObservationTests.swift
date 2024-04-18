import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import UserDefaultsObservation
import XCTest

#if canImport(UserDefaultsObservationMacros)
import UserDefaultsObservationMacros

let testMacros: [String: Macro.Type] = [
    "ObservableUserDefaults": UserDefaultsObservationMacro.self,
]
#endif

@Observable
class TestModel {
    @ObservableUserDefaults(key: "username")
    @ObservationIgnored
    var name: String = ""
}

final class UserDefaultsObservationTests: XCTestCase {
    func testUserDefaults() {
        struct Item: Codable {
            let name: String
        }

        let item = Item(name: "name")
        UserDefaults.standard._$observationSet(item, forKey: "item")
        let get = UserDefaults.standard._$observationGet(Item.self, forKey: "item")
        XCTAssertEqual(item.name, get?.name)
    }

    func testUsage() {
        let test1 = TestModel()
        test1.name = "hello world"

        let test2 = TestModel()
        XCTAssertEqual(test2.name, "hello world")
    }

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
                        return store._$observationGet(String.self, forKey: "username") ?? _name
                    }
                    set {
                        withMutation(keyPath: \.name) {
                            let store: UserDefaults = .standard
                            store._$observationSet(newValue, forKey: "username")
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
                        return store._$observationGet(Int.self, forKey: "value") ?? _val
                    }
                    set {
                        withMutation(keyPath: \.val) {
                            let store: UserDefaults = .init(suiteName: "Store")!
                            store._$observationSet(newValue, forKey: "value")
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
