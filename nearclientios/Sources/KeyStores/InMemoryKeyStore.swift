//
//  InMemoryKeyStore.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit

/**
* Simple in-memory keystore for testing purposes.
*/
internal class InMemoryKeyStore {
  private var keys: [String: String]

  init(keys: [String: String] = [:]) {
    self.keys = keys
  }
}

extension InMemoryKeyStore: KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void> {
    keys["\(accountId):\(networkId)"] = keyPair.toString()
    return .value(())
  }

  func getKey(networkId: String, accountId: String) -> Promise<KeyPair?> {
    guard let value = keys["\(accountId):\(networkId)"] else {return .value(nil)}
    return .value(try? keyPairFromString(encodedKey: value))
  }

  func removeKey(networkId: String, accountId: String) -> Promise<Void> {
    keys.removeValue(forKey: "\(accountId):\(networkId)")
    return .value(())
  }

  func clear() -> Promise<Void> {
    keys = [:]
    return .value(())
  }

  func getNetworks() throws -> Promise<[String]> {
    var result = Set<String>()
    keys.keys.forEach {key in
      let parts = key.split(separator: ":")
      result.insert(String(parts[1]))
    }
    return .value(Array(result))
  }

  func getAccounts(networkId: String) throws -> Promise<[String]> {
    var result = [String]()
    keys.keys.forEach {key in
      let parts = key.split(separator: ":").map {String($0)}
      if parts[parts.count - 1] == networkId {
          result.append(parts.dropLast().joined(separator: ":"))
      }
    }
    return .value(result)
  }
}
