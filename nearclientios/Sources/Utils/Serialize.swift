//
//  Serialize.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import Base58Swift

internal extension String {
  var baseDecoded: [UInt8] {
    return Base58.base58Decode(self) ?? []
  }
}

internal extension Data {
  var baseEncoded: String {
    return Base58.base58Encode(bytes)
  }

  var bytes: [UInt8] {
    return [UInt8](self)
  }
}

internal extension Data {
  var json: [String: Any]? {
    return try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
  }

  init(json: [String: Any]) {
    let data = try? JSONSerialization.data(withJSONObject: json, options: [])
    self.init(bytes: data?.bytes ?? [], count: data?.bytes.count ?? 0)
  }
}

internal extension Collection where Element == UInt8 {
  var baseEncoded: String {
    return data.baseEncoded
  }

  var data: Data {
    return Data(self)
  }
}
