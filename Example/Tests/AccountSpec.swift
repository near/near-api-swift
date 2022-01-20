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
  override func setUp() async throws {
    self.near = try await TestUtils.setUpTestConnection()
    let masterAccount = try await self.near.account(accountId: testAccountName)
    let amount = INITIAL_BALANCE * UInt128(100)
    self.workingAccount = try await TestUtils.createAccount(masterAccount: masterAccount, amount: amount)
    print(self.workingAccount)
  }
  func testPredifinedAccountWithCorrectName() async throws {
//    let status = try await self.workingAccount.state()
//    XCTAssertEqual(status.code_hash, "11111111111111111111111111111111")
  }
}
//class AccountSpec: QuickSpec {
//  var near: Near!
//  var workingAccount: Account!
//
//  override func spec() {
//    describe("AccountSpec") {
//      beforeSuite {
//        do {
//          self.near = try await(TestUtils.setUpTestConnection())
//          let masterAccount = try await(self.near.account(accountId: testAccountName))
//          let amount = INITIAL_BALANCE * UInt128(100)
//          self.workingAccount = try await(TestUtils.createAccount(masterAccount: masterAccount, amount: amount))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("it should works with predefined account and returns correct name") {
//        do {
//          let status = try await(self.workingAccount.state())
//          expect(status.code_hash).to(equal("11111111111111111111111111111111"))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("it should create account and then view account returns the created account") {
//        do {
//          let newAccountName = TestUtils.generateUniqueString(prefix: "test")
//          let newAccountPublicKey = try PublicKey.fromString(encodedKey: "9AhWenZ3JddamBoyMqnTbp7yVbRuvqAv3zwfrWgfVRJE")
//          try await(self.workingAccount.createAccount(newAccountId: newAccountName,
//                                                      publicKey: newAccountPublicKey,
//                                                      amount: INITIAL_BALANCE))
//          let newAccount = Account(connection: self.near.connection, accountId: newAccountName)
//          let state = try await(newAccount.state())
//          expect(state.amount).to(equal("\(INITIAL_BALANCE)"))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("it should send money") {
//        do {
//          let sender = try await(TestUtils.createAccount(masterAccount: self.workingAccount))
//          let receiver = try await(TestUtils.createAccount(masterAccount: self.workingAccount))
//          try await(sender.sendMoney(receiverId: receiver.accountId, amount: UInt128(10000)))
//          try await(receiver.fetchState())
//          let state = try await(receiver.state())
//          let rightValue = INITIAL_BALANCE + UInt128(10000)
//          expect(state.amount).to(equal("\(rightValue)"))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("it should delete account") {
//        do {
//          let sender = try await(TestUtils.createAccount(masterAccount: self.workingAccount))
//          let receiver = try await(TestUtils.createAccount(masterAccount: self.workingAccount))
//          try await(sender.deleteAccount(beneficiaryId: receiver.accountId))
//          let reloaded = Account(connection: sender.connection, accountId: sender.accountId)
//          try expect(reloaded.state()).to(throwError())
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//    }
//
//    describe("errors") {
//      it("while creating existing account") {
//        try! expect(self.workingAccount.createAccount(newAccountId: self.workingAccount.accountId,
//                                                     publicKey: PublicKey.fromString(encodedKey: "9AhWenZ3JddamBoyMqnTbp7yVbRuvqAv3zwfrWgfVRJE"),
//                                                     amount: 100)).to(throwError())
//      }
//    }
//
//    describe("with deploy contract") {
////      let oldLog;
////      let logs;
//      let contractId = TestUtils.generateUniqueString(prefix: "test_contract")
//      var contract: Contract!
//
//      beforeSuite {
//        do {
//          let newPublicKey = try await(self.near.connection.signer.createKey(accountId: contractId, networkId: networkId))
//          let data = Wasm().data
//          try await(self.workingAccount.createAndDeployContract(contractId: contractId,
//                                                                publicKey: newPublicKey,
//                                                                data: data.bytes,
//                                                                amount: UInt128(1000000)))
//          let options = ContractOptions(viewMethods: [.hello, .getValue, .getAllKeys, .returnHiWithLogs],
//                                        changeMethods: [.setValue, .generateLogs, .triggerAssert, .testSetRemove],
//                                        sender: nil)
//          contract = Contract(account: self.workingAccount, contractId: contractId, options: options)
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("make function calls via account") {
//        do {
//          let result: String = try await(self.workingAccount.viewFunction(contractId: contractId,
//                                                                          methodName: "hello",
//                                                                          args: ["name": "trex"]))
//          expect(result).to(equal("hello trex"))
//
//          let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
//          let result2 = try await(self.workingAccount.functionCall(contractId: contractId,
//                                                                   methodName: "setValue",
//                                                                   args: ["value": setCallValue],
//                                                                   gas: nil,
//                                                                   amount: 0))
//          expect(getTransactionLastResult(txResult: result2) as? String).to(equal(setCallValue))
//          let testSetCallValue: String = try await(self.workingAccount.viewFunction(contractId: contractId,
//                                                                                    methodName: "getValue",
//                                                                                    args: [:]))
//          expect(testSetCallValue).to(equal(setCallValue))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("should make function calls via contract") {
//        do {
//          let result: String = try await(contract.view(methodName: .hello, args: ["name": "trex"]))
//          expect(result).to(equal("hello trex"))
//
//          let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
//          let result2 = try await(contract.change(methodName: .setValue, args: ["value": setCallValue])) as? String
//          expect(result2).to(equal(setCallValue))
//          let testSetCallValue: String = try await(contract.view(methodName: .getValue))
//          expect(testSetCallValue).to(equal(setCallValue))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("should make function calls via contract with gas") {
//        do {
//          let result: String = try await(contract.view(methodName: .hello, args: ["name": "trex"]))
//          expect(result).to(equal("hello trex"))
//
//          let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
//          let result2 = try await(contract.change(methodName: .setValue, args: ["value": setCallValue], gas: 100000)) as? String
//          expect(result2).to(equal(setCallValue))
//          let testSetCallValue: String = try await(contract.view(methodName: .getValue))
//          expect(testSetCallValue).to(equal(setCallValue))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("should get logs from method result") {
//        do {
//          let logs = try await(contract.change(methodName: .generateLogs))
////          expect(logs).to(equal([`[${contractId}]: LOG: log1`, `[${contractId}]: LOG: log2`]))]
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("can get logs from view call") {
//        do {
//          let result: String = try await(contract.view(methodName: .returnHiWithLogs))
//          expect(result).to(equal("Hi"))
////          expect(logs).toEqual([`[${contractId}]: LOG: loooog1`, `[${contractId}]: LOG: loooog2`]);
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("can get assert message from method result") {
//          try! expect(contract.change(methodName: .triggerAssert)).to(throwError())
//          //          expect(logs[0]).toEqual(`[${contractId}]: LOG: log before assert`);
//          //          expect(logs[1]).toMatch(new RegExp(`^\\[${contractId}\\]: ABORT: "?expected to fail"?,? filename: "assembly/main.ts" line: \\d+ col: \\d+$`));
//      }
//
//      it("test set/remove") {
//        do {
//          try await(contract.change(methodName: .testSetRemove, args: ["value": "123"]))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//    }
//  }
//}
