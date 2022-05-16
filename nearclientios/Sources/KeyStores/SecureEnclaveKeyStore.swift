//
//  SecureEnclaveKeyStore.swift
//  nearclientios
//
//  Created by Kevin McConnaughay on 4/1/22.
//

import Foundation
import CryptoKit
import LocalAuthentication
import KeychainAccess

private let algorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM

private enum SecureEnclaveKeyStoreError: Error {
  case cannotAccessPrivateKey(osStatus: OSStatus)
  case cannotAccessPublicKey
  case encryptionNotSupported(algorithm: SecKeyAlgorithm)
  case decryptionNotSupported(algorithm: SecKeyAlgorithm)
  case cannotDeleteKeys(osStatus: OSStatus)
  case unexpected(description: String)
  
  var errorDescription: String {
    switch self {
    case .cannotAccessPrivateKey(let osStatus):
      return "Cannot access private key: \(osStatus)"
    case .cannotAccessPublicKey:
      return "Cannot access public key"
    case .encryptionNotSupported(let algorithm):
      return "Encryption not supported: \(algorithm)"
    case .decryptionNotSupported(let algorithm):
      return "Decryption not supported: \(algorithm)"
    case .cannotDeleteKeys(let osStatus):
      return "Cannot delete key: \(osStatus)"
    case .unexpected(let description):
      return description
    }
  }
}

public class SecureEnclaveKeyStore {
  public let keychain: Keychain
  public let keychainKeyStore: KeychainKeyStore
  /// Ignored and forced to false on simulators.
  let requireUserPresence: Bool
  public var context: LAContext?

  public init(keychain: Keychain = .init(service: NEAR_KEYCHAIN_STORAGE_SERVICE), requireUserPresence: Bool = true) {
    var userPresence = requireUserPresence
    #if targetEnvironment(simulator)
    userPresence = false
    #endif
    self.keychain = keychain
    self.keychainKeyStore = .init(keychain: keychain)
    self.requireUserPresence = userPresence
  }
}

extension SecureEnclaveKeyStore: KeyStore {
  public func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws -> Void {
    let storageKey = storageKeyForSecretKey(networkId: networkId, accountId: accountId)
    let keyPairData = keyPair.toString().data(using: .utf8)!
    let encrypted = try encrypt(plainTextData: keyPairData, withPublicKeyFromStorageKey: storageKey)
    try await keychainKeyStore.setKey(networkId: networkId, accountId: accountId, withKeyPairAsData: encrypted)
  }
  
  public func getKey(networkId: String, accountId: String) async throws -> KeyPair? {
    let storageKey = storageKeyForSecretKey(networkId: networkId, accountId: accountId)
    guard let encryptedKey = try await keychainKeyStore.getEncryptedKey(networkId: networkId, accountId: accountId) else {
      return nil
    }

    let decrypted = try decrypt(cipherText: encryptedKey, withPrivateKeyFromStorageKey: storageKey)
    return try? keyPairFromString(encodedKey: String(decoding: decrypted, as: UTF8.self))
  }
  
  public func removeKey(networkId: String, accountId: String) async throws -> Void {
    let storageKey = storageKeyForSecretKey(networkId: networkId, accountId: accountId)
    try delete(storageKey: storageKey)
    try await keychainKeyStore.removeKey(networkId: networkId, accountId: accountId)
  }
  
  public func clear() async throws -> Void {
    try delete(storageKey: nil)
    try await keychainKeyStore.clear()
  }
  
  private func delete(storageKey: String?) throws -> Void {
    var params: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
    ]
    if storageKey != nil {
      params[kSecAttrApplicationTag as String] = storageKey! as CFString
    }
    let status = SecItemDelete(params as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound {
      throw SecureEnclaveKeyStoreError.cannotDeleteKeys(osStatus: status)
    }
  }
  
  public func getNetworks() async throws -> [String] {
    return try await keychainKeyStore.getNetworks()
  }
  
  public func getAccounts(networkId: String) async throws -> [String] {
    return try await keychainKeyStore.getAccounts(networkId: networkId)
  }
  
  private func createPrivateKey(withStorageKey storageKey: String) throws -> SecKey {
    let flags: SecAccessControlCreateFlags = requireUserPresence ? [.privateKeyUsage, .userPresence] : .privateKeyUsage

    let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, flags, nil)!
    var attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: storageKey as CFString,
        kSecAttrAccessControl as String: access
      ]
    ]
    
    if SecureEnclave.isAvailable {
      attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
    }
    
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw error!.takeRetainedValue() as Swift.Error
    }
    
    return privateKey
  }
  
  private func getPrivateKey(withStorageKey storageKey: String) throws -> SecKey {
    var params: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrApplicationTag as String: storageKey as CFString,
      kSecReturnRef as String: true,
    ]
    if context != nil {
      params[kSecUseAuthenticationContext as String] = context
    }
    var raw: CFTypeRef?
    let status = SecItemCopyMatching(params as CFDictionary, &raw)
    guard status == errSecSuccess, let result = raw else {
      throw SecureEnclaveKeyStoreError.cannotAccessPrivateKey(osStatus: status)
    }

    return result as! SecKey
  }
  
  private func encrypt(plainTextData: Data, withPublicKey publicKey: SecKey) throws -> Data {
    guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
      throw SecureEnclaveKeyStoreError.encryptionNotSupported(algorithm: algorithm)
    }
    var error: Unmanaged<CFError>?
    guard let cipherTextData = SecKeyCreateEncryptedData(publicKey, algorithm, plainTextData as CFData, &error) as Data? else {
      throw error!.takeRetainedValue() as Swift.Error
    }
    return cipherTextData
  }
  
  func encrypt(plainTextData: Data, withPublicKeyFromStorageKey storageKey: String) throws -> Data {
    let privateKey: SecKey
    do {
      privateKey = try getPrivateKey(withStorageKey: storageKey)
    } catch {
      privateKey = try createPrivateKey(withStorageKey: storageKey)
    }
    
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else { throw SecureEnclaveKeyStoreError.cannotAccessPublicKey }
    return try encrypt(plainTextData: plainTextData, withPublicKey: publicKey)
  }
  
  private func decrypt(cipherText: Data, privateKey: SecKey) throws -> Data {
    guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
      throw SecureEnclaveKeyStoreError.decryptionNotSupported(algorithm: algorithm)
    }

    var error: Unmanaged<CFError>?
    guard let plainTextData = SecKeyCreateDecryptedData(privateKey, algorithm, cipherText as CFData, &error) as Data? else {
      throw error!.takeRetainedValue() as Swift.Error
    }
    
    return plainTextData
  }
  
  func decrypt(cipherText: Data, withPrivateKeyFromStorageKey storageKey: String) throws -> Data {
    let privateKey = try getPrivateKey(withStorageKey: storageKey)
    return try decrypt(cipherText: cipherText, privateKey: privateKey)
  }
  
  private func storageKeyForSecretKey(networkId: String, accountId: String) -> String {
    return "enc:\(accountId):\(networkId)"
  }
}
