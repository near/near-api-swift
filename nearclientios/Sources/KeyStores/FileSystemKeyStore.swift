//
//  AccountInfo.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

/**
// Format of the account stored on disk.
*/
internal protocol AccountInfoProtocol {
  var account_id: String {get}
  var private_key: String? {get}
  var secret_key: String? {get}
}

internal struct AccountInfo: AccountInfoProtocol, Codable {
  let account_id: String
  let private_key: String?
  let secret_key: String?
}

internal struct UnencryptedFileSystemKeyStore {
  let keyDir: String
  let manager: FileManager

  init(keyDir: String, manager: FileManager = .default) {
    self.keyDir = keyDir
    self.manager = manager
  }
}

internal enum UnencryptedFileSystemKeyStoreError: Error {
  case noPrivateKey
}

extension UnencryptedFileSystemKeyStore: KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void> {
    do {
      let networkPath = "\(keyDir)/\(networkId)"
      let fullNetworkPath = manager.targetDirectory.appendingPathComponent(networkPath).path
      try manager.ensureDir(path: fullNetworkPath)
      let content = AccountInfo(account_id: accountId, private_key: keyPair.toString(), secret_key: nil)
      let encoded = try JSONEncoder().encode(content)
      let fileUrl = getKeyFileUrl(networkPath: networkPath, accountId: accountId)
      try encoded.write(to: fileUrl, options: [.atomic])
      return .value(())
    } catch let error {
      return .init(error: error)
    }
  }

  /// Find key / account id.
  func getKey(networkId: String, accountId: String) -> Promise<KeyPair?> {
    let networkPath = "\(keyDir)/\(networkId)"
    let path = getKeyFileUrl(networkPath: networkPath, accountId: accountId).path
    guard manager.fileExists(atPath: path) else {return .value(nil)}
    do {
      let accountKeyPair = try await(UnencryptedFileSystemKeyStore.readKeyFile(path: path))
      return .value(accountKeyPair.1)
    } catch let error {
      return .init(error: error)
    }
  }

  func removeKey(networkId: String, accountId: String) -> Promise<Void> {
    let networkPath = "\(keyDir)/\(networkId)"
    let path = getKeyFileUrl(networkPath: networkPath, accountId: accountId).path
    guard manager.fileExists(atPath: path) else {return .value(())}
    do {
      try manager.removeItem(atPath: path)
      return .value(())
    } catch let error {
      return .init(error: error)
    }
  }

  func clear() -> Promise<Void> {
    do {
      let networks = try await(getNetworks())
      try networks.forEach { networkId in
        let accounts = try await(getAccounts(networkId: networkId))
        try accounts.forEach { accountId in
          try await(removeKey(networkId: networkId, accountId: accountId))
        }
      }
      return .value(())
    } catch let error {
      return .init(error: error)
    }
  }

  func getNetworks() -> Promise<[String]> {
    let networksPath = manager.targetDirectory.appendingPathComponent(keyDir).path
    do {
      let files = try manager.contentsOfDirectory(atPath: networksPath)
      return .value(files)
    } catch let error {
      return .init(error: error)
    }
  }

  func getAccounts(networkId: String) -> Promise<[String]> {
    let networkPath = "\(keyDir)/\(networkId)"
    let fullNetworkPath = manager.targetDirectory.appendingPathComponent(networkPath).path
    guard manager.fileExists(atPath: fullNetworkPath) else {return .value([])}
    do {
      let files = try manager.contentsOfDirectory(atPath: fullNetworkPath)
      return .value(files.filter {$0.hasSuffix(".json")}.map {$0.replacingOccurrences(of: ".json", with: "")})
    } catch let error {
      return .init(error: error)
    }
  }
}

extension UnencryptedFileSystemKeyStore {
  private func getKeyFileUrl(networkPath: String, accountId: String) -> URL {
    return manager.targetDirectory.appendingPathComponent("\(networkPath)/\(accountId).json")
  }

  private static func loadJsonFile(path: String) throws -> Promise<AccountInfo> {
    let content = try Data(contentsOf: URL(fileURLWithPath: path), options: [])
    let accountInfo = try JSONDecoder().decode(AccountInfo.self, from: content)
    return .value(accountInfo)
  }

  static func readKeyFile(path: String) throws -> Promise<(String, KeyPair)> {
    let accountInfo = try await(loadJsonFile(path: path))
    // The private key might be in private_key or secret_key field.
    var privateKey = accountInfo.private_key
    if privateKey == nil, accountInfo.secret_key != nil {
      privateKey = accountInfo.secret_key
    }
    guard privateKey != nil else {return .init(error: UnencryptedFileSystemKeyStoreError.noPrivateKey)}
    let keyPair = try keyPairFromString(encodedKey: privateKey!)
    return .value((accountInfo.account_id, keyPair))
  }
}
