//
//  Account.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

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
  public let accountId: String?
  public let staked: String?
  public let locked: String
  public let amount: String
  public let codeHash: String
  public let storagePaidAt: Int
  public let storageUsage: Int
}

public struct AccountBalance {
  public let total: String
  public let stateStaked: String
  public let staked: String
  public let available: String
}

public struct ProtocolConfigError: Error {}

public struct KeyBox: Decodable {
  public let accessKey: AccessKey
  public let publicKey: String
}

public struct KeyBoxes: Decodable {
  public let keys: [KeyBox]
}

public enum AccountError: Error {
  case noAccessKey(String)
  case noResult
}

public struct AuthorizedApp: Equatable, Codable {
  public let contractId: String
  public let amount: UInt128?
  public let publicKey: String
}

public struct AccountDetails: Equatable, Codable {
  public let authorizedApps: [AuthorizedApp]
  public let transactions: [String]
}

public struct QueryResult: Equatable, Decodable {
  let logs: [String]
  let result: [UInt8]
}

public struct RPCError: Error, Decodable {
  let blockHeight: Int
  let blockHash: String
  let logs: [String]
  let error: String
}

public struct HandlerErrorCause: Decodable {
  public let name: String
}

public struct HandlerError: Decodable {
  public let cause: HandlerErrorCause
  public let code: Int
  public let message: String
}

public struct TransactionError: Error, Decodable {
  public let error: HandlerError
}

public final class Account {
  public let connection: Connection
  public let accountId: String
  private var _state: AccountState?
  private var _accessKey: AccessKey?
  
  func ready() async throws -> Void {
    return try await fetchState()
  }
  
  public init(connection: Connection, accountId: String) {
    self.connection = connection;
    self.accountId = accountId;
  }
  
  func fetchState() async throws -> Void {
    _state = try await connection.provider.query(params: [
      "request_type": "view_account",
      "finality": Finality.optimistic.rawValue,
      "account_id": accountId
    ])
    guard let publicKey = try await connection.signer.getPublicKey(accountId: accountId, networkId: connection.networkId) else {
      print("Missing public key for \(accountId) in \(connection.networkId)")
      return
    }
    _accessKey = try await connection.provider.query(params: [
      "request_type": "view_access_key",
      "finality": Finality.optimistic.rawValue,
      "account_id": accountId,
      "public_key": publicKey.toString()
    ])
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
    throw TypedError.error(type: "Exceeded \(TX_STATUS_RETRY_NUMBER) status check attempts for transaction \(txHash.baseEncoded).", message: "RetriesExceeded")
  }
  
  public func signAndSendTransaction(receiverId: String, actions: [Action]) async throws -> FinalExecutionOutcome {
    try await ready()
    guard _accessKey != nil else {
      throw TypedError.error(type: "Can not sign transactions, initialize account with available public key in Signer.", message: "KeyNotFound")
    }
    
    let status = try await connection.provider.status()
    _accessKey!.nonce += 1
    let blockHash = status.syncInfo.latestBlockHash.baseDecoded
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
      if let transactionError = error as? TransactionError, transactionError.error.cause.name == "TIMEOUT_ERROR" {
        outcome = try await retryTxResult(txHash: txHash, accountId: accountId)
      } else {
        throw error
      }
    }
    
    guard let result = outcome else {throw AccountError.noResult}
    let flatLogs = ([result.transactionOutcome] + result.receiptsOutcome).reduce([], {$0 + $1.outcome.logs})
    printLogs(contractId: signedTx.transaction.receiverId, logs: flatLogs)
    
    if case .failure(let error) = result.status {
      throw TypedError.error(type: "Transaction \(result.transactionOutcome.id) failed. \(error.errorMessage ?? "")",
                             message: error.errorType)
    }
    // TODO: if Tx is Unknown or Started.
    // TODO: deal with timeout on node side.
    return result
  }
  
  public func signAndSendTransactionAsync(receiverId: String, actions: [Action]) async throws -> SimpleRPCResult {
    try await ready()
    guard _accessKey != nil else {
      throw TypedError.error(type: "Can not sign transactions, initialize account with available public key in Signer.", message: "KeyNotFound")
    }
    
    let status = try await connection.provider.status()
    _accessKey!.nonce += 1
    let blockHash = status.syncInfo.latestBlockHash.baseDecoded
    let (_, signedTx) = try await signTransaction(receiverId: receiverId,
                                                  nonce: _accessKey!.nonce,
                                                  actions: actions,
                                                  blockHash: blockHash,
                                                  signer: connection.signer,
                                                  accountId: accountId,
                                                  networkId: connection.networkId)
    
    let outcome: SimpleRPCResult
    do {
      outcome = try await connection.provider.sendTransactionAsync(signedTransaction: signedTx)
    } catch let error {
      throw error
    }
    return outcome
  }
  
  
  @discardableResult
  public func createAndDeployContract(contractId: String, publicKey: PublicKey,
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
  
  @discardableResult
  public func sendMoney(receiverId: String, amount: UInt128) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: receiverId, actions: [nearclientios.transfer(deposit: amount)])
  }
  
  @discardableResult
  public func createAccount(newAccountId: String, publicKey: PublicKey,
                            amount: UInt128) async throws -> FinalExecutionOutcome {
    let accessKey = fullAccessKey()
    let actions = [nearclientios.createAccount(),
                   nearclientios.transfer(deposit: amount),
                   nearclientios.addKey(publicKey: publicKey, accessKey: accessKey)]
    return try await signAndSendTransaction(receiverId: newAccountId, actions: actions)
  }
  
  @discardableResult
  public func deleteAccount(beneficiaryId: String) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId,
                                            actions: [nearclientios.deleteAccount(beneficiaryId: beneficiaryId)])
  }
  
  public func deployContract(data: [UInt8]) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId, actions: [nearclientios.deployContract(code: data)])
  }
  
  public func functionCall(contractId: String, methodName: ChangeMethod, args: [String: Any] = [:],
                           gas: UInt64 = 30000000000000, amount: UInt128) async throws -> FinalExecutionOutcome {
    /// 30000000000000 is the default amount of gas to be sent with the function calls. Used to pay for the fees
    /// incurred while running the contract execution. The unused amount will be refunded back to
    /// the originator.
    /// Due to protocol changes that charge upfront for the maximum possible gas price inflation due to
    /// full blocks, the price of max_prepaid_gas is decreased to `300 * 10**12`.
    /// For discussion see https://github.com/nearprotocol/NEPs/issues/67
    
    let actions = [nearclientios.functionCall(methodName: methodName, args: Data(json: args).bytes,
                                              gas: gas, deposit: amount)]
    return try await signAndSendTransaction(receiverId: contractId, actions: actions)
  }
  
  // TODO: expand this API to support more options.
  @discardableResult
  public func addKey(publicKey: PublicKey, contractId: String?, methodName: String?,
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
  
  @discardableResult
  public func deleteKey(publicKey: PublicKey) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId, actions: [nearclientios.deleteKey(publicKey: publicKey)])
  }
  
  public func stake(publicKey: PublicKey, amount: UInt128) async throws -> FinalExecutionOutcome {
    return try await signAndSendTransaction(receiverId: accountId,
                                            actions: [nearclientios.stake(stake: amount, publicKey: publicKey)])
  }
  
  public func viewFunction<T: Decodable>(contractId: String, methodName: String, args: [String: Any] = [:], decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
    let data = Data(json: args).base64EncodedString()
    let result: QueryResult = try await connection.provider.query(params: [
      "request_type": "call_function",
      "finality": Finality.optimistic.rawValue,
      "account_id": contractId,
      "method_name": methodName,
      "args_base64": data
    ])
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
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = decodingStrategy
    let decodedResult = try decoder.decode(T.self, from: rawData)
    return decodedResult
  }
  
  /// Returns array of {access_key: AccessKey, public_key: PublicKey} items.
  public func getAccessKeys() async throws -> KeyBoxes {
    let response: KeyBoxes = try await connection.provider.query(params: [
      "request_type": "view_access_key_list",
      "finality": Finality.optimistic.rawValue,
      "account_id": accountId,
    ])
    return response
  }
  
  public func getAccountDetails() async throws -> AccountDetails {
    // TODO: update the response value to return all the different keys, not just app keys.
    // Also if we need this function, or getAccessKeys is good enough.
    let accessKeys = try await getAccessKeys()
    var authorizedApps: [AuthorizedApp] = []
    accessKeys.keys.forEach { item in
      if case AccessKeyPermission.functionCall(let permission) = item.accessKey.permission {
        authorizedApps.append(AuthorizedApp(contractId: permission.receiverId,
                                            amount: permission.allowance,
                                            publicKey: item.publicKey))
      }
    }
    let result = AccountDetails(authorizedApps: authorizedApps, transactions: [])
    return result
  }
  
  public func getAccountBalance() async throws -> AccountBalance {
    let protocolConfig = try await connection.provider.experimentalProtocolConfig(blockQuery: .finality(.final))
    let state = try await self.state()
    
    guard let storageAmountPerByte = protocolConfig.runtimeConfig?.storageAmountPerByte else {
      throw ProtocolConfigError()
    }
    let costPerByte = UInt128(stringLiteral: storageAmountPerByte)
    let stateStaked = UInt128(integerLiteral: UInt64(state.storageUsage)) * costPerByte
    let staked = UInt128(stringLiteral: state.locked)
    let totalBalance = UInt128(stringLiteral: state.amount) + staked
    let availableBalance = totalBalance - max(staked, stateStaked)
    
    return AccountBalance(total: totalBalance.toString(), stateStaked: stateStaked.toString(), staked: staked.toString(), available: availableBalance.toString())
  }
}
