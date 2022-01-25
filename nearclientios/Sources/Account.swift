//
//  Account.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

/// Default amount of gas to be sent with the function calls. Used to pay for the fees
/// incurred while running the contract execution. The unused amount will be refunded back to
/// the originator.
/// Due to protocol changes that charge upfront for the maximum possible gas price inflation due to
/// full blocks, the price of max_prepaid_gas is decreased to `300 * 10**12`.
/// For discussion see https://github.com/nearprotocol/NEPs/issues/67
let DEFAULT_FUNC_CALL_AMOUNT: UInt64 = 30000000000000

/// Default number of retries before giving up on a transactioin.
let TX_STATUS_RETRY_NUMBER = 10

/// Default wait until next retry in millis.
let TX_STATUS_RETRY_WAIT: Double = 500

/// Exponential back off for waiting to retry.
let TX_STATUS_RETRY_WAIT_BACKOFF = 1.5

// Sleep given number of millis.
public func sleep(millis: Double) async -> Void {
  let sec = millis / 1000
  return await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
    DispatchQueue.main.asyncAfter(deadline: .now() + sec) {continuation.resume(returning: Void())}
  }
}

public struct AccountState: Codable {
  public let account_id: String?
  public let staked: String?
  public let locked: String
  public let amount: String
  public let code_hash: String
  public let storage_paid_at: Number
  public let storage_usage: Number
}

public struct KeyBox: Decodable {
  let access_key: AccessKey
  let public_key: String
}

public typealias KeyBoxes = [KeyBox]

public enum AccountError: Error {
  case noAccessKey(String)
  case noResult
}

public struct AuthorizedApp: Equatable, Codable {
  let contractId: String
  let amount: UInt128
  let publicKey: String
}

public struct AccountDetails: Equatable, Codable {
  let authorizedApps: [AuthorizedApp]
  let transactions: [String]
}

public struct QueryResult: Equatable, Decodable {
  let logs: [String]
  let result: [UInt8]
}

public final class Account {
  let connection: Connection
  public let accountId: String
  private var _state: AccountState?
  private var _accessKey: AccessKey?

  func ready() async throws -> Void {
    return try await fetchState()
  }

  init(connection: Connection, accountId: String) {
    self.connection = connection;
    self.accountId = accountId;
  }

  func fetchState() async throws -> Void {
    _state = try await connection.provider.query(path: "account/\(accountId)", data: "")
    guard let publicKey = try await connection.signer.getPublicKey(accountId: accountId, networkId: connection.networkId) else {
      print("Missing public key for \(accountId) in \(connection.networkId)")
      return
    }
    _accessKey = try await connection.provider.query(path: "access_key/\(accountId)/\(publicKey.toString())", data: "")
    guard _accessKey != nil else {
      throw AccountError.noAccessKey("Failed to fetch access key for '\(accountId)' with public key \(publicKey.toString())")
    }
    return
  }

  public func state() async throws -> AccountState {
    try await ready()
    return _state!
  }

  private func printLogs(contractId: String, logs: [String]) {
    logs.forEach {print("[\(contractId)]: \($0)")}
  }

  private func retryTxResult(txHash: [UInt8], accountId: String) async throws -> FinalExecutionOutcome {
    var waitTime = TX_STATUS_RETRY_WAIT
    for _ in [0 ..< TX_STATUS_RETRY_NUMBER] {
      if let result = try? await connection.provider.txStatus(txHash: txHash, accountId: accountId) {
        return result
      }
      await sleep(millis: waitTime)
      waitTime *= TX_STATUS_RETRY_WAIT_BACKOFF
    }
    throw TypedError.error(type: "Exceeded \(TX_STATUS_RETRY_NUMBER) status check attempts for transaction \(txHash.baseEncoded).",
      message: "RetriesExceeded")
  }

  private func signAndSendTransaction(receiverId: String, actions: [Action]) async throws -> FinalExecutionOutcome {
    try await ready()
    guard _accessKey != nil else {
      throw TypedError.error(type: "Can not sign transactions, initialize account with available public key in Signer.", message: "KeyNotFound")
    }

    let status = try await connection.provider.status()
    _accessKey!.nonce += 1
    let blockHash = status.sync_info.latest_block_hash.baseDecoded
    let (txHash, signedTx) = try await signTransaction(receiverId: receiverId,
                                                       nonce: _accessKey!.nonce,
                                                       actions: actions,
                                                       blockHash: blockHash,
                                                       signer: connection.signer,
                                                       accountId: accountId,
                                                       networkId: connection.networkId)

    let outcome: FinalExecutionOutcome?
    do {
      outcome = try await connection.provider.sendTransaction(signedTransaction: signedTx)
    } catch let error {
      if case TypedError.error(let type, _) = error, type == "TimeoutError" {
        outcome = try await retryTxResult(txHash: txHash, accountId: accountId)
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
    return result
  }

  func createAndDeployContract(contractId: String, publicKey: PublicKey,
                                       data: [UInt8], amount: UInt128) async throws -> Account {
    let accessKey = fullAccessKey()
    let actions = [nearclientios.createAccount(),
                   nearclientios.transfer(deposit: amount),
                   nearclientios.addKey(publicKey: publicKey, accessKey: accessKey),
                   nearclientios.deployContract(code: data)]
    let _ = try await signAndSendTransaction(receiverId: contractId, actions: actions)
    let contractAccount = Account(connection: connection, accountId: contractId)
    return contractAccount
  }

  func sendMoney(receiverId: String, amount: UInt128) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: receiverId, actions: [nearclientios.transfer(deposit: amount)])
  }

  func createAccount(newAccountId: String, publicKey: PublicKey,
                             amount: UInt128) async throws -> FinalExecutionOutcome {
    let accessKey = fullAccessKey()
    let actions = [nearclientios.createAccount(),
                   nearclientios.transfer(deposit: amount),
                   nearclientios.addKey(publicKey: publicKey, accessKey: accessKey)]
    return try await signAndSendTransaction(receiverId: newAccountId, actions: actions)
  }

  func deleteAccount(beneficiaryId: String) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId,
                                      actions: [nearclientios.deleteAccount(beneficiaryId: beneficiaryId)])
  }

  private func deployContract(data: [UInt8]) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId, actions: [nearclientios.deployContract(code: data)])
  }

  func functionCall(contractId: String, methodName: ChangeMethod, args: [String: Any] = [:],
                            gas: UInt64?, amount: UInt128) async throws -> FinalExecutionOutcome {
    let gasValue = gas ?? DEFAULT_FUNC_CALL_AMOUNT
    let actions = [nearclientios.functionCall(methodName: methodName, args: Data(json: args).bytes,
                                              gas: gasValue, deposit: amount)]
    return try await signAndSendTransaction(receiverId: contractId, actions: actions)
  }

  // TODO: expand this API to support more options.
  func addKey(publicKey: PublicKey, contractId: String?, methodName: String?,
                      amount: UInt128?) async throws -> FinalExecutionOutcome {
    let accessKey: AccessKey
    if let contractId = contractId, !contractId.isEmpty {
      let methodNames = methodName.flatMap {[$0].filter {!$0.isEmpty}} ?? []
      accessKey = functionCallAccessKey(receiverId: contractId, methodNames: methodNames, allowance: amount)
    } else {
      accessKey = fullAccessKey()
    }
    return try await signAndSendTransaction(receiverId: accountId, actions: [nearclientios.addKey(publicKey: publicKey, accessKey: accessKey)])
  }

  func deleteKey(publicKey: PublicKey) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId, actions: [nearclientios.deleteKey(publicKey: publicKey)])
  }

  private func stake(publicKey: PublicKey, amount: UInt128) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId,
                                      actions: [nearclientios.stake(stake: amount, publicKey: publicKey)])
  }

  func viewFunction<T: Decodable>(contractId: String, methodName: String, args: [String: Any] = [:]) async throws -> T {
    let data = Data(json: args).baseEncoded
    let result: QueryResult = try await connection.provider.query(path: "call/\(contractId)/\(methodName)", data: data)
    if !result.logs.isEmpty {
      printLogs(contractId: contractId, logs: result.logs)
    }
    var rawData: Data
    do {
      let dictionary = try result.result.data.toDictionary()
      rawData = try dictionary.toData()
    } catch {
      rawData = result.result.data
    }
    let decodedResult = try JSONDecoder().decode(T.self, from: rawData)
    return decodedResult
  }

  /// Returns array of {access_key: AccessKey, public_key: PublicKey} items.
  func getAccessKeys() async throws -> KeyBoxes {
    let response: KeyBoxes = try await connection.provider.query(path: "access_key/\(accountId)", data: "")
    return response
  }

  func getAccountDetails() async throws -> AccountDetails {
    // TODO: update the response value to return all the different keys, not just app keys.
    // Also if we need this function, or getAccessKeys is good enough.
    let accessKeys = try await getAccessKeys()
    var authorizedApps: [AuthorizedApp] = []
    accessKeys.forEach { item in
      if case AccessKeyPermission.functionCall(let permission) = item.access_key.permission {
        authorizedApps.append(AuthorizedApp(contractId: permission.receiverId,
                                            amount: permission.allowance ?? 0,
                                            publicKey: item.public_key))
      }
    }
    let result = AccountDetails(authorizedApps: authorizedApps, transactions: [])
    return result
  }
}
