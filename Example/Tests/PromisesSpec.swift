//
//  PromisesSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 09.12.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest

@testable import nearclientios
class PromiseSpec: XCTestCase {
  static var near: Near!
  static var workingAccount: Account!
  
  private struct RSResult: Decodable, Equatable {
    let ok: Bool
    let r: Result
  }
  
  private struct Result: Decodable, Equatable {
    let rs: [RSResult]
    let n: String
  }
  
  static var contract: Contract!
  static var contract1: Contract!
  static var contract2: Contract!
  //static var oldLog: [String]
  //static var logs: [String]
  static let contractName = TestUtils.generateUniqueString(prefix: "cnt")
  static let contractName1 = TestUtils.generateUniqueString(prefix: "cnt")
  static let contractName2 = TestUtils.generateUniqueString(prefix: "cnt")
  
  override class func setUp() {
    super.setUp()
    unsafeWaitFor {
      try! await setUpAll()
    }
  }
  
  class func setUpAll() async throws {
    near = try await TestUtils.setUpTestConnection()
    let masterAccount = try await near.account(accountId: testAccountName)
    let amount = INITIAL_BALANCE * UInt128(100)
    workingAccount = try await TestUtils.createAccount(masterAccount: masterAccount, amount: amount)
    
    contract = try await TestUtils.deployContract(workingAccount: workingAccount,
                                                  contractId: contractName)
    contract1 = try await TestUtils.deployContract(workingAccount: workingAccount,
                                                   contractId: contractName1)
    contract2 = try await TestUtils.deployContract(workingAccount: workingAccount,
                                                   contractId: contractName2)
  }
  
  // -> means async call
  // => means callback
  // it should pass test single promise, no callback (A->B)
  func testPassSinglePromiseNoCallback() async throws {
    let args: [String: Any?] = ["receiver": PromiseSpec.contractName1,
                                "methodName": "callbackWithName",
                                "gas": "3000000000000",
                                "balance": "0",
                                "callbackBalance": "0",
                                "callbackGas": "0"]

    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise,
                                                         args: ["args": args]) as! [String: Any]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult: Result = try await PromiseSpec.contract1.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult, Result(rs: [], n: PromiseSpec.contractName1))
    XCTAssertEqual(realResult, lastResult)
  }
  
  // -> means async call
  // => means callback
  // it should pass test single promise with callback (A->B=>A)
  func testPassSinglePromiseWithCallback() async throws {
    let args: [String: Any] = ["receiver": PromiseSpec.contractName1,
                               "methodName": "callbackWithName",
                               "gas": "3000000000000",
                               "balance": "0",
                               "callback": "callbackWithName",
                               "callbackBalance": "0",
                               "callbackGas": "2000000000000"]
    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise,
                                                         args: ["args": args]) as! [String: Any]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult1: Result = try await PromiseSpec.contract1.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult1, Result(rs: [], n: PromiseSpec.contractName1))
    let lastResult: Result = try await PromiseSpec.contract.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult, Result(rs: [RSResult(ok: true, r: lastResult1)], n: PromiseSpec.contractName))
    XCTAssertEqual(realResult, lastResult)
  }
  
  // -> means async call
  // => means callback
  // it should pass test two promises, no callbacks (A->B->C)
  func testPassTwoPromisesNoCallbacks() async throws {
    let callPromiseArgs: [String: Any?] = ["receiver": PromiseSpec.contractName2,
                                          "methodName": "callbackWithName",
                                          "gas": "40000000000000",
                                          "balance": "0",
                                          "callbackBalance": "0",
                                          "callbackGas": "20000000000000"]
    let args: [String: Any?] = ["receiver": PromiseSpec.contractName1,
                               "methodName": "callPromise",
                               "args": callPromiseArgs,
                               "gas": "60000000000000",
                               "balance": "0",
                               "callbackBalance": "0",
                               "callbackGas": "60000000000000"]
    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise, args: ["args": args]) as! [String: Any?]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult2: Result = try await PromiseSpec.contract2.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult2, Result(rs: [], n: PromiseSpec.contractName2))
    XCTAssertEqual(realResult, lastResult2)
  }
  
  // -> means async call
  // => means callback
  // it should pass test two promises, with two callbacks (A->B->C=>B=>A)
  func testPassTwoPromisesWithTwoCallbacks() async throws {
    let callPromiseArgs: [String: Any] = ["receiver": PromiseSpec.contractName2,
                                          "methodName": "callbackWithName",
                                          "gas": "40000000000000",
                                          "balance": "0",
                                          "callback": "callbackWithName",
                                          "callbackBalance": "0",
                                          "callbackGas": "20000000000000"]
    let args: [String: Any] = ["receiver": PromiseSpec.contractName1,
                               "methodName": "callPromise",
                               "args": callPromiseArgs,
                               "gas": "100000000000000",
                               "balance": "0",
                               "callback": "callbackWithName",
                               "callbackBalance": "0",
                               "callbackGas": "30000000000000"]
    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise,
                                                         args: ["args": args]) as! [String: Any]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult2: Result = try await PromiseSpec.contract2.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult2, Result(rs: [], n: PromiseSpec.contractName2))
    let lastResult1: Result = try await PromiseSpec.contract1.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult1, Result(rs: [RSResult(ok: true, r: lastResult2)], n: PromiseSpec.contractName1))
    let lastResult: Result = try await PromiseSpec.contract.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult, Result(rs: [RSResult(ok: true, r: lastResult1)], n: PromiseSpec.contractName))
    XCTAssertEqual(realResult, lastResult)
  }
  
  // -> means async call
  // => means callback
  // it should pass test cross contract call with callbacks (A->B->A=>B=>A)
  func testPassCrossContractCallWithCallbacks() async throws {
    let callPromiseArgs: [String: Any] = ["receiver": PromiseSpec.contractName,
                                          "methodName": "callbackWithName",
                                          "gas": "40000000000000",
                                          "balance": "0",
                                          "callback": "callbackWithName",
                                          "callbackBalance": "0",
                                          "callbackGas": "40000000000000"]
    let args: [String: Any] = ["receiver": PromiseSpec.contractName1,
                               "methodName": "callPromise",
                               "args": callPromiseArgs,
                               "gas": "100000000000000",
                               "balance": "0",
                               "callback": "callbackWithName",
                               "callbackBalance": "0",
                               "callbackGas": "30000000000000"]
    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise,
                                                         args: ["args": args]) as! [String: Any]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult1: Result = try await PromiseSpec.contract1.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult1, Result(rs: [RSResult(ok: true,
                                                     r: Result(rs: [], n: PromiseSpec.contractName))], n: PromiseSpec.contractName1))
    let lastResult: Result = try await PromiseSpec.contract.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult, Result(rs: [RSResult(ok: true, r: lastResult1)], n: PromiseSpec.contractName))
    XCTAssertEqual(realResult, lastResult)
  }
  
  // -> means async call
  // => means callback
  // it should pass test 2 promises with 1 skipped callbacks (A->B->C=>A)
  func testPassTestTwoPromisesWithOneSkippedCallbacks() async throws {
    let callPromiseArgs: [String: Any] = ["receiver": PromiseSpec.contractName2,
                                          "methodName": "callbackWithName",
                                          "gas": "20000000000000",
                                          "balance": "0",
                                          "callbackBalance": "0",
                                          "callbackGas": "20000000000000"]
    let args: [String: Any] = ["receiver": PromiseSpec.contractName1,
                               "methodName": "callPromise",
                               "args": callPromiseArgs,
                               "gas": "50000000000000",
                               "balance": "0",
                               "callback": "callbackWithName",
                               "callbackBalance": "0",
                               "callbackGas": "30000000000000"]
    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise,
                                                         args: ["args": args]) as! [String: Any]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult2: Result = try await PromiseSpec.contract2.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult2, Result(rs: [], n: PromiseSpec.contractName2))
    let lastResult: Result = try await PromiseSpec.contract.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult, Result(rs: [RSResult(ok: true, r: lastResult2)], n: PromiseSpec.contractName))
    XCTAssertEqual(realResult, lastResult)
  }
  
  // -> means async call
  // => means callback
  // it should pass test two promises, with one callbacks to B only (A->B->C=>B)
  func testPassTestTwoPromisesWithOneCallbacksToBOnly() async throws {
    let callPromiseArgs: [String: Any] = ["receiver": PromiseSpec.contractName2,
                                          "methodName": "callbackWithName",
                                          "gas": "40000000000000",
                                          "balance": "0",
                                          "callback": "callbackWithName",
                                          "callbackBalance": "0",
                                          "callbackGas": "40000000000000"]
    let args: [String: Any] = ["receiver": PromiseSpec.contractName1,
                               "methodName": "callPromise",
                               "args": callPromiseArgs,
                               "gas": "100000000000000",
                               "balance": "0",
                               "callbackBalance": "0",
                               "callbackGas": "0"]
    let realResultDictionary = try await PromiseSpec.contract.change(methodName: .callPromise,
                                                         args: ["args": args]) as! [String: Any]
    let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
    let lastResult2: Result = try await PromiseSpec.contract2.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult2, Result(rs: [], n: PromiseSpec.contractName2))
    let lastResult1: Result = try await PromiseSpec.contract1.view(methodName: .getLastResult)
    XCTAssertEqual(lastResult1, Result(rs: [RSResult(ok: true, r: lastResult2)], n: PromiseSpec.contractName1))
    XCTAssertEqual(realResult, lastResult1)
  }
}
