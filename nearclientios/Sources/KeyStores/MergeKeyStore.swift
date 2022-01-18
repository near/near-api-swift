//
//  MergeKeyStore.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

/**
 * Keystore which can be used to merge multiple key stores into one virtual key store.
 */
public struct MergeKeyStore {
  /// First keystore gets all write calls, read calls are attempted from start to end of array
  private(set) var keyStores: [KeyStore]

  public init(keyStores: [KeyStore] = []) {
    self.keyStores = keyStores
  }
}

extension MergeKeyStore: KeyStore {
  public func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws -> Void {
    return try await keyStores[0].setKey(networkId: networkId, accountId: accountId, keyPair: keyPair)
  }

  public func getKey(networkId: String, accountId: String) async throws -> KeyPair? {
    for keyStore in keyStores {
      if let keyPair = try await keyStore.getKey(networkId: networkId, accountId: accountId) {
        return keyPair
      }
    }
    return nil
  }

  public func removeKey(networkId: String, accountId: String) async throws -> Void {
    for keyStore in keyStores {
      try await keyStore.removeKey(networkId: networkId, accountId: accountId)
    }
  }

  public func clear() async throws -> Void {
    for keyStore in keyStores {
      try await keyStore.clear()
    }
  }

  public func getNetworks() async throws -> [String] {
    var result = Set<String>()
    for keyStore in keyStores {
      let networks = try await keyStore.getNetworks()
      for network in networks {
        result.insert(network)
      }
    }
    return Array(result)
  }

  public func getAccounts(networkId: String) async throws -> [String] {
    var result = Set<String>()
    for keyStore in keyStores {
      let accounts = try await keyStore.getAccounts(networkId: networkId)
      for account in accounts {
        result.insert(account)
      }
    }
    return Array(result)
  }
}
