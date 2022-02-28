//
//  Near.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public protocol NearConfigProtocol: ConnectionConfigProtocol {
  var networkId: String {get}
  var nodeUrl: URL {get}
  var masterAccount: String? {get set}
  var keyPath: String? {get}
  var helperUrl: URL? {get}
  var initialBalance: UInt128? {get}
  var keyStore: KeyStore? {get set}
  var contractName: String? {get}
  var walletUrl: String {get}
}

public struct NearConfig: NearConfigProtocol {
  public let networkId: String
  public let nodeUrl: URL
  public var masterAccount: String?
  public let keyPath: String?
  public let helperUrl: URL?
  public let initialBalance: UInt128?
  public let providerType: ProviderType
  public let signerType: SignerType
  public var keyStore: KeyStore?
  public let contractName: String?
  public let walletUrl: String
  
  public init(networkId: String, nodeUrl: URL, masterAccount: String?, keyPath: String?, helperUrl: URL?, initialBalance: UInt128?, providerType: ProviderType, signerType: SignerType, keyStore: KeyStore?, contractName: String?, walletUrl: String) {
    self.networkId = networkId
    self.nodeUrl = nodeUrl
    self.masterAccount = masterAccount
    self.keyPath = keyPath
    self.helperUrl = helperUrl
    self.initialBalance = initialBalance
    self.providerType = providerType
    self.signerType = signerType
    self.keyStore = keyStore
    self.contractName = contractName
    self.walletUrl = walletUrl
  }
}

public struct Near {
  let config: NearConfigProtocol
  let connection: Connection
  private let accountCreator: AccountCreator?
}

public enum NearError: Error {
  case noAccountCreator(String)
  case noAccountId
}

extension Near {
  public init(config: NearConfigProtocol) throws {
    let connection = try Connection.fromConfig(config: config)
    var accountCreator: AccountCreator?
    if let masterAccount = config.masterAccount {
      // TODO: figure out better way of specifiying initial balance.
      let initialBalance = config.initialBalance ?? UInt128(1000000000000)
      let masterAccount = Account(connection: connection, accountId: masterAccount)
      accountCreator = LocalAccountCreator(masterAccount: masterAccount, initialBalance: initialBalance)
    } else if let url = config.helperUrl {
      accountCreator = UrlAccountCreator(connection: connection, helperUrl: url)
    }
    self.init(config: config, connection: connection, accountCreator: accountCreator)
  }
}

public extension Near {
  func account(accountId: String) async throws -> Account {
    let account = Account(connection: connection, accountId: accountId)
    try await account.ready()
    return account
  }

  private func createAccount(accountId: String, publicKey: PublicKey) async throws -> Account {
    guard let accountCreator = accountCreator else {
      throw NearError.noAccountCreator("Must specify account creator, either via masterAccount or helperUrl configuration settings.")
    }
    try await accountCreator.createAccount(newAccountId: accountId, publicKey: publicKey)
    return Account(connection: connection, accountId: accountId)
  }

  /**
   - Parameters:
      - contractId: contractId
      - options: options
   - Returns: promise with contract.
   */
  @available(*, deprecated, renamed: "Contract.init", message: "Backwards compatibility method. Use contract constructor instead")
  private func loadContract(contractId: String, options: ContractOptionsProtocol) async throws -> Contract {
    print("near.loadContract is deprecated. Use `Contract.init` instead.")
    guard let accountId = options.sender else { throw NearError.noAccountId }
    let account = Account(connection: connection, accountId: accountId)
    let contract = Contract(account: account, contractId: contractId, viewMethods: options.viewMethods,
                    changeMethods: options.changeMethods, sender: accountId)
    return contract
  }

  /**
   - Parameters:
      - amount: amount
      - originator: originator
      - receiver: receiver
   */
  @available(*, deprecated, renamed: "yourAccount.sendMoney", message: "Backwards compatibility method. Use `yourAccount.sendMoney` instead")
  private func sendTokens(amount: UInt128, originator: String, receiver: String) async throws -> String {
    print("near.sendTokens is deprecated. Use `yourAccount.sendMoney` instead.")
    let account = Account(connection: connection, accountId: originator)
    let result = try await account.sendMoney(receiverId: receiver, amount: amount)
    return result.transactionOutcome.id
  }
}

func connect(config: NearConfigProtocol) async throws -> Near {
    // Try to find extra key in `KeyPath` if provided.let
  var configuration = config
  if let keyPath = configuration.keyPath, let keyStore = configuration.keyStore {
    do {
      let (accountId, keyPair) = try await UnencryptedFileSystemKeyStore.readKeyFile(path: keyPath)
      // TODO: Only load key if network ID matches
      let keyPathStore = InMemoryKeyStore()
      try await keyPathStore.setKey(networkId: configuration.networkId, accountId: accountId, keyPair: keyPair)
      if configuration.masterAccount == nil {
        configuration.masterAccount = accountId
      }
      configuration.keyStore = MergeKeyStore(keyStores: [keyStore, keyPathStore])
      print("Loaded master account \(accountId) key from \(keyPath) with public key = \(keyPair.getPublicKey())")
    } catch let error {
      print("Failed to load master account key from \(keyPath): \(error)")
    }
  }
  let near = try Near(config: configuration)
  return near
}
