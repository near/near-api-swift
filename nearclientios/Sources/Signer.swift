//
//  Signer.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

internal enum SignerType {
  case inMemory(KeyStore)
}

/**
 General signing interface, can be used for in memory signing, RPC singing, external wallet, HSM, etc.
 */
internal protocol Signer {

  /**
   Creates new key and returns public key.
   - Parameters:
      - accountId: accountId to retrieve from.
      - networkId: network for this accountId.
   */
  func createKey(accountId: String, networkId: String) throws -> Promise<PublicKey>

  /**
   - Parameters:
      - accountId: accountId to retrieve from.
      - networkId: network for this accountId.
    - Returns: public key for given account / network.
   */
  func getPublicKey(accountId: String, networkId: String) throws -> Promise<PublicKey?>

  /**
   Signs given hash.
   - Parameters:
      - hash: hash to sign.
      - accountId: accountId to use for signing.
      - networkId: network for this accontId.
   */
  func signHash(hash: [UInt8], accountId: String, networkId: String) throws -> Promise<GeneralSignature>

  /**
   Signs given message, by first hashing with sha256.
   - Parameters:
      - message: message to sign.
      - accountId: accountId to use for signing.
      - networkId: network for this accontId.
   */
  func signMessage(message: [UInt8], accountId: String, networkId: String) throws -> Promise<GeneralSignature>
}

extension Signer {
  func signMessage(message: [UInt8], accountId: String, networkId: String) throws -> Promise<GeneralSignature> {
    return try signHash(hash: message.digest, accountId: accountId, networkId: networkId)
  }
}

/**
 * Signs using in memory key store.
 */
internal struct InMemorySigner {
  let keyStore: KeyStore
}

internal enum InMemorySignerError: Error {
  case notFound(String)
}

extension InMemorySigner: Signer {
  func createKey(accountId: String, networkId: String) throws -> Promise<PublicKey> {
    let keyPair = try keyPairFromRandom(curve: .ED25519)
    try await(keyStore.setKey(networkId: networkId, accountId: accountId, keyPair: keyPair))
    return .value(keyPair.getPublicKey())
  }

  func getPublicKey(accountId: String, networkId: String) throws -> Promise<PublicKey?> {
    let keyPair = keyStore.getKey(networkId: networkId, accountId: accountId)
    return keyPair.map {$0?.getPublicKey()}
  }

  func signHash(hash: [UInt8], accountId: String, networkId: String) throws -> Promise<GeneralSignature> {
    guard let keyPair = try await(keyStore.getKey(networkId: networkId, accountId: accountId)) else {
      throw InMemorySignerError.notFound("Key for \(accountId) not found in \(networkId)")
    }
    let signature = try keyPair.sign(message: hash)
    return .value(signature)
  }
}
