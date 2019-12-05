//
//  Near.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

internal protocol NearConfigProtocol: ConnectionConfigProtocol {
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

internal struct NearConfig: NearConfigProtocol {
  let networkId: String
  let nodeUrl: URL
  var masterAccount: String?
  let keyPath: String?
  let helperUrl: URL?
  let initialBalance: UInt128?
  let providerType: ProviderType
  let signerType: SignerType
  var keyStore: KeyStore?
  let contractName: String?
  let walletUrl: String
}

internal struct Near {
  let config: NearConfigProtocol
  let connection: Connection
  private let accountCreator: AccountCreator?
}

internal enum NearError: Error {
  case noAccountCreator(String)
  case noAccountId
}

extension Near {
  init(config: NearConfigProtocol) throws {
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

internal extension Near {
  func account(accountId: String) throws -> Promise<Account> {
    let account = Account(connection: connection, accountId: accountId)
    try await(account.state())
    return .value(account)
  }

  private func createAccount(accountId: String, publicKey: PublicKey) throws -> Promise<Account> {
    guard let accountCreator = accountCreator else {
      throw NearError.noAccountCreator("Must specify account creator, either via masterAccount or helperUrl configuration settings.")
    }
    try await(accountCreator.createAccount(newAccountId: accountId, publicKey: publicKey))
    return .value(Account(connection: connection, accountId: accountId))
  }

  /**
   - Parameters:
      - contractId: contractId
      - options: options
   - Returns: promise with contract.
   */
  @available(*, deprecated, renamed: "Contract.init", message: "Backwards compatibility method. Use contract constructor instead")
  private func loadContract(contractId: String, options: ContractOptionsProtocol) throws -> Promise<Contract> {
    print("near.loadContract is deprecated. Use `Contract.init` instead.")
    guard let accountId = options.sender else { throw NearError.noAccountId }
    let account = Account(connection: connection, accountId: accountId)
    let contract = Contract(account: account, contractId: contractId, viewMethods: options.viewMethods,
                    changeMethods: options.changeMethods, sender: accountId)
    return .value(contract)
  }

  /**
   - Parameters:
      - amount: amount
      - originator: originator
      - receiver: receiver
   */
  @available(*, deprecated, renamed: "yourAccount.sendMoney", message: "Backwards compatibility method. Use `yourAccount.sendMoney` instead")
  private func sendTokens(amount: UInt128, originator: String, receiver: String) throws -> Promise<String> {
    print("near.sendTokens is deprecated. Use `yourAccount.sendMoney` instead.")
    let account = Account(connection: connection, accountId: originator)
    let result = try await(account.sendMoney(receiverId: receiver, amount: amount))
    return .value(result.transaction.id)
  }
}

func connect(config: NearConfigProtocol) throws -> Promise<Near> {
    // Try to find extra key in `KeyPath` if provided.let
  var configuration = config
  if let keyPath = configuration.keyPath, let keyStore = configuration.keyStore {
    do {
      let (accountId, keyPair) = try await(UnencryptedFileSystemKeyStore.readKeyFile(path: keyPath))
      // TODO: Only load key if network ID matches
      let keyPathStore = InMemoryKeyStore()
      try await(keyPathStore.setKey(networkId: configuration.networkId, accountId: accountId, keyPair: keyPair))
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
  return .value(near)
}
