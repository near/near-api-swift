//
//  AccountSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 28.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest

@testable import nearclientios
class AccountSpec: XCTestCase {
  static var near: Near!
  static var workingAccount: Account!

  static let contractId = TestUtils.generateUniqueString(prefix: "test_contract")
  static var contract: Contract!
  
  override class func setUp() {
    super.setUp()
    unsafeWaitFor {
      do {
        try await setUpAll()
      } catch let error {
        print(error)
      }
    }
  }
  
  class func setUpAll() async throws {
    // Account setup
    near = try await TestUtils.setUpTestConnection()
    let masterAccount = try await near.account(accountId: testAccountName)
    let amount = INITIAL_BALANCE
    workingAccount = try await TestUtils.createAccount(masterAccount: masterAccount, amount: amount)
    
    // Contract setup
    let newPublicKey = try await near.connection.signer.createKey(accountId: contractId, networkId: networkId, curve: .ED25519)
    let data = Wasm().data
    try await workingAccount.createAndDeployContract(contractId: contractId, publicKey: newPublicKey, data: data.bytes, amount: HELLO_WASM_BALANCE)
    let options = ContractOptions(viewMethods: [.hello, .getValue, .getAllKeys, .returnHiWithLogs], changeMethods: [.setValue, .generateLogs, .triggerAssert, .testSetRemove], sender: nil)
    contract = Contract(account: workingAccount, contractId: contractId, options: options)
  }
  
  func testViewPredefinedAccountWithCorrectName() async throws {
    let status = try await AccountSpec.workingAccount.state()
    XCTAssertEqual(status.codeHash, "11111111111111111111111111111111")
  }
  
  func testCreateAccountAndViewNewAccount() async throws {
    let newAccountName = TestUtils.generateUniqueString(prefix: "test")
    let newAccountPublicKey = try PublicKey.fromString(encodedKey: "9AhWenZ3JddamBoyMqnTbp7yVbRuvqAv3zwfrWgfVRJE")
    let workingState = try await AccountSpec.workingAccount.state()
    let amount = workingState.amount
    let newAmount = UInt128(stringLiteral: amount) / UInt128(100)
    try await AccountSpec.workingAccount.createAccount(newAccountId: newAccountName, publicKey: newAccountPublicKey, amount: newAmount)
    let newAccount = Account(connection: AccountSpec.near.connection, accountId: newAccountName)
    let state = try await newAccount.state()
    XCTAssertEqual(state.amount, "\(newAmount)")
  }
  
  func testCreateAccountAndViewNewAccountUsingSecp256k1Curve() async throws {
    let newAccountName = TestUtils.generateUniqueString(prefix: "test")
    let newAccountPublicKey = try PublicKey.fromString(encodedKey: "secp256k1:45KcWwYt6MYRnnWFSxyQVkuu9suAzxoSkUMEnFNBi9kDayTo5YPUaqMWUrf7YHUDNMMj3w75vKuvfAMgfiFXBy28")
    let workingState = try await AccountSpec.workingAccount.state()
    let amount = workingState.amount
    let newAmount = UInt128(stringLiteral: amount) / UInt128(100)
    try await AccountSpec.workingAccount.createAccount(newAccountId: newAccountName, publicKey: newAccountPublicKey, amount: newAmount)
    let newAccount = Account(connection: AccountSpec.near.connection, accountId: newAccountName)
    let state = try await newAccount.state()
    XCTAssertEqual(state.amount, "\(newAmount)")
  }
  
  func testSendMoney() async throws {
    let workingState = try await AccountSpec.workingAccount.state()
    let amountFraction = UInt128(stringLiteral: workingState.amount) / UInt128(100)
    let sender = try await TestUtils.createAccount(masterAccount: AccountSpec.workingAccount, amount: amountFraction)
    let receiver = try await TestUtils.createAccount(masterAccount: AccountSpec.workingAccount, amount: amountFraction)
    try await sender.sendMoney(receiverId: receiver.accountId, amount: UInt128(10000))
    try await receiver.fetchState()
    let state = try await receiver.state()
    XCTAssertEqual(state.amount, "\(amountFraction + UInt128(10000))")
  }
  
  func testDeleteAccount() async throws {
    let workingState = try await AccountSpec.workingAccount.state()
    let amountFraction = UInt128(stringLiteral: workingState.amount) / UInt128(100)
    let sender = try await TestUtils.createAccount(masterAccount: AccountSpec.workingAccount, amount: amountFraction)
    let receiver = try await TestUtils.createAccount(masterAccount: AccountSpec.workingAccount, amount: amountFraction)
    try await sender.deleteAccount(beneficiaryId: receiver.accountId)
    try await receiver.fetchState()
    let senderState = try await receiver.state()
    XCTAssertGreaterThan(UInt128(stringLiteral: senderState.amount), amountFraction)
    
    let reloaded = Account(connection: sender.connection, accountId: sender.accountId)
    await AssertThrowsError(try await reloaded.state()) { error in
      XCTAssertTrue(error is HTTPError)
    }
  }
  
  // Errors
  func testCreatingAnExistingAccountShouldThrow() async throws {
    await AssertThrowsError(try await AccountSpec.workingAccount.createAccount(newAccountId: AccountSpec.workingAccount.accountId, publicKey: PublicKey.fromString(encodedKey: "9AhWenZ3JddamBoyMqnTbp7yVbRuvqAv3zwfrWgfVRJE"), amount: 100)) { error in
      XCTAssertTrue(error is TypedError)
    }
  }
  
  // With deploy contract
  func testMakeFunctionCallsViaAccount() async throws {
    let result: String = try await AccountSpec.workingAccount.viewFunction(contractId: AccountSpec.contractId, methodName: "hello", args: ["name": "trex"])
    XCTAssertEqual(result, "hello trex")

    let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
    let result2 = try await AccountSpec.workingAccount.functionCall(contractId: AccountSpec.contractId, methodName: "setValue", args: ["value": setCallValue], amount: 0)
    XCTAssertEqual(getTransactionLastResult(txResult: result2) as? String, setCallValue)
    
    let testSetCallValue: String = try await AccountSpec.workingAccount.viewFunction(contractId: AccountSpec.contractId, methodName: "getValue", args: [:])
    XCTAssertEqual(testSetCallValue, setCallValue)
  }
  
  func testMakeFunctionCallsViaAccountWithGas() async throws {
    let result: String = try await AccountSpec.contract.view(methodName: .hello, args: ["name": "trex"])
    XCTAssertEqual(result, "hello trex")

    let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
    let result2 = try await AccountSpec.contract.change(methodName: .setValue, args: ["value": setCallValue], gas: 1000000 * 1000000) as? String
    XCTAssertEqual(result2, setCallValue)

    let testSetCallValue: String = try await AccountSpec.contract.view(methodName: .getValue)
    XCTAssertEqual(testSetCallValue, setCallValue)
  }
  
//  func testShouldGetLogsFromMethodResult() async throws {
//    let logs = try await contract.change(methodName: .generateLogs)
//    expect(logs).to(equal([`[${contractId}]: LOG: log1`, `[${contractId}]: LOG: log2`]))]
//  }
  
  func testCanGetLogsFromViewCall() async throws {
    let result: String = try await AccountSpec.contract.view(methodName: .returnHiWithLogs)
    XCTAssertEqual(result, "Hi")
    //expect(logs).toEqual([`[${contractId}]: LOG: loooog1`, `[${contractId}]: LOG: loooog2`]);
  }
  
  func testCanGetAssertMessageFromMethodResult() async throws {
    await AssertThrowsError(try await AccountSpec.contract.change(methodName: .triggerAssert) as Any) { error in
      XCTAssertTrue(error is TypedError)
      // This method in the testing contract is just designed to test logging after failure.
      //expect(logs[0]).toEqual(`[${contractId}]: LOG: log before assert`)
      //expect(logs[1]).toMatch(new RegExp(`^\\[${contractId}\\]: ABORT: "?expected to fail"?,?
    }
  }
  
  func testAttemptSetRemove() async throws {
    do {
      try await AccountSpec.contract.change(methodName: .testSetRemove, args: ["value": "123"])
    } catch let error {
      XCTFail(error.localizedDescription)
    }
  }
}
