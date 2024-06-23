//
//  UserDefaults+Codable.swift
//
//
//  Created by winddpan on 2024/4/18.
//

import Foundation

extension UserDefaults {
    @_disfavoredOverload
    public func _$observationGet<T>(_ type: T.Type, forKey key: String) -> T? {
        value(forKey: key) as? T
    }

    public func _$observationGet<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let anyValue = value(forKey: key)
        return if let valueT = anyValue as? T {
            valueT
        } else if let data = anyValue as? Data {
            try? JSONDecoder().decode(type, from: data)
        } else {
            nil
        }
    }

    @_disfavoredOverload
    public func _$observationSet(_ value: Any?, forKey key: String) {
        set(value, forKey: key)
    }

    public func _$observationSet<T: Codable>(_ value: T?, forKey key: String) {
        guard let value else {
            set(nil, forKey: key)
            return
        }
        switch T.self {
        case is Int.Type, is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type,
            is UInt.Type, is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type,
            is Float.Type, is Double.Type, is String.Type, is Data.Type, is Date.Type, is Bool.Type, is URL.Type,
            is [Int].Type, is [Double].Type, is [Date].Type, is [URL].Type, is [String].Type:
            set(value, forKey: key)
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try? encoder.encode(value)
            set(data, forKey: key)
        }
    }
}
