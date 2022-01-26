////
////  AccessKeySpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 02.12.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
import XCTest

@testable import nearclientios
class AccessKeySpec: XCTestCase {
  
  static var near: Near!
  static var testAccount: Account!
  
  override class func setUp() {
    super.setUp()
    unsafeWaitFor {
      try! await setUpAll()
    }
  }
  
  class func setUpAll() async throws {
    near = try await TestUtils.setUpTestConnection()
    let masterAccount = try await self.near.account(accountId: testAccountName)
    let amount = INITIAL_BALANCE * UInt128(100)
    testAccount = try await TestUtils.createAccount(masterAccount: masterAccount, amount: amount)
  }
  
  var workingAccount: Account!
  var contractId: String!
  var contract: Contract!
  
  override func setUp() async throws {
    self.contractId = TestUtils.generateUniqueString(prefix: "test")
    self.workingAccount = try await TestUtils.createAccount(masterAccount: AccessKeySpec.testAccount)
    self.contract = try await TestUtils.deployContract(workingAccount: self.workingAccount,
                                                       contractId: self.contractId)
  }
  
  func testMakeFunctionCallsUsingAcccessKey() async throws {
    let keyPair = try keyPairFromRandom()
    let publicKey = keyPair.getPublicKey()
    try await self.workingAccount.addKey(publicKey: publicKey,
                                         contractId: self.contractId,
                                         methodName: "",
                                         amount: UInt128(stringLiteral: "2000000000000000000000000"))
    // Override in the key store the workingAccount key to the given access key.
    let signer = AccessKeySpec.near.connection.signer as! InMemorySigner
    try await signer.keyStore.setKey(networkId: networkId,
                                     accountId: self.workingAccount.accountId,
                                     keyPair: keyPair)
    let setCallValue = TestUtils.generateUniqueString(prefix: "setCallPrefix")
    try await self.contract.change(methodName: .setValue, args: ["value": setCallValue])
    let testValue: String = try await self.contract.view(methodName: .getValue)
    XCTAssertEqual(testValue, setCallValue)
  }
  
  func testRemoveAccessKeyNoLongerWorks() async throws {
    let keyPair = try keyPairFromRandom()
    let publicKey = keyPair.getPublicKey()
    try await self.workingAccount.addKey(publicKey: publicKey,
                                         contractId: self.contractId,
                                         methodName: "",
                                         amount: UInt128(400000))
    try await self.workingAccount.deleteKey(publicKey: publicKey)
    // Override in the key store the workingAccount key to the given access key.
    let signer = AccessKeySpec.near.connection.signer as! InMemorySigner
    try await signer.keyStore.setKey(networkId: networkId,
                                     accountId: self.workingAccount.accountId,
                                     keyPair: keyPair)
    
    await XCTAssertThrowsError(try await self.contract.change(methodName: .setValue, args: ["value": "test"]) as Any) { error in
      XCTAssertTrue(error is DecodingError)
    }
  }
  
  func testViewAccountDetailsAfterAddingAccessKeys() async throws {
    let keyPair = try keyPairFromRandom()
    try await self.workingAccount.addKey(publicKey: keyPair.getPublicKey(),
                                         contractId: self.contractId,
                                         methodName: "",
                                         amount: UInt128(1000000000))
    let contract2 = try await TestUtils.deployContract(workingAccount: self.workingAccount,
                                                       contractId: TestUtils.generateUniqueString(prefix: "test_contract2"))
    let keyPair2 = try keyPairFromRandom()
    try await self.workingAccount.addKey(publicKey: keyPair2.getPublicKey(),
                                         contractId: contract2.contractId,
                                         methodName: "",
                                         amount: UInt128(2000000000))
    let details = try await self.workingAccount.getAccountDetails()
    let expectedResult: [AuthorizedApp] = [AuthorizedApp(contractId: self.contractId,
                                                         amount: UInt128(1000000000),
                                                         publicKey: keyPair.getPublicKey().toString()),
                                           AuthorizedApp(contractId: contract2.contractId,
                                                         amount: UInt128(2000000000),
                                                         publicKey: keyPair2.getPublicKey().toString())]
    
    XCTAssertTrue(details.authorizedApps.contains(expectedResult[0]))
    XCTAssertTrue(details.authorizedApps.contains(expectedResult[1]))
  }
  
  func testLoadingAccountAfterAddingAFullKey() async throws {
    let keyPair = try keyPairFromRandom()
    // wallet calls this with an empty string for contract id and method
    try await self.workingAccount.addKey(publicKey: keyPair.getPublicKey(),
                                         contractId: "",
                                         methodName: "",
                                         amount: nil)
    let accessKeys = try await self.workingAccount.getAccessKeys()
    XCTAssertEqual(accessKeys.keys.count, 2)
    let addedKey = accessKeys.keys.first(where: {$0.public_key == keyPair.getPublicKey().toString()})
    XCTAssertNotNil(addedKey)
    if case AccessKeyPermission.fullAccess(let permission) = addedKey!.access_key.permission {
      XCTAssertEqual(permission, FullAccessPermission())
    } else {
      XCTFail("AccessKeyPermission in not FullAccess")
    }
  }
}
