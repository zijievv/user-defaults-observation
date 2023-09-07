import Foundation

@attached(accessor)
public macro ObservableUserDefaults<T>(
    key: String,
    defaultValue: T,
    store: UserDefaults = .standard
) = #externalMacro(module: "UserDefaultsObservationMacros", type: "UserDefaultsObservationMacro")
