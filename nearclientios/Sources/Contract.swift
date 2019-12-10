//
//  Contract.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

internal protocol ContractOptionsProtocol {
  var viewMethods: [ViewMethod] {get}
  var changeMethods: [ChangeMethod] {get}
  var sender: String? {get}
}

internal typealias MethodName = String
internal typealias ViewMethod = MethodName
internal typealias ChangeMethod = MethodName

internal extension ViewMethod {
  static let getValue = "getValue"
  static let getLastResult = "getLastResult"
  static let hello = "hello"
  static let getAllKeys = "getAllKeys"
  static let returnHiWithLogs = "returnHiWithLogs"
}

internal extension ChangeMethod {
  static let setValue = "setValue"
  static let callPromise = "callPromise"
  static let generateLogs = "generateLogs"
  static let triggerAssert = "triggerAssert"
  static let testSetRemove = "testSetRemove"
}

internal struct ContractOptions: ContractOptionsProtocol {
  let viewMethods: [ViewMethod]
  let changeMethods: [ChangeMethod]
  let sender: String?
}

internal struct Contract {
  let account: Account
  let contractId: String
  let viewMethods: [ViewMethod]
  let changeMethods: [ChangeMethod]
  let sender: String?
}

internal extension Contract {
  init(account: Account, contractId: String, options:  ContractOptionsProtocol) {
    self.init(account: account, contractId: contractId, viewMethods: options.viewMethods,
              changeMethods: options.changeMethods, sender: nil)
  }
}

internal extension Contract {
  func view<T: Decodable>(methodName: ChangeMethod, args: [String: Any] = [:]) throws -> Promise<T> {
    return try account.viewFunction(contractId: contractId, methodName: methodName, args: args)
  }
}

internal extension Contract {
  @discardableResult
  func change(methodName: ChangeMethod, args: [String: Any] = [:],
              gas: UInt64? = nil, amount: UInt128 = 0) throws -> Promise<Any?> {
    let rawResult = try await(account.functionCall(contractId: contractId,
                                                   methodName: methodName,
                                                   args: args,
                                                   gas: gas,
                                                   amount: amount))
    return .value(getTransactionLastResult(txResult: rawResult))
  }
}
