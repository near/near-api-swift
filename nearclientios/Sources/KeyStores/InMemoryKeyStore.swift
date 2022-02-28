//
//  InMemoryKeyStore.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

/**
* Simple in-memory keystore for testing purposes.
*/
public class InMemoryKeyStore {
  private var keys: [String: String]

  public init(keys: [String: String] = [:]) {
    self.keys = keys
  }
}

extension InMemoryKeyStore: KeyStore {
  public func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws -> Void {
    keys["\(accountId):\(networkId)"] = keyPair.toString()
  }

  public func getKey(networkId: String, accountId: String) async throws -> KeyPair? {
    guard let value = keys["\(accountId):\(networkId)"] else {return nil}
    return try? keyPairFromString(encodedKey: value)
  }

  public func removeKey(networkId: String, accountId: String) async throws -> Void {
    keys.removeValue(forKey: "\(accountId):\(networkId)")
  }

  public func clear() async throws -> Void {
    keys = [:]
  }

  public func getNetworks() async throws -> [String] {
    var result = Set<String>()
    keys.keys.forEach {key in
      let parts = key.split(separator: ":")
      result.insert(String(parts[1]))
    }
    return Array(result)
  }

  public func getAccounts(networkId: String) async throws -> [String] {
    var result = [String]()
    keys.keys.forEach {key in
      let parts = key.split(separator: ":").map {String($0)}
      if parts[parts.count - 1] == networkId {
          result.append(parts.dropLast().joined(separator: ":"))
      }
    }
    return result
  }
}
