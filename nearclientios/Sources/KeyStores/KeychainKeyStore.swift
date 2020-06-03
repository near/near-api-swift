//
//  KeychainKeyStore.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 08.11.2019.
//

import Foundation
import PromiseKit
import KeychainAccess

public let NEAR_KEYCHAIN_STORAGE_SERVICE = "near.keystore"

public struct KeychainKeyStore {
  private let keychain: Keychain

  public init(keychain: Keychain = .init(service: NEAR_KEYCHAIN_STORAGE_SERVICE)) {
    self.keychain = keychain
  }
}

extension KeychainKeyStore: KeyStore {
  public func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void> {
    keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] = keyPair.toString()
    return .value(())
  }

  public func getKey(networkId: String, accountId: String) -> Promise<KeyPair?> {
    guard let value = keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] else {
      return .value(nil)
    }
    return .value(try? keyPairFromString(encodedKey: value))
  }

  public func removeKey(networkId: String, accountId: String) -> Promise<Void> {
    keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] = nil
    return .value(())
  }

  public func clear() -> Promise<Void> {
    try? keychain.removeAll()
    return .value(())
  }

  public func getNetworks() throws -> Promise<[String]> {
    var result = Set<String>()
    for key in storageKeys() {
      if let networkId = key.components(separatedBy: ":").last {
        result.insert(networkId)
      }
    }
    return .value(Array(result))
  }

  public func getAccounts(networkId: String) throws -> Promise<[String]> {
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
