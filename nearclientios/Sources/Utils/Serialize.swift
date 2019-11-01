//
//  Serialize.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

internal extension String {
  var baseDecoded: [UInt8] {
    return []
  }
}

internal extension Data {
  var baseEncoded: String {
    return String(data: self, encoding: .utf8) ?? ""
  }

  var bytes: [UInt8] {
    return [UInt8](self)
  }
}

internal extension Collection where Element == UInt8 {
  var baseEncoded: String {
    return String(bytes: self, encoding: .utf8) ?? ""
  }

  var data: Data {
    var values = self
    return Data(bytes: &values, count: self.count)
  }
}
