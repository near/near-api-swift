//
//  KeyPair.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import TweetNacl

internal protocol GeneralSignature {
  var signature: [UInt8] {get}
  var publicKey: PublicKey {get}
}

internal struct Signature: GeneralSignature {
  let signature: [UInt8]
  let publicKey: PublicKey
}

/** All supported key types */
internal enum KeyType: String {
    case ED25519 = "ed25519"
}

internal enum PublicKeyDecodeError: Error {
  case invalidKeyFormat(String)
  case unknowKeyType
}

/**
 * PublicKey representation that has type and bytes of the key.
 */
internal struct PublicKey {
  private let keyType: KeyType
  internal let data: [UInt8]

  init(keyType: KeyType, data: [UInt8]) {
    self.keyType = keyType
    self.data = data
  }

  static func fromString(encodedKey: String) throws -> PublicKey {
    let parts = encodedKey.split(separator: ":").map {String($0)}
    if parts.count == 1 {
      return PublicKey(keyType: .ED25519, data: parts[0].baseDecoded)
    } else if parts.count == 2 {
      guard let keyType = KeyType(rawValue: parts[0]) else {throw PublicKeyDecodeError.unknowKeyType}
      return PublicKey(keyType: keyType, data: parts[1].baseDecoded)
    } else {
      throw PublicKeyDecodeError.invalidKeyFormat("Invlaid encoded key format, must be <curve>:<encoded key>")
    }
  }

  func toString() -> String {
    return "\(keyType):\(data.baseEncoded)"
  }
}

extension PublicKey: Codable {
  //TODO: implement
  func encode(to encoder: Encoder) throws {

  }

  init(from decoder: Decoder) throws {

  }
}

internal enum KeyPairDecodeError: Error {
  case invalidKeyFormat(String)
  case unknowCurve(String)
}

internal protocol KeyPair {
  func sign(message: [UInt8]) throws -> GeneralSignature
//  func verify(message: Uint8Array, signature: Uint8Array) -> Bool
  func toString() -> String
  func getPublicKey() -> PublicKey
}

func keyPairFromRandom(curve: KeyType) throws -> KeyPair{
  switch curve {
  case .ED25519: return try KeyPairEd25519.fromRandom()
  }
}

func keyPairFromString(encodedKey: String) throws -> KeyPair {
  let parts = encodedKey.split(separator: ":").map {String($0)}
  if parts.count == 1 {
    return try KeyPairEd25519(secretKey: parts[0])
  } else if parts.count == 2 {
    guard let curve = KeyType(rawValue: parts[0]) else {
      throw KeyPairDecodeError.unknowCurve("Unknown curve: \(parts[0])")
    }
    switch curve {
    case .ED25519: return try KeyPairEd25519(secretKey: parts[1])
    }
  } else {
    throw KeyPairDecodeError.invalidKeyFormat("Invalid encoded key format, must be <curve>:<encoded key>")
  }
}

/**
* This struct provides key pair functionality for Ed25519 curve:
* generating key pairs, encoding key pairs, signing and verifying.
*/
internal struct KeyPairEd25519 {
  private let publicKey: PublicKey
  private let secretKey: String

  /**
   * Construct an instance of key pair given a secret key.
   * It's generally assumed that these are encoded in base58.
   * - Parameter secretKey: SecretKey to be used for KeyPair
   */
  init(secretKey: String) throws {
    let keyPair = try NaclSign.KeyPair.keyPair(fromSecretKey: secretKey.baseDecoded.data)
    self.publicKey = PublicKey(keyType: .ED25519, data: keyPair.publicKey.bytes);
    self.secretKey = secretKey;
  }

  /**
   Generate a new random keypair.
   ```
   let keyRandom = KeyPair.fromRandom()
   keyRandom.publicKey
      - Returns: publicKey
   ```
   ```
   let keyRandom = KeyPair.fromRandom()
   keyRandom.secretKey
      - Returns: secretKey
   ```
   */
  static func fromRandom() throws -> Self {
    let newKeyPair = try NaclSign.KeyPair.keyPair()
    return try KeyPairEd25519(secretKey: newKeyPair.secretKey.baseEncoded)
  }
}

extension KeyPairEd25519: KeyPair {
  func sign(message: [UInt8]) throws -> GeneralSignature {
    let signature = try NaclSign.signDetached(message: message.data, secretKey: secretKey.baseDecoded.data)
    return Signature(signature: signature.bytes, publicKey: publicKey)
  }

  func verify(message: [UInt8], signature: [UInt8]) throws -> Bool {
    return try NaclSign.signDetachedVerify(message: message.data, sig: signature.data, publicKey: publicKey.data.data)
  }

  func toString() -> String {
    return "ed25519:\(secretKey)"
  }

  func getPublicKey() -> PublicKey {
    return publicKey
  }
}
