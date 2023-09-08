import Foundation

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro ObservableUserDefaults(key: String, store: UserDefaults = .standard) = #externalMacro(
    module: "UserDefaultsObservationMacros", 
    type: "UserDefaultsObservationMacro"
)
