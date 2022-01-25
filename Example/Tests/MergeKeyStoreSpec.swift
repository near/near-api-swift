//
////  MergeKeyStoreSpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 26.11.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//@testable import nearclientios
//
//class MergeKeyStoreSpec: QuickSpec {
//  static let keystoreService = "test.keystore"
//
//  private let stores: [KeyStore] = [InMemoryKeyStore(), InMemoryKeyStore()]
//  private lazy var keyStore: KeyStore! = MergeKeyStore(keyStores: stores)
//
//  override func spec() {
//
//    afterEach {
//      try! await(self.keyStore.clear())
//    }
//
//    it("looks up key from fallback key store if needed") {
//      let key1 = try! keyPairFromRandom() as! KeyPairEd25519
//      try! await(self.stores[1].setKey(networkId: "network", accountId: "account", keyPair: key1))
//      let key = try! await(self.keyStore.getKey(networkId: "network", accountId: "account")) as! KeyPairEd25519
//      expect(key).to(equal(key1))
//    }
//
//    it("looks up key in proper order") {
//      let key1 = try! keyPairFromRandom() as! KeyPairEd25519
//      let key2 = try! keyPairFromRandom() as! KeyPairEd25519
//      try! await(self.stores[0].setKey(networkId: "network", accountId: "account", keyPair: key1))
//      try! await(self.stores[1].setKey(networkId: "network", accountId: "account", keyPair: key2))
//      let key = try! await(self.keyStore.getKey(networkId: "network", accountId: "account")) as! KeyPairEd25519
//      expect(key).to(equal(key1))
//    }
//
//    it("sets keys only in first key store") {
//      let key1 = try! keyPairFromRandom() as! KeyPairEd25519
//      try! await(self.keyStore.setKey(networkId: "network", accountId: "account", keyPair: key1))
//      let account1 = try! await(self.stores[0].getAccounts(networkId: "network"))
//      let account2 = try! await(self.stores[1].getAccounts(networkId: "network"))
//      expect(account1).to(haveCount(1))
//      expect(account2).to(haveCount(0))
//    }
//
//    itBehavesLike(KeyStoreSpec.self) {self.keyStore}
//  }
//}
//
