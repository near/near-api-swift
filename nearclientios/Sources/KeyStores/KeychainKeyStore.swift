//
//  KeychainKeyStore.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 08.11.2019.
//

import Foundation
import KeychainAccess

public let NEAR_KEYCHAIN_STORAGE_SERVICE = "near.keystore"

public struct KeychainKeyStore {
  private let keychain: Keychain

  public init(keychain: Keychain = .init(service: NEAR_KEYCHAIN_STORAGE_SERVICE)) {
    self.keychain = keychain
  }
}

extension KeychainKeyStore: KeyStore {
  public func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws -> Void {
    keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] = keyPair.toString()
  }

  public func getKey(networkId: String, accountId: String) async throws -> KeyPair? {
    guard let value = keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] else {
      return nil
    }
    return try? keyPairFromString(encodedKey: value)
  }

  public func removeKey(networkId: String, accountId: String) async throws -> Void {
    keychain[storageKeyForSecretKey(networkId: networkId, accountId: accountId)] = nil
  }

  public func clear() async throws -> Void {
    try? keychain.removeAll()
  }

  public func getNetworks() async throws -> [String] {
    var result = Set<String>()
    for key in storageKeys() {
      if let networkId = key.components(separatedBy: ":").last {
        result.insert(networkId)
      }
    }
    return Array(result)
  }

  public func getAccounts(networkId: String) async throws -> [String] {
    var result = [String]()
    for key in storageKeys() {
      let components = key.components(separatedBy: ":")
      if let keychainNetworkId = components.last, keychainNetworkId == networkId, let accountId = components.first {
        result.append(accountId)
      }
    }
    return result
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
