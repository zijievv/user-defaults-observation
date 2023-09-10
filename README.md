# UserDefaultsObservation

`ObservableUserDefaults` is a Swift macro adding accessors to properties for reading/writing values in `UserDefaults` within `Observable` classes.

## Usage

Source code:

```swift
import Foundation
import Observation
import UserDefaultsObservation

@Observable
class Model {
    @ObservableUserDefaults(key: "text", store: Self.store)
    @ObservationIgnored
    var text: String = "Text"

    @ObservableUserDefaults(key: "value")
    @ObservationIgnored
    var value: Int = 1

    static let store = UserDefaults(suiteName: "Store")!
}
```

Expanded source:

```swift
import Foundation
import Observation
import UserDefaultsObservation

@Observable
class Model {
    @ObservationIgnored
    var text: String {
        @storageRestrictions(initializes: _text)
        init(initialValue) {
            _text = initialValue
        }
        get {
            access(keyPath: \.text)
            let store: UserDefaults = Self.store
            return (store.value(forKey: "text") as? String) ?? _text
        }
        set {
            withMutation(keyPath: \.text) {
                let store: UserDefaults = Self.store
                store.set(newValue, forKey: "text")
            }
        }
    }
    
    @ObservationIgnored private let _text: String

    @ObservationIgnored
    var value: Int = 1 {
        @storageRestrictions(initializes: _value)
        init(initialValue) {
            _value = initialValue
        }
        get {
            access(keyPath: \.value)
            let store: UserDefaults = .standard
            return (store.value(forKey: "value") as? Int) ?? _value
        }
        set {
            withMutation(keyPath: \.value) {
                let store: UserDefaults = .standard
                store.set(newValue, forKey: "value")
            }
        }
    }
    
    @ObservationIgnored private let _value: Int

    static let store = UserDefaults(suiteName: "Store")!
}
```

⚠️ Note that when you use the `@ObservableUserDefaults(key:store:)` macro, you need to add the `@ObservationIgnored` macro to the property. Otherwise, `@Observable` will generate accessors that conflict with `ObservableUserDefaults`.

## Installation

### [Swift Package Manager](https://www.swift.org/package-manager/) (SPM)

Add the following line to the dependencies in `Package.swift`, to use the `ObservableUserDefaults` macro in a SPM project:

```swift
.package(url: "https://github.com/zijievv/user-defaults-observation", from: "0.1.0"),
```

In your target:

```swift
.target(name: "<TARGET_NAME>", dependencies: [
    .product(name: "UserDefaultsObservation", package: "user-defaults-observation"),
    // ...
]),
```

Add `import UserDefaultsObservation` into your source code to use the `ObservableUserDefaults` macro.

### Xcode

Go to `File > Add Package Dependencies...` and paste the repo's URL:

```
https://github.com/zijievv/user-defaults-observation
```
