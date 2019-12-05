//
//  Account.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

//TODO complete this part

/// Default amount of tokens to be send with the function calls. Used to pay for the fees
/// incurred while running the contract execution. The unused amount will be refunded back to
/// the originator.
let DEFAULT_FUNC_CALL_AMOUNT = 2000000

/// Default number of retries before giving up on a transactioin.
let TX_STATUS_RETRY_NUMBER = 10

/// Default wait until next retry in millis.
let TX_STATUS_RETRY_WAIT: Double = 500

/// Exponential back off for waiting to retry.
let TX_STATUS_RETRY_WAIT_BACKOFF = 1.5

// Sleep given number of millis.
internal func sleep(millis: Double) -> Promise<Void> {
  let sec = millis / 1000
  return Promise<Void> { seal in
    DispatchQueue.main.asyncAfter(deadline: .now() + sec) {seal.fulfill(())}
  }
}

internal struct AccountState: Codable {
  let account_id: String?
  let staked: String?
  let locked: String
  let amount: String
  let code_hash: String
  let storage_paid_at: Number
  let storage_usage: Number
}

internal struct KeyBox: Decodable {
  let access_key: AccessKey
  let public_key: String
}

internal typealias KeyBoxes = [KeyBox]

internal enum AccountError: Error {
  case noAccessKey(String)
  case noResult
}

internal struct AuthorizedApp: Equatable, Codable {
  let contractId: String
  let amount: UInt128
  let publicKey: String
}

internal struct AccountDetails: Equatable, Codable {
  let authorizedApps: [AuthorizedApp]
  let transactions: [String]
}

internal final class Account {
  let connection: Connection
  let accountId: String
  private var _state: AccountState?
  private var _accessKey: AccessKey?

  private lazy var ready: Promise<Void> = {
    do {
      return try fetchState()
    } catch let error {
      return .init(error: error)
    }
  }()

  init(connection: Connection, accountId: String) {
    self.connection = connection;
    self.accountId = accountId;
  }

  func fetchState() throws -> Promise<Void> {
    _state = try await(connection.provider.query(path: "account/\(accountId)", data: ""))
    guard let publicKey = try await(connection.signer.getPublicKey(accountId: accountId,
                                                                   networkId: connection.networkId)) else {
                                                                    print("Missing public key for \(accountId) in \(connection.networkId)")
                                                                    return .value(())
    }
    _accessKey = try await(connection.provider.query(path: "access_key/\(accountId)/\(publicKey.toString())", data: ""))
    guard _accessKey != nil else {
      return .init(error: AccountError.noAccessKey("Failed to fetch access key for '\(accountId)' with public key \(publicKey.toString())"))
    }
    return .value(())
  }

  func state() throws -> Promise<AccountState> {
    try await(ready)
    return .value(_state!)
  }

  private func printLogs(contractId: String, logs: [String]) {
    logs.forEach {print("[\(contractId)]: \($0)")}
  }

  private func retryTxResult(txHash: [UInt8], accountId: String) throws -> Promise<FinalExecutionOutcome> {
    var waitTime = TX_STATUS_RETRY_WAIT
    for _ in [0 ..< TX_STATUS_RETRY_NUMBER] {
      if let result = try? await(connection.provider.txStatus(txHash: txHash, accountId: accountId)) {
        return .value(result)
      }
      try await(sleep(millis: waitTime))
      waitTime *= TX_STATUS_RETRY_WAIT_BACKOFF
    }
    throw TypedError.error(type: "Exceeded \(TX_STATUS_RETRY_NUMBER) status check attempts for transaction \(txHash.baseEncoded).",
      message: "RetriesExceeded")
  }

  private func signAndSendTransaction(receiverId: String, actions: [Action]) throws -> Promise<FinalExecutionOutcome> {
    try await(ready)
    guard _accessKey != nil else {
      throw TypedError.error(type: "Can not sign transactions, initialize account with available public key in Signer.", message: "KeyNotFound")
    }

    let status = try await(connection.provider.status())

    _accessKey!.nonce += 1
    let blockHash = status.sync_info.latest_block_hash.baseDecoded
    let (txHash, signedTx) = try await(signTransaction(receiverId: receiverId,
                                                       nonce: _accessKey!.nonce,
                                                       actions: actions,
                                                       blockHash: blockHash,
                                                       signer: connection.signer,
                                                       accountId: accountId,
                                                       networkId: connection.networkId))

    let outcome: FinalExecutionOutcome?
    do {
      outcome = try await(connection.provider.sendTransaction(signedTransaction: signedTx))
    } catch let error {
      if case TypedError.error(let type, _) = error, type == "TimeoutError" {
        outcome = try await(retryTxResult(txHash: txHash, accountId: accountId))
      } else {
        throw error
      }
    }

    guard let result = outcome else {throw AccountError.noResult}

    let flatLogs = ([result.transaction] + result.receipts).reduce([], {$0 + $1.outcome.logs})
    printLogs(contractId: signedTx.transaction.receiverId, logs: flatLogs)

    if case .failure(let error) = result.status {
      throw TypedError.error(type: "Transaction \(result.transaction.id) failed. \(error.error_message ?? "")",
        message: error.error_type)
    }
    // TODO: if Tx is Unknown or Started.
    // TODO: deal with timeout on node side.
    return .value(result)
  }

  func createAndDeployContract(contractId: String, publicKey: PublicKey,
                                       data: [UInt8], amount: UInt128) throws -> Promise<Account> {
    let accessKey = fullAccessKey()
    let actions = [nearclientios.createAccount(),
                   nearclientios.transfer(deposit: amount),
                   nearclientios.addKey(publicKey: publicKey, accessKey: accessKey),
                   nearclientios.deployContract(code: data)]
    try await(signAndSendTransaction(receiverId: contractId, actions: actions))
    let contractAccount = Account(connection: connection, accountId: contractId)
    return .value(contractAccount)
  }

  func sendMoney(receiverId: String, amount: UInt128) throws -> Promise<FinalExecutionOutcome> {
    return try signAndSendTransaction(receiverId: receiverId, actions: [nearclientios.transfer(deposit: amount)])
  }

  func createAccount(newAccountId: String, publicKey: PublicKey,
                             amount: UInt128) throws -> Promise<FinalExecutionOutcome> {
    let accessKey = fullAccessKey()
    let actions = [nearclientios.createAccount(),
                   nearclientios.transfer(deposit: amount),
                   nearclientios.addKey(publicKey: publicKey, accessKey: accessKey)]
    return try signAndSendTransaction(receiverId: newAccountId, actions: actions)
  }

  func deleteAccount(beneficiaryId: String) throws -> Promise<FinalExecutionOutcome> {
    return try signAndSendTransaction(receiverId: accountId,
                                      actions: [nearclientios.deleteAccount(beneficiaryId: beneficiaryId)])
  }

  private func deployContract(data: [UInt8]) throws -> Promise<FinalExecutionOutcome> {
    return try signAndSendTransaction(receiverId: accountId, actions: [nearclientios.deployContract(code: data)])
  }

  func functionCall(contractId: String, methodName: ChangeMethod, args: [String: Any] = [:],
                            gas: Number?, amount: UInt128?) throws -> Promise<FinalExecutionOutcome> {
    let gasValue = gas ?? DEFAULT_FUNC_CALL_AMOUNT
    let actions = [nearclientios.functionCall(methodName: methodName, args: Data(json: args).bytes,
                                              gas: gasValue, deposit: amount)]
    return try signAndSendTransaction(receiverId: contractId, actions: actions)
  }

  // TODO: expand this API to support more options.
  func addKey(publicKey: PublicKey, contractId: String?, methodName: String?,
                      amount: UInt128?) throws -> Promise<FinalExecutionOutcome> {
    let accessKey: AccessKey
    if let contractId = contractId, !contractId.isEmpty {
      let methodNames = methodName.flatMap {[$0]} ?? []
      accessKey = functionCallAccessKey(receiverId: contractId, methodNames: methodNames, allowance: amount)
    } else {
      accessKey = fullAccessKey()
    }
    return try signAndSendTransaction(receiverId: accountId, actions: [nearclientios.addKey(publicKey: publicKey, accessKey: accessKey)])
  }

  func deleteKey(publicKey: PublicKey) throws -> Promise<FinalExecutionOutcome> {
    return try signAndSendTransaction(receiverId: accountId, actions: [nearclientios.deleteKey(publicKey: publicKey)])
  }

  private func stake(publicKey: PublicKey, amount: UInt128) throws -> Promise<FinalExecutionOutcome> {
    return try signAndSendTransaction(receiverId: accountId,
                                      actions: [nearclientios.stake(stake: amount, publicKey: publicKey)])
  }

  func viewFunction<T: Codable>(contractId: String, methodName: String, args: [String: Any] = [:]) throws -> Promise<T> {
    let data = String(data: Data(json: args), encoding: .utf8) ?? ""
    let result: T = try await(connection.provider.query(path: "call/\(contractId)/\(methodName)", data: data))
    return .value(result)
    //TODO: don't get it
//    if result.logs {
//      printLogs(contractId, result.logs)
//    }
//    return result.result && result.result.length > 0 && JSON.parse(Buffer.from(result.result).toString());
  }

  /// Returns array of {access_key: AccessKey, public_key: PublicKey} items.
  func getAccessKeys() throws -> Promise<KeyBoxes> {
    let response: KeyBoxes = try await(connection.provider.query(path: "access_key/\(accountId)", data: ""))
    return .value(response)
  }

  func getAccountDetails() throws -> Promise<AccountDetails> {
    // TODO: update the response value to return all the different keys, not just app keys.
    // Also if we need this function, or getAccessKeys is good enough.
    let accessKeys = try await(getAccessKeys())
    var authorizedApps: [AuthorizedApp] = []
    accessKeys.forEach { item in
      if case AccessKeyPermission.functionCall(let permission) = item.access_key.permission {
        authorizedApps.append(AuthorizedApp(contractId: permission.receiverId,
                                            amount: permission.allowance ?? 0,
                                            publicKey: item.public_key))
      }
    }
    let result = AccountDetails(authorizedApps: authorizedApps, transactions: [])
    return .value(result)
  }
}
