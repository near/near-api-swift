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
}

extension MergeKeyStore: KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void> {
    keyStores[0].setKey(networkId: networkId, accountId: accountId, keyPair: keyPair)
  }

  func getKey(networkId: String, accountId: String) -> Promise<KeyPair?> {
    for keyStore in keyStores {
      let keyPair = try? await(keyStore.getKey(networkId: networkId, accountId: accountId))
      if keyPair != nil {
        return .value(keyPair)
      }
    }
    return .value(nil)
  }

  func removeKey(networkId: String, accountId: String) -> Promise<Void> {
    async {
      for keyStore in self.keyStores {
        try await(keyStore.removeKey(networkId: networkId, accountId: accountId))
      }
    }
    return .value(())
  }

  func clear() -> Promise<Void> {
    async {
      for keyStore in self.keyStores {
        try await(keyStore.clear())
      }
    }
    return .value(())
  }

  func getNetworks() -> Promise<[String]> {
    var result = Set<String>()
    async {
      for keyStore in self.keyStores {
        for network in try await(keyStore.getNetworks()) {
          result.insert(network)
        }
      }
    }
    return .value(Array(result))
  }

  func getAccounts(networkId: String) -> Promise<[String]> {
    var result = Set<String>()
    async {
      for keyStore in self.keyStores {
        for account in try await(keyStore.getAccounts(networkId: networkId)) {
          result.insert(account)
        }
      }
    }
    return .value(Array(result))
  }
}
