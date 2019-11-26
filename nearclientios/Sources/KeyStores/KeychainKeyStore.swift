//
//  KeychainKeyStore.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 08.11.2019.
//

import Foundation
import PromiseKit
import KeychainAccess

let KEYCHAIN_STORAGE_SERVICE = "nearlib.keystore"

internal struct KeychainKeyStore {
  private let keychain: Keychain

  init(keychain: Keychain = .init(service: KEYCHAIN_STORAGE_SERVICE)) {
    self.keychain = keychain
  }
}

extension KeychainKeyStore: KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void> {
    keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] = keyPair.toString()
    return .value(())
  }

  func getKey(networkId: String, accountId: String) -> Promise<KeyPair?> {
    guard let value = keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] else {
      return .value(nil)
    }
    return .value(try? keyPairFromString(encodedKey: value))
  }

  func removeKey(networkId: String, accountId: String) -> Promise<Void> {
    keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] = nil
    return .value(())
  }

  func clear() -> Promise<Void> {
    try? keychain.removeAll()
    return .value(())
  }

  func getNetworks() throws -> Promise<[String]> {
    var result = Set<String>()
    for key in storageKeys() {
      if let networkId = key.components(separatedBy: ":").last {
        result.insert(networkId)
      }
    }
    return .value(Array(result))
  }

  func getAccounts(networkId: String) throws -> Promise<[String]> {
    var result = [String]()
    for key in storageKeys() {
      let components = key.components(separatedBy: ":")
      if let keychainNetworkId = components.last, keychainNetworkId == networkId, let accountId = components.first {
        result.append(accountId)
      }
    }
    return .value(result)
  }
}

extension KeychainKeyStore {
  private func storageKeyForSecretKey(networkId: String, accountId: String) -> String {
    return "\(accountId):\(networkId)"
  }

  private func storageKeys() -> [String] {
    return keychain.allKeys()
  }
}
