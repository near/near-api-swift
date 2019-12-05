//
//  AccessKeySpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 02.12.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import Quick
import Nimble
import PromiseKit
import AwaitKit
@testable import nearclientios

class AccessKeySpec: QuickSpec {
  var near: Near!
  var testAccount: Account!
  var workingAccount: Account!
  var contractId: String!
  var contract: Contract!

  override func spec() {
    describe("AccessKeySpec") {
      beforeSuite {
        do {
          self.near = try await(TestUtils.setUpTestConnection())
          let masterAccount = try await(self.near.account(accountId: testAccountName))
          let amount = INITIAL_BALANCE * UInt128(100)
          self.testAccount = try await(TestUtils.createAccount(masterAccount: masterAccount, amount: amount))
        } catch let error {
          fail("\(error)")
        }
      }

      beforeEach {
        do {
          self.contractId = TestUtils.generateUniqueString(prefix: "test")
          self.workingAccount = try await(TestUtils.createAccount(masterAccount: self.testAccount))
          self.contract = try await(TestUtils.deployContract(workingAccount: self.workingAccount,
                                                             contractId: self.contractId))
        } catch let error {
          fail("\(error)")
        }
      }

      it("should make function call using access key") {
        do {
          let keyPair = try keyPairFromRandom()
          try await(self.workingAccount.addKey(publicKey: keyPair.getPublicKey(),
                                               contractId: self.contractId,
                                               methodName: "",
                                               amount: UInt128(10000000)))
          // Override in the key store the workingAccount key to the given access key.
          try await((self.near.connection.signer as! InMemorySigner)
            .keyStore.setKey(networkId: networkId,
                             accountId: self.workingAccount.accountId,
                             keyPair: keyPair))
          let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
          try await(self.contract.change(methodName: .setValue, args: ["value": setCallValue]))
          let testValue: String = try await(self.contract.view(methodName: .getValue))
          expect(testValue).to(equal(setCallValue))
        } catch let error {
          fail("\(error)")
        }
      }

      it("should remove access key no longer works") {
        do {
          let keyPair = try keyPairFromRandom()
          let publicKey = keyPair.getPublicKey()
          try await(self.workingAccount.addKey(publicKey: publicKey,
                                               contractId: self.contractId,
                                               methodName: "",
                                               amount: UInt128(400000)))
          try await(self.workingAccount.deleteKey(publicKey: publicKey))
          // Override in the key store the workingAccount key to the given access key.
          let signer = self.near.connection.signer as! InMemorySigner
          try await(signer.keyStore.setKey(networkId: networkId,
                                           accountId: self.workingAccount.accountId,
                                           keyPair: keyPair))
          try expect(self.contract.change(methodName: .setValue, args: ["value": "test"])).to(throwError())
        } catch let error {
          fail("\(error)")
        }
      }

      it("should view account details after adding access keys") {
        do {
          let keyPair = try keyPairFromRandom()
          try await(self.workingAccount.addKey(publicKey: keyPair.getPublicKey(),
                                               contractId: self.contractId,
                                               methodName: "",
                                               amount: UInt128(1000000000)))
          let contract2 = try await(TestUtils.deployContract(workingAccount: self.workingAccount,
                                                             contractId: "test_contract2_\(Int(Date().timeIntervalSince1970))"))
          let keyPair2 = try keyPairFromRandom()
          try await(self.workingAccount.addKey(publicKey: keyPair2.getPublicKey(),
                                               contractId: contract2.contractId,
                                               methodName: "",
                                               amount: UInt128(2000000000)))
          let details = try await(self.workingAccount.getAccountDetails())
          let expectedResult: [AuthorizedApp] = [AuthorizedApp(contractId: self.contractId,
                                                               amount: UInt128(1000000000),
                                                               publicKey: keyPair.getPublicKey().toString()),
                                                 AuthorizedApp(contractId: contract2.contractId,
                                                               amount: UInt128(2000000000),
                                                               publicKey: keyPair2.getPublicKey().toString())]
          expect(details.authorizedApps).to(contain(expectedResult))
        } catch let error {
          fail("\(error)")
        }
      }

      it("should loading account after adding a full key") {
        do {
          let keyPair = try keyPairFromRandom()
          // wallet calls this with an empty string for contract id and method
          try await(self.workingAccount.addKey(publicKey: keyPair.getPublicKey(),
                                               contractId: "",
                                               methodName: "",
                                               amount: nil))
          let accessKeys = try await(self.workingAccount.getAccessKeys())
          expect(accessKeys.count).to(equal(2))
          let addedKey = accessKeys.first(where: {$0.public_key == keyPair.getPublicKey().toString()})
          expect(addedKey).notTo(beNil())
          if case AccessKeyPermission.fullAccess(let permission) = addedKey!.access_key.permission {
            expect(permission).to(equal(FullAccessPermission()))
          } else {
            fail("AccessKeyPermission in not FullAccess")
          }
        } catch let error {
          fail("\(error)")
        }
      }
    }
  }
}
