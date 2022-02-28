//
//  KeyPair.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import TweetNacl
import secp256k1

public protocol SignatureProtocol {
  var signature: [UInt8] {get}
  var publicKey: PublicKey {get}
}

public struct Signature: SignatureProtocol {
  public let signature: [UInt8]
  public let publicKey: PublicKey
}

/** All supported key types */
public enum KeyType: String, Codable, Equatable, BorshCodable {
  case ED25519 = "ed25519"
  case SECP256k1 = "secp256k1"

  public func serialize(to writer: inout Data) throws {
    switch self {
    case .ED25519: return try UInt8(0).serialize(to: &writer)
    case .SECP256k1: return try UInt8(1).serialize(to: &writer)
    }
  }

  public init(from reader: inout BinaryReader) throws {
    let value = try UInt8(from: &reader)
    switch value {
    case 0: self = .ED25519
    case 1: self = .SECP256k1
    default: throw BorshDecodingError.unknownData
    }
  }
}

public enum PublicKeyDecodeError: Error {
  case invalidKeyFormat(String)
  case unknowKeyType
}

/**
 * PublicKey representation that has type and bytes of the key.
 */
public struct PublicKey: Decodable, Equatable {
  public let keyType: KeyType
  public let data: [UInt8]

  public init(keyType: KeyType, data: [UInt8]) {
    self.keyType = keyType
    self.data = data
  }
  
  func bytes() -> [UInt8] {
    switch keyType {
    case .ED25519:
      return data
    case .SECP256k1:
       // inject the first byte back into the data, it will always be 0x04 since we always use SECP256K1_EC_UNCOMPRESSED
      var modifiedBytes = data
      modifiedBytes.insert(0x04, at: 0)
      return modifiedBytes
    }
  }

  public static func fromString(encodedKey: String) throws -> PublicKey {
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

  public func toString() -> String {
    return "\(keyType.rawValue):\(data.baseEncoded)"
  }
}

extension PublicKey: BorshCodable {

  public func serialize(to writer: inout Data) throws {
    try keyType.serialize(to: &writer)
    writer.append(data, count: Int(keyType == .ED25519 ? 32 : 64))
  }

  public init(from reader: inout BinaryReader) throws {
    self.keyType = try .init(from: &reader)
    self.data = reader.read(count: keyType == .ED25519 ? 32 : 64)
  }
}

public enum KeyPairDecodeError: Error {
  case invalidKeyFormat(String)
  case unknowCurve(String)
}

public protocol KeyPair {
  func sign(message: [UInt8]) throws -> SignatureProtocol
  func verify(message: [UInt8], signature: [UInt8]) throws -> Bool
  func toString() -> String
  func getPublicKey() -> PublicKey
}

func keyPairFromRandom(curve: KeyType = .ED25519) throws -> KeyPair{
  switch curve {
  case .ED25519: return try KeyPairEd25519.fromRandom()
  case .SECP256k1: return try KeyPairSecp256k1.fromRandom()
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
    case .SECP256k1: return try KeyPairSecp256k1(secretKey: parts[1])
    }
  } else {
    throw KeyPairDecodeError.invalidKeyFormat("Invalid encoded key format, must be <curve>:<encoded key>")
  }
}

/**
* This struct provides key pair functionality for Ed25519 curve:
* generating key pairs, encoding key pairs, signing and verifying.
*/
public struct KeyPairEd25519: Equatable {
  private let publicKey: PublicKey
  private let secretKey: String

  /**
   * Construct an instance of key pair given a secret key.
   * It's generally assumed that these are encoded in base58.
   * - Parameter secretKey: SecretKey to be used for KeyPair
   */
  public init(secretKey: String) throws {
    let keyPair = try NaclSign.KeyPair.keyPair(fromSecretKey: secretKey.baseDecoded.data)
    self.publicKey = PublicKey(keyType: .ED25519, data: keyPair.publicKey.bytes)
    self.secretKey = secretKey
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
  public static func fromRandom() throws -> Self {
    let newKeyPair = try NaclSign.KeyPair.keyPair()
    return try KeyPairEd25519(secretKey: newKeyPair.secretKey.baseEncoded)
  }
}

extension KeyPairEd25519: KeyPair {
  public func sign(message: [UInt8]) throws -> SignatureProtocol {
    let signature = try NaclSign.signDetached(message: message.data, secretKey: secretKey.baseDecoded.data)
    return Signature(signature: signature.bytes, publicKey: publicKey)
  }

  public func verify(message: [UInt8], signature: [UInt8]) throws -> Bool {
    return try NaclSign.signDetachedVerify(message: message.data, sig: signature.data, publicKey: publicKey.bytes().data)
  }

  public func toString() -> String {
    return "ed25519:\(secretKey)"
  }

  public func getPublicKey() -> PublicKey {
    return publicKey
  }

  func getSecretKey() -> String {
    return secretKey
  }
}

public enum Secp256k1Error: Error {
  case badContext(String)
  case invalidPrivateKey(String)
  case invalidPublicKey(String)
  case invalidSignature(String)
  case signatureFailure(String)
  case unknownError
}

/**
* This struct provides key pair functionality for secp256k1 curve:
* generating key pairs, encoding key pairs, signing and verifying.
*/
public struct KeyPairSecp256k1: Equatable {
  private let publicKey: PublicKey
  private let secretKey: String

  /**
   * Construct an instance of key pair given a secret key.
   * It's generally assumed that these are encoded in base58.
   * - Parameter secretKey: SecretKey to be used for KeyPair
   */
  public init(secretKey: String) throws {
    let privateKey = secretKey.baseDecoded.data
    // this is largely based on the MIT Licensed implementation here — https://github.com/argentlabs/web3.swift/blob/04c10ec83861ee483efabb72850d51573cfa2545/web3swift/src/Utils/KeyUtil.swift

    guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
      throw Secp256k1Error.badContext("Unable to generate secp256k1 key, bad context")
    }
    
    defer {
      secp256k1_context_destroy(context)
    }
    
    let privateKeyPointer = (privateKey as NSData).bytes.assumingMemoryBound(to: UInt8.self)
    guard secp256k1_ec_seckey_verify(context, privateKeyPointer) == 1 else {
        throw Secp256k1Error.invalidPrivateKey("Unable to generate secp256k1 key, invalid private key")
    }
    
    let publicKeyPointer = UnsafeMutablePointer<secp256k1_pubkey>.allocate(capacity: 1)
    defer {
        publicKeyPointer.deallocate()
    }
  
    guard secp256k1_ec_pubkey_create(context, publicKeyPointer, privateKeyPointer) == 1 else {
        throw Secp256k1Error.unknownError
    }
    
    var publicKeyLength = 65
    let outputPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: publicKeyLength)
    defer {
        outputPointer.deallocate()
    }
    secp256k1_ec_pubkey_serialize(context, outputPointer, &publicKeyLength, publicKeyPointer, UInt32(SECP256K1_EC_UNCOMPRESSED))
    
    // drop the first byte of the data, it will always be 0x04 since we always use SECP256K1_EC_UNCOMPRESSED
    let publicKey = Data(bytes: outputPointer, count: publicKeyLength).subdata(in: 1..<publicKeyLength)
    
    self.publicKey = PublicKey(keyType: .SECP256k1, data: publicKey.bytes)
    self.secretKey = secretKey
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
  public static func fromRandom() throws -> Self {
    let newKeyPair = try NaclSign.KeyPair.keyPair()
    return try KeyPairSecp256k1(secretKey: newKeyPair.secretKey.baseEncoded)
  }
}

extension KeyPairSecp256k1: KeyPair {
  public func sign(message: [UInt8]) throws -> SignatureProtocol {
    // this is largely based on the MIT Licensed implementation here — https://github.com/argentlabs/web3.swift/blob/04c10ec83861ee483efabb72850d51573cfa2545/web3swift/src/Utils/KeyUtil.swift
    guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
      throw Secp256k1Error.badContext("Unable to sign secp256k1 message, bad context")
    }
    
    defer {
      secp256k1_context_destroy(context)
    }
    
    let messagePointer = (message.data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
    let privateKeyPointer = (secretKey.baseDecoded.data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
    let signaturePointer = UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>.allocate(capacity: 1)
    defer {
      signaturePointer.deallocate()
    }
    guard secp256k1_ecdsa_sign_recoverable(context, signaturePointer, messagePointer, privateKeyPointer, nil, nil) == 1 else {
      throw Secp256k1Error.signatureFailure("Failed to sign message: recoverable ECDSA signature creation failed.")
    }
    
    let outputPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    defer {
      outputPointer.deallocate()
    }
    var recid: Int32 = 0
    secp256k1_ecdsa_recoverable_signature_serialize_compact(context, outputPointer, &recid, signaturePointer)
    
    let outputWithRecidPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 65)
    defer {
      outputWithRecidPointer.deallocate()
    }
    outputWithRecidPointer.assign(from: outputPointer, count: 64)
    outputWithRecidPointer.advanced(by: 64).pointee = UInt8(recid)
    
    let signature = Data(bytes: outputWithRecidPointer, count: 65)
    
    return Signature(signature: signature.bytes, publicKey: publicKey)
  }

  public func verify(message: [UInt8], signature: [UInt8]) throws -> Bool {
    guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
      throw Secp256k1Error.badContext("Unable to verify secp256k1 message, bad context")
    }
    
    defer {
      secp256k1_context_destroy(context)
    }
    let messagePointer = (message.data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
    let signaturePointer = (signature.data as NSData).bytes.assumingMemoryBound(to: UInt8.self)

    let publicKeyPointer = UnsafeMutablePointer<secp256k1_pubkey>.allocate(capacity: 1)
    defer {
        publicKeyPointer.deallocate()
    }
    let publicKeyBytes = publicKey.bytes()
    guard secp256k1_ec_pubkey_parse(context, publicKeyPointer, publicKeyBytes, publicKeyBytes.count) == 1 else {
      throw Secp256k1Error.invalidPublicKey("Unable to verify secp256k1 message, invalid public key")
    }
    var signatureOutput = secp256k1_ecdsa_signature()
    guard secp256k1_ecdsa_signature_parse_compact(context, &signatureOutput, signaturePointer) == 1 else {
      throw Secp256k1Error.invalidSignature("Unable to verify secp256k1 message, invalid signature")
    }

    return secp256k1_ecdsa_verify(context, &signatureOutput, messagePointer, publicKeyPointer) != 0
  }

  public func toString() -> String {
    return "secp256k1:\(secretKey)"
  }

  public func getPublicKey() -> PublicKey {
    return publicKey
  }

  func getSecretKey() -> String {
    return secretKey
  }
}
