//
//  MergeKeyStore.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

/**
 * Keystore which can be used to merge multiple key stores into one virtual key store.
 */
internal struct MergeKeyStore {
  /// First keystore gets all write calls, read calls are attempted from start to end of array
  private(set) var keyStores: [KeyStore]

  init(keyStores: [KeyStore] = []) {
    self.keyStores = keyStores
  }
}

extension MergeKeyStore: KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void> {
    return keyStores[0].setKey(networkId: networkId, accountId: accountId, keyPair: keyPair)
  }

  func getKey(networkId: String, accountId: String) -> Promise<KeyPair?> {
    for keyStore in keyStores {
      if let keyPair = try! await(keyStore.getKey(networkId: networkId, accountId: accountId)) {
        return .value(keyPair)
      }
    }
    return .value(nil)
  }

  func removeKey(networkId: String, accountId: String) -> Promise<Void> {
    let promises = keyStores.map { $0.removeKey(networkId: networkId, accountId: accountId) }
    return when(resolved: promises).asVoid()
  }

  func clear() -> Promise<Void> {
    let promises = keyStores.map { $0.clear() }
    return when(resolved: promises).asVoid()
  }

  func getNetworks() throws -> Promise<[String]> {
    var result = Set<String>()
    for keyStore in keyStores {
      let networks = try await(keyStore.getNetworks())
      for network in networks {
        result.insert(network)
      }
    }
    return .value(Array(result))
  }

  func getAccounts(networkId: String) throws -> Promise<[String]> {
    var result = Set<String>()
    for keyStore in keyStores {
      let accounts = try await(keyStore.getAccounts(networkId: networkId))
      for account in accounts {
        result.insert(account)
      }
    }
    return .value(Array(result))
  }
}
