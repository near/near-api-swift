//
//  Contract.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public protocol ContractOptionsProtocol {
  var viewMethods: [ViewMethod] {get}
  var changeMethods: [ChangeMethod] {get}
  var sender: String? {get}
}

public typealias MethodName = String
public typealias ViewMethod = MethodName
public typealias ChangeMethod = MethodName

public extension ViewMethod {
  static let getValue = "getValue"
  static let getLastResult = "getLastResult"
  static let hello = "hello"
  static let getAllKeys = "getAllKeys"
  static let returnHiWithLogs = "returnHiWithLogs"
}

public extension ChangeMethod {
  static let setValue = "setValue"
  static let callPromise = "callPromise"
  static let generateLogs = "generateLogs"
  static let triggerAssert = "triggerAssert"
  static let testSetRemove = "testSetRemove"
}

public struct ContractOptions: ContractOptionsProtocol {
  public let viewMethods: [ViewMethod]
  public let changeMethods: [ChangeMethod]
  public let sender: String?
}

public struct Contract {
  let account: Account
  let contractId: String
  let viewMethods: [ViewMethod]
  let changeMethods: [ChangeMethod]
  let sender: String?
}

public extension Contract {
  init(account: Account, contractId: String, options:  ContractOptionsProtocol) {
    self.init(account: account, contractId: contractId, viewMethods: options.viewMethods,
              changeMethods: options.changeMethods, sender: nil)
  }
}

public extension Contract {
  func view<T: Decodable>(methodName: ChangeMethod, args: [String: Any] = [:]) async throws -> T {
    return try await account.viewFunction(contractId: contractId, methodName: methodName, args: args)
  }
}

public extension Contract {
  @discardableResult
  func change(methodName: ChangeMethod, args: [String: Any] = [:],
              gas: UInt64? = nil, amount: UInt128 = 0) async throws -> Any? {
    let rawResult = try await account.functionCall(contractId: contractId,
                                                   methodName: methodName,
                                                   args: args,
                                                   gas: gas,
                                                   amount: amount)
    return getTransactionLastResult(txResult: rawResult)
  }
}
