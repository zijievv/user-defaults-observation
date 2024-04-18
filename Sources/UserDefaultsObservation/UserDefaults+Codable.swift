//
//  UserDefaults+Codable.swift
//
//
//  Created by winddpan on 2024/4/18.
//

import Foundation

public extension UserDefaults {
    @_disfavoredOverload
    func _$observationGet<T>(_ type: T.Type, forKey key: String) -> T? {
        value(forKey: key) as? T
    }

    func _$observationGet<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        if [Int.self, Float.self, Double.self, Bool.self, URL.self].contains(where: { type == $0 }) {
            return value(forKey: key) as? T
        }
        if let data = value(forKey: key) as? Data {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }

    @_disfavoredOverload
    func _$observationSet(_ value: Any?, forKey key: String) {
        set(value, forKey: key)
    }

    func _$observationSet<T: Codable>(_ value: T?, forKey key: String) {
        guard let value else {
            set(nil, forKey: key)
            return
        }
        if [Int.self, Float.self, Double.self, Bool.self, URL.self].contains(where: { T.self == $0 }) {
            set(value, forKey: key)
        } else {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try? encoder.encode(value)
            set(data, forKey: key)
        }
    }
}
