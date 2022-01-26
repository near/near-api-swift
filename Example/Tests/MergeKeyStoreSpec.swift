
//  MergeKeyStoreSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 26.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios

class MergeKeyStoreSpec: XCTestCase {
  private let stores: [KeyStore] = [InMemoryKeyStore(), InMemoryKeyStore()]
  private lazy var keyStore: KeyStore! = MergeKeyStore(keyStores: stores)
  
  override func tearDown() async throws {
    try! await(self.keyStore.clear())
  }
  
  func testLookUpKeyFromFallbackKeystoreIfNeeded() async throws {
    let key1 = try! keyPairFromRandom() as! KeyPairEd25519
    try! await self.stores[1].setKey(networkId: "network", accountId: "account", keyPair: key1)
    let key = try! await self.keyStore.getKey(networkId: "network", accountId: "account") as! KeyPairEd25519
    XCTAssertEqual(key, key1)
  }
  
  func testKeyLookupOrder() async throws {
    let key1 = try! keyPairFromRandom() as! KeyPairEd25519
    let key2 = try! keyPairFromRandom() as! KeyPairEd25519
    try! await self.stores[0].setKey(networkId: "network", accountId: "account", keyPair: key1)
    try! await self.stores[1].setKey(networkId: "network", accountId: "account", keyPair: key2)
    let key = try! await self.keyStore.getKey(networkId: "network", accountId: "account") as! KeyPairEd25519
    XCTAssertEqual(key, key1)
  }
  
  func testSetsKeysOnlyInFirstKeyStore() async throws {
    let key1 = try! keyPairFromRandom() as! KeyPairEd25519
    try! await self.keyStore.setKey(networkId: "network", accountId: "account", keyPair: key1)
    let account1 = try! await self.stores[0].getAccounts(networkId: "network")
    let account2 = try! await self.stores[1].getAccounts(networkId: "network")
    XCTAssertEqual(account1.count, 1)
    XCTAssertEqual(account2.count, 0)
  }
}
