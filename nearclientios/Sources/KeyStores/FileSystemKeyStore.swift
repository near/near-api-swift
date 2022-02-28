//
//  AccountInfo.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

/**
// Format of the account stored on disk.
*/
public protocol AccountInfoProtocol {
  var account_id: String {get}
  var private_key: String? {get}
  var secret_key: String? {get}
}

public struct AccountInfo: AccountInfoProtocol, Codable {
  public let account_id: String
  public let private_key: String?
  public let secret_key: String?
}

public struct UnencryptedFileSystemKeyStore {
  let keyDir: String
  let manager: FileManager

  public init(keyDir: String, manager: FileManager = .default) {
    self.keyDir = keyDir
    self.manager = manager
  }
}

public enum UnencryptedFileSystemKeyStoreError: Error {
  case noPrivateKey
}

extension UnencryptedFileSystemKeyStore: KeyStore {
  public func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws -> Void {
    let networkPath = "\(keyDir)/\(networkId)"
    let fullNetworkPath = manager.targetDirectory.appendingPathComponent(networkPath).path
    try manager.ensureDir(path: fullNetworkPath)
    let content = AccountInfo(account_id: accountId, private_key: keyPair.toString(), secret_key: nil)
    let encoded = try JSONEncoder().encode(content)
    let fileUrl = getKeyFileUrl(networkPath: networkPath, accountId: accountId)
    try encoded.write(to: fileUrl, options: [.atomic])
  }

  /// Find key / account id.
  public func getKey(networkId: String, accountId: String) async throws -> KeyPair? {
    let networkPath = "\(keyDir)/\(networkId)"
    let path = getKeyFileUrl(networkPath: networkPath, accountId: accountId).path
    guard manager.fileExists(atPath: path) else {return nil}
    let accountKeyPair = try await UnencryptedFileSystemKeyStore.readKeyFile(path: path)
    return accountKeyPair.1
  }

  public func removeKey(networkId: String, accountId: String) async throws -> Void {
    let networkPath = "\(keyDir)/\(networkId)"
    let path = getKeyFileUrl(networkPath: networkPath, accountId: accountId).path
    guard manager.fileExists(atPath: path) else {return}
    try manager.removeItem(atPath: path)
  }

  public func clear() async throws -> Void {
    let networksPath = manager.targetDirectory.appendingPathComponent(keyDir).path
    try manager.removeItem(atPath: networksPath)
  }

  public func getNetworks() async throws -> [String] {
    let networksPath = manager.targetDirectory.appendingPathComponent(keyDir).path
    let files = try manager.contentsOfDirectory(atPath: networksPath)
    return files
  }

  public func getAccounts(networkId: String) async throws -> [String] {
    let networkPath = "\(keyDir)/\(networkId)"
    let fullNetworkPath = manager.targetDirectory.appendingPathComponent(networkPath).path
    guard manager.fileExists(atPath: fullNetworkPath) else {return []}
    let files = try manager.contentsOfDirectory(atPath: fullNetworkPath)
    return files.filter {$0.hasSuffix(".json")}.map {$0.replacingOccurrences(of: ".json", with: "")}
  }
}

extension UnencryptedFileSystemKeyStore {
  private func getKeyFileUrl(networkPath: String, accountId: String) -> URL {
    return manager.targetDirectory.appendingPathComponent("\(networkPath)/\(accountId).json")
  }

  private static func loadJsonFile(path: String) async throws -> AccountInfo {
    let content = try Data(contentsOf: URL(fileURLWithPath: path), options: [])
    let accountInfo = try JSONDecoder().decode(AccountInfo.self, from: content)
    return accountInfo
  }

  static func readKeyFile(path: String) async throws -> (String, KeyPair) {
    let accountInfo = try await loadJsonFile(path: path)
    // The private key might be in private_key or secret_key field.
    var privateKey = accountInfo.private_key
    if privateKey == nil, accountInfo.secret_key != nil {
      privateKey = accountInfo.secret_key
    }
    guard privateKey != nil else {throw UnencryptedFileSystemKeyStoreError.noPrivateKey}
    let keyPair = try keyPairFromString(encodedKey: privateKey!)
    return (accountInfo.account_id, keyPair)
  }
}
