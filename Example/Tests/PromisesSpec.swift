////
////  PromisesSpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 09.12.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//@testable import nearclientios
//
//class PromiseSpec: QuickSpec {
//  var near: Near!
//  var workingAccount: Account!
//
//  private struct RSResult: Decodable, Equatable {
//    let ok: Bool
//    let r: Result
//  }
//
//  private struct Result: Decodable, Equatable {
//    let rs: [RSResult]
//    let n: String
//  }
//
//  override func spec() {
//    describe("PromiseSpec") {
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
//      describe("with promises") {
//        var contract: Contract!
//        var contract1: Contract!
//        var contract2: Contract!
//        //var oldLog: [String]
//        //var logs: [String]
//        let contractName = TestUtils.generateUniqueString(prefix: "cnt")
//        let contractName1 = TestUtils.generateUniqueString(prefix: "cnt")
//        let contractName2 = TestUtils.generateUniqueString(prefix: "cnt")
//
//        beforeSuite {
//          do {
//            contract = try await(TestUtils.deployContract(workingAccount: self.workingAccount,
//                                                          contractId: contractName))
//            contract1 = try await(TestUtils.deployContract(workingAccount: self.workingAccount,
//                                                           contractId: contractName1))
//            contract2 = try await(TestUtils.deployContract(workingAccount: self.workingAccount,
//                                                           contractId: contractName2))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//        // -> means async call
//        // => means callback
//
//        it("it should pass test single promise, no callback (A->B)") {
//          do {
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callbackWithName",
//                                       "gas": 300000,
//                                       "balance": 0,
//                                       "callbackBalance": 0,
//                                       "callbackGas": 0]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult: Result = try await(contract1.view(methodName: .getLastResult))
//            expect(lastResult).to(equal(Result(rs: [], n: contractName1)))
//            expect(realResult).to(equal(lastResult))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//
//        it("it should pass test single promise with callback (A->B=>A)") {
//          do {
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callbackWithName",
//                                       "gas": 300000,
//                                       "balance": 0,
//                                       "callback": "callbackWithName",
//                                       "callbackBalance": 0,
//                                       "callbackGas": 200000]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult1: Result = try await(contract1.view(methodName: .getLastResult))
//            expect(lastResult1).to(equal(Result(rs: [], n: contractName1)))
//            let lastResult: Result = try await(contract.view(methodName: .getLastResult))
//            expect(lastResult).to(equal(Result(rs: [RSResult(ok: true, r: lastResult1)], n: contractName)))
//            expect(realResult).to(equal(lastResult))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//
//        it("it should pass test two promises, no callbacks (A->B->C)") {
//          do {
//            let callPromiseArgs: [String: Any] = ["receiver": contractName2,
//                                                  "methodName": "callbackWithName",
//                                                  "gas": 400000,
//                                                  "balance": 0,
//                                                  "callbackBalance": 0,
//                                                  "callbackGas": 200000]
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callPromise",
//                                       "args": callPromiseArgs,
//                                       "gas": 600000,
//                                       "balance": 0,
//                                       "callbackBalance": 0,
//                                       "callbackGas": 600000]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult2: Result = try await(contract2.view(methodName: .getLastResult))
//            expect(lastResult2).to(equal(Result(rs: [], n: contractName2)))
//            expect(realResult).to(equal(lastResult2))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//
//        it("it should pass test two promises, with two callbacks (A->B->C=>B=>A)") {
//          do {
//            let callPromiseArgs: [String: Any] = ["receiver": contractName2,
//                                                  "methodName": "callbackWithName",
//                                                  "gas": 400000,
//                                                  "balance": 0,
//                                                  "callback": "callbackWithName",
//                                                  "callbackBalance": 0,
//                                                  "callbackGas": 200000]
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callPromise",
//                                       "args": callPromiseArgs,
//                                       "gas": 1000000,
//                                       "balance": 0,
//                                       "callback": "callbackWithName",
//                                       "callbackBalance": 0,
//                                       "callbackGas": 300000]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult2: Result = try await(contract2.view(methodName: .getLastResult))
//            expect(lastResult2).to(equal(Result(rs: [], n: contractName2)))
//            let lastResult1: Result = try await(contract1.view(methodName: .getLastResult))
//            expect(lastResult1).to(equal(Result(rs: [RSResult(ok: true, r: lastResult2)], n: contractName1)))
//            let lastResult: Result = try await(contract.view(methodName: .getLastResult))
//            expect(lastResult).to(equal(Result(rs: [RSResult(ok: true, r: lastResult1)], n: contractName)))
//            expect(realResult).to(equal(lastResult))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//
//        it("it should pass test cross contract call with callbacks (A->B->A=>B=>A)") {
//          do {
//            let callPromiseArgs: [String: Any] = ["receiver": contractName,
//                                                  "methodName": "callbackWithName",
//                                                  "gas": 400000,
//                                                  "balance": 0,
//                                                  "callback": "callbackWithName",
//                                                  "callbackBalance": 0,
//                                                  "callbackGas": 400000]
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callPromise",
//                                       "args": callPromiseArgs,
//                                       "gas": 1000000,
//                                       "balance": 0,
//                                       "callback": "callbackWithName",
//                                       "callbackBalance": 0,
//                                       "callbackGas": 300000]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult1: Result = try await(contract1.view(methodName: .getLastResult))
//            expect(lastResult1).to(equal(Result(rs: [RSResult(ok: true,
//                                                              r: Result(rs: [], n: contractName))], n: contractName1)))
//            let lastResult: Result = try await(contract.view(methodName: .getLastResult))
//            expect(lastResult).to(equal(Result(rs: [RSResult(ok: true, r: lastResult1)], n: contractName)))
//            expect(realResult).to(equal(lastResult))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//
//        it("it should pass test 2 promises with 1 skipped callbacks (A->B->C=>A)") {
//          do {
//            let callPromiseArgs: [String: Any] = ["receiver": contractName2,
//                                                  "methodName": "callbackWithName",
//                                                  "gas": 200000,
//                                                  "balance": 0,
//                                                  "callbackBalance": 0,
//                                                  "callbackGas": 200000]
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callPromise",
//                                       "args": callPromiseArgs,
//                                       "gas": 500000,
//                                       "balance": 0,
//                                       "callback": "callbackWithName",
//                                       "callbackBalance": 0,
//                                       "callbackGas": 300000]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult2: Result = try await(contract2.view(methodName: .getLastResult))
//            expect(lastResult2).to(equal(Result(rs: [], n: contractName2)))
//            let lastResult: Result = try await(contract.view(methodName: .getLastResult))
//            expect(lastResult).to(equal(Result(rs: [RSResult(ok: true, r: lastResult2)], n: contractName)))
//            expect(realResult).to(equal(lastResult))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//
//        it("it should pass test two promises, with one callbacks to B only (A->B->C=>B)") {
//          do {
//            let callPromiseArgs: [String: Any] = ["receiver": contractName2,
//                                                  "methodName": "callbackWithName",
//                                                  "gas": 400000,
//                                                  "balance": 0,
//                                                  "callback": "callbackWithName",
//                                                  "callbackBalance": 0,
//                                                  "callbackGas": 400000]
//            let args: [String: Any] = ["receiver": contractName1,
//                                       "methodName": "callPromise",
//                                       "args": callPromiseArgs,
//                                       "gas": 1000000,
//                                       "balance": 0,
//                                       "callbackBalance": 0,
//                                       "callbackGas": 0]
//            let realResultDictionary = try await(contract.change(methodName: .callPromise,
//                                                                 args: ["args": args])) as! [String: Any]
//            let realResult = try JSONDecoder().decode(Result.self, from: try realResultDictionary.toData())
//            let lastResult2: Result = try await(contract2.view(methodName: .getLastResult))
//            expect(lastResult2).to(equal(Result(rs: [], n: contractName2)))
//            let lastResult1: Result = try await(contract1.view(methodName: .getLastResult))
//            expect(lastResult1).to(equal(Result(rs: [RSResult(ok: true, r: lastResult2)], n: contractName1)))
//            expect(realResult).to(equal(lastResult1))
//          } catch let error {
//            fail("\(error)")
//          }
//        }
//      }
//    }
//  }
//}
