//
//  Signer.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public enum SignerType {
  case inMemory(KeyStore)
}

/**
 General signing interface, can be used for in memory signing, RPC singing, external wallet, HSM, etc.
 */
public protocol Signer {

  /**
   Creates new key and returns public key.
   - Parameters:
      - accountId: accountId to retrieve from.
      - networkId: network for this accountId.
   */
  func createKey(accountId: String, networkId: String, curve: KeyType) async throws -> PublicKey

  /**
   - Parameters:
      - accountId: accountId to retrieve from.
      - networkId: network for this accountId.
    - Returns: public key for given account / network.
   */
  func getPublicKey(accountId: String, networkId: String) async throws -> PublicKey?

  /**
   Signs given hash.
   - Parameters:
      - hash: hash to sign.
      - accountId: accountId to use for signing.
      - networkId: network for this accontId.
   */
  func signHash(hash: [UInt8], accountId: String, networkId: String) async throws -> SignatureProtocol

  /**
   Signs given message, by first hashing with sha256.
   - Parameters:
      - message: message to sign.
      - accountId: accountId to use for signing.
      - networkId: network for this accontId.
   */
  func signMessage(message: [UInt8], accountId: String, networkId: String) async throws -> SignatureProtocol
}

extension Signer {
  public func signMessage(message: [UInt8], accountId: String, networkId: String) async throws -> SignatureProtocol {
    return try await signHash(hash: message.digest, accountId: accountId, networkId: networkId)
  }
}

/**
 * Signs using in memory key store.
 */
public struct InMemorySigner {
  let keyStore: KeyStore

  public init(keyStore: KeyStore) {
    self.keyStore = keyStore
  }
}

public enum InMemorySignerError: Error {
  case notFound(String)
}

extension InMemorySigner: Signer {
  public func createKey(accountId: String, networkId: String, curve: KeyType = .ED25519) async throws -> PublicKey {
    let keyPair = try keyPairFromRandom(curve: curve)
    try await keyStore.setKey(networkId: networkId, accountId: accountId, keyPair: keyPair)
    return keyPair.getPublicKey()
  }

  public func getPublicKey(accountId: String, networkId: String) async throws -> PublicKey? {
    let keyPair = try await keyStore.getKey(networkId: networkId, accountId: accountId)
    return keyPair?.getPublicKey()
  }

  public func signHash(hash: [UInt8], accountId: String, networkId: String) async throws -> SignatureProtocol {
    guard let keyPair = try await keyStore.getKey(networkId: networkId, accountId: accountId) else {
      throw InMemorySignerError.notFound("Key for \(accountId) not found in \(networkId)")
    }
    let signature = try keyPair.sign(message: hash)
    return signature
  }
}
