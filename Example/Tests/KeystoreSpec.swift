//
//  KeystoreSpec.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 26.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios
import LocalAuthentication

let NETWORK_ID_SINGLE_KEY = "singlekeynetworkid"
let ACCOUNT_ID_SINGLE_KEY = "singlekey_accountid"
let secretKey = "2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw"
let KEYPAIR_SINGLE_KEY = try! KeyPairEd25519(secretKey: secretKey)

class KeyStoreSpec: XCTestCase {
  static var keyStores: [KeyStore] = []
  override class func setUp() {
    keyStores.append(InMemoryKeyStore())
    keyStores.append(UnencryptedFileSystemKeyStore(keyDir: "test-keys"))
    keyStores.append(KeychainKeyStore(keychain: .init(service: "test.keystore")))
    keyStores.append(SecureEnclaveKeyStore(keychain: .init(service: "testEnclave.keystore")))
    keyStores.append(MergeKeyStore(keyStores: [InMemoryKeyStore(), InMemoryKeyStore()]))
  }
  
  func withAllKeyStores(run: (_: KeyStore) async throws -> Void) async throws {
    for store in KeyStoreSpec.keyStores {
      try await run(store)
    }
  }
  
  override func setUp() async throws {
    try await withAllKeyStores(run: setUp(keyStore:))
  }
  
  func setUp(keyStore: KeyStore) async throws {
    try! await(keyStore.setKey(networkId: NETWORK_ID_SINGLE_KEY,
                               accountId: ACCOUNT_ID_SINGLE_KEY,
                               keyPair: KEYPAIR_SINGLE_KEY))
  }
  
  override func tearDown() async throws {
    try await withAllKeyStores(run: tearDown(keyStore:))
  }
  
  func tearDown(keyStore: KeyStore) async throws {
    try! await(keyStore.clear())
  }
  
  func testGetAllKeysWithEmptyNetworkReturnsEmptyList() async throws {
    try await withAllKeyStores(run: getAllKeysWithEmptyNetworkReturnsEmptyList)
  }
  func getAllKeysWithEmptyNetworkReturnsEmptyList(keyStore: KeyStore) async throws {
    let emptyList = try! await keyStore.getAccounts(networkId: "emptynetwork")
    XCTAssertEqual(emptyList.count, 0)
  }
  
  func testGetAllKeysWithSingleKeyInKeyStore() async throws {
    try await withAllKeyStores(run: getAllKeysWithSingleKeyInKeyStore)
  }
  func getAllKeysWithSingleKeyInKeyStore(keyStore: KeyStore) async throws {
    let accountIds = try! await keyStore.getAccounts(networkId: NETWORK_ID_SINGLE_KEY)
    XCTAssertEqual(accountIds, [ACCOUNT_ID_SINGLE_KEY])
  }
  
  func testGetNonExistingAccount() async throws {
    try await withAllKeyStores(run: getNonExistingAccount)
  }
  func getNonExistingAccount(keyStore: KeyStore) async throws {
    let account = try! await(keyStore.getKey(networkId: "somenetwork", accountId: "someaccount"))
    XCTAssertNil(account)
  }
  
  func testGetAccountIdFromNetworkWithSingleKey() async throws {
    try await withAllKeyStores(run: getAccountIdFromNetworkWithSingleKey)
  }
  func getAccountIdFromNetworkWithSingleKey(keyStore: KeyStore) async throws {
    let key = try! await keyStore.getKey(networkId: NETWORK_ID_SINGLE_KEY,
                                         accountId: ACCOUNT_ID_SINGLE_KEY) as? KeyPairEd25519
    XCTAssertEqual(key, KEYPAIR_SINGLE_KEY)
  }

  func testGetNetworks() async throws {
    try await withAllKeyStores(run: getNetworks)
  }
  func getNetworks(keyStore: KeyStore) async throws {
    let networks = try! await keyStore.getNetworks()
    XCTAssertEqual(networks, [NETWORK_ID_SINGLE_KEY])
  }
  
  func testAddTwoKeysToNetworkAndRetrieveThem() async throws {
    try await withAllKeyStores(run: addTwoKeysToNetworkAndRetrieveThem)
  }
  func addTwoKeysToNetworkAndRetrieveThem(keyStore: KeyStore) async throws {
    if keyStore is SecureEnclaveKeyStore {
      (keyStore as! SecureEnclaveKeyStore).context = LAContext()
    }
    let networkId = "twoKeyNetwork"
    let accountId1 = "acc1"
    let accountId2 = "acc2"
    let key1Expected = try! keyPairFromRandom() as! KeyPairEd25519
    let key2Expected = try! keyPairFromRandom() as! KeyPairEd25519
    try! await keyStore.setKey(networkId: networkId, accountId: accountId1, keyPair: key1Expected)
    try! await keyStore.setKey(networkId: networkId, accountId: accountId2, keyPair: key2Expected)
    let key1 = try await keyStore.getKey(networkId: networkId, accountId: accountId1) as! KeyPairEd25519
    let key2 = try await keyStore.getKey(networkId: networkId, accountId: accountId2) as! KeyPairEd25519
    XCTAssertEqual(key1, key1Expected)
    XCTAssertEqual(key2, key2Expected)
    let accountIds = try! await keyStore.getAccounts(networkId: networkId)
    XCTAssertEqual(accountIds.sorted(), [accountId1, accountId2].sorted())
    let networks = try! await(keyStore.getNetworks())
    XCTAssertEqual(networks.sorted(), [NETWORK_ID_SINGLE_KEY, networkId].sorted())
  }

}

