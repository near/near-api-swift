//
//  AccountSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 28.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import Quick
import Nimble
import AwaitKit
@testable import nearclientios
class _AccountSpec: XCTestCase {
  var near: Near!
  var workingAccount: Account!

  let contractId = TestUtils.generateUniqueString(prefix: "test_contract")
  var contract: Contract!
  
  override func setUp() async throws {
    // Account setup
    self.near = try await TestUtils.setUpTestConnection()
    let masterAccount = try await self.near.account(accountId: testAccountName)
    let amount = INITIAL_BALANCE
    self.workingAccount = try await TestUtils.createAccount(masterAccount: masterAccount, amount: amount)
    
    // Contract setup
    let newPublicKey = try await self.near.connection.signer.createKey(accountId: contractId, networkId: networkId)
    let data = Wasm().data
    _ = try await self.workingAccount.createAndDeployContract(contractId: contractId, publicKey: newPublicKey, data: data.bytes, amount: UInt128(stringLiteral: "10000000000000000000000000"))
    let options = ContractOptions(viewMethods: [.hello, .getValue, .getAllKeys, .returnHiWithLogs], changeMethods: [.setValue, .generateLogs, .triggerAssert, .testSetRemove], sender: nil)
    contract = Contract(account: self.workingAccount, contractId: contractId, options: options)
  }
  
  func testViewPredefinedAccountWithCorrectName() async throws {
    let status = try await self.workingAccount.state()
    XCTAssertEqual(status.code_hash, "11111111111111111111111111111111")
  }
  
  func testCreateAccountAndViewNewAccount() async throws {
    let newAccountName = TestUtils.generateUniqueString(prefix: "test")
    let newAccountPublicKey = try PublicKey.fromString(encodedKey: "9AhWenZ3JddamBoyMqnTbp7yVbRuvqAv3zwfrWgfVRJE")
    let workingState = try await self.workingAccount.state()
    let amount = workingState.amount
    let newAmount = UInt128(stringLiteral: amount) / UInt128(100)
    _ = try await self.workingAccount.createAccount(newAccountId: newAccountName, publicKey: newAccountPublicKey, amount: newAmount)
    let newAccount = Account(connection: self.near.connection, accountId: newAccountName)
    let state = try await newAccount.state()
    XCTAssertEqual(state.amount, "\(newAmount)")
  }
  
  func testSendMoney() async throws {
    let workingState = try await self.workingAccount.state()
    let amountFraction = UInt128(stringLiteral: workingState.amount) / UInt128(100)
    let sender = try await TestUtils.createAccount(masterAccount: self.workingAccount, amount: amountFraction)
    let receiver = try await TestUtils.createAccount(masterAccount: self.workingAccount, amount: amountFraction)
    _ = try await sender.sendMoney(receiverId: receiver.accountId, amount: UInt128(10000))
    try await receiver.fetchState()
    let state = try await receiver.state()
    XCTAssertEqual(state.amount, "\(amountFraction + UInt128(10000))")
  }
  
  func testDeleteAccount() async throws {
    let workingState = try await self.workingAccount.state()
    let amountFraction = UInt128(stringLiteral: workingState.amount) / UInt128(100)
    let sender = try await TestUtils.createAccount(masterAccount: self.workingAccount, amount: amountFraction)
    let receiver = try await TestUtils.createAccount(masterAccount: self.workingAccount, amount: amountFraction)
    _ = try await sender.deleteAccount(beneficiaryId: receiver.accountId)
    
    let reloaded = Account(connection: sender.connection, accountId: sender.accountId)
    do {
      _ = try await reloaded.state()
      XCTFail("This should fail, as the sender has been deleted.")
    } catch {
      try await receiver.fetchState()
      let senderState = try await receiver.state()
      XCTAssertGreaterThan(UInt128(stringLiteral: senderState.amount), amountFraction)
    }
  }
  
  // Errors
  func testCreatingAnExistingAccountShouldThrow() async throws {
    do {
      _ = try await self.workingAccount.createAccount(newAccountId: self.workingAccount.accountId, publicKey: PublicKey.fromString(encodedKey: "9AhWenZ3JddamBoyMqnTbp7yVbRuvqAv3zwfrWgfVRJE"), amount: 100)
      XCTFail("This should fail, as the account exists already.")
    } catch { }
  }
  
  // With deploy contract
  func testMakeFunctionCallsViaAccount() async throws {
    let result: String = try await self.workingAccount.viewFunction(contractId: contractId, methodName: "hello", args: ["name": "trex"])
    XCTAssertEqual(result, "hello trex")

    let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
    let result2 = try await self.workingAccount.functionCall(contractId: contractId, methodName: "setValue", args: ["value": setCallValue], gas: nil, amount: 0)
    XCTAssertEqual(getTransactionLastResult(txResult: result2) as? String, setCallValue)
    
    let testSetCallValue: String = try await self.workingAccount.viewFunction(contractId: contractId, methodName: "getValue", args: [:])
    XCTAssertEqual(testSetCallValue, setCallValue)
  }
  
  func testMakeFunctionCallsViaAccountWithGas() async throws {
    let result: String = try await contract.view(methodName: .hello, args: ["name": "trex"])
    XCTAssertEqual(result, "hello trex")

    let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
    let result2 = try await contract.change(methodName: .setValue, args: ["value": setCallValue], gas: 1000000 * 1000000) as? String
    XCTAssertEqual(result2, setCallValue)

    let testSetCallValue: String = try await contract.view(methodName: .getValue)
    XCTAssertEqual(testSetCallValue, setCallValue)
  }
  
//  func testShouldGetLogsFromMethodResult() async throws {
//    let logs = try await contract.change(methodName: .generateLogs)
//    expect(logs).to(equal([`[${contractId}]: LOG: log1`, `[${contractId}]: LOG: log2`]))]
//  }
  
  func testCanGetLogsFromViewCall() async throws {
    let result: String = try await contract.view(methodName: .returnHiWithLogs)
    XCTAssertEqual(result, "Hi")
    //expect(logs).toEqual([`[${contractId}]: LOG: loooog1`, `[${contractId}]: LOG: loooog2`]);
  }
  
  func testCanGetAssertMessageFromMethodResult() async throws {
    do {
      try await contract.change(methodName: .triggerAssert)
      XCTFail("The purpose of this method in the test contract is to fail.")
    } catch {
      // This method in the testing contract is just designed to test logging after failure.
      //expect(logs[0]).toEqual(`[${contractId}]: LOG: log before assert`)
      //expect(logs[1]).toMatch(new RegExp(`^\\[${contractId}\\]: ABORT: "?expected to fail"?,?
    }
  }
  
  func testAttemptSetRemove() async throws {
    do {
      try await contract.change(methodName: .testSetRemove, args: ["value": "123"])
    } catch let error {
      XCTFail(error.localizedDescription)
    }
  }
}
