//
//  SHA256.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import CommonCrypto

public extension Collection where Element == UInt8 {
  var digest: [UInt8] {
    var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(count), &result)
    }
    return result
  }
}
