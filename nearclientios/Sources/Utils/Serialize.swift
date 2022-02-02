//
//  Serialize.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import Base58Swift

public extension String {
  var baseDecoded: [UInt8] {
    return Base58.base58Decode(self) ?? []
  }
}

public extension Data {
  var baseEncoded: String {
    return Base58.base58Encode(bytes)
  }

  var bytes: [UInt8] {
    return [UInt8](self)
  }
}

public extension Data {
  var hexString: String {
      return map { String(format: "%02x", UInt8($0)) }.joined()
  }
}

public extension Data {
  var json: [String: Any]? {
    return try? toDictionary()
  }

  init(json: [String: Any]) {
    let data = try? json.toData()
    self.init(bytes: data?.bytes ?? [], count: data?.bytes.count ?? 0)
  }
}

public extension Sequence where Element == UInt8 {
  var baseEncoded: String {
    return data.baseEncoded
  }

  var data: Data {
    return Data(self)
  }
}

public struct CastingError: Error {
  let fromType: Any.Type
  let toType: Any.Type
  init<FromType, ToType>(fromType: FromType.Type, toType: ToType.Type) {
    self.fromType = fromType
    self.toType = toType
  }
}

extension CastingError: LocalizedError {
  var localizedDescription: String { return "Can not cast from \(fromType) to \(toType)" }
}

extension CastingError: CustomStringConvertible { public var description: String { return localizedDescription } }

public extension Data {
  func toDictionary(options: JSONSerialization.ReadingOptions = []) throws -> [String: Any] {
    return try to(type: [String: Any].self, options: options)
  }

  func to<T>(type: T.Type, options: JSONSerialization.ReadingOptions = []) throws -> T {
    guard let result = try JSONSerialization.jsonObject(with: self, options: options) as? T else {
      throw CastingError(fromType: type, toType: T.self)
    }
    return result
  }
}

public extension String {
  func asJSON<T>(to type: T.Type, using encoding: String.Encoding = .utf8) throws -> T {
    guard let data = data(using: encoding) else { throw CastingError(fromType: type, toType: T.self) }
    return try data.to(type: T.self)
  }

  func asJSONToDictionary(using encoding: String.Encoding = .utf8) throws -> [String: Any] {
    return try asJSON(to: [String: Any].self, using: encoding)
  }
}

internal extension Dictionary {
  func toData(options: JSONSerialization.WritingOptions = []) throws -> Data {
    return try JSONSerialization.data(withJSONObject: self, options: options)
  }
}
