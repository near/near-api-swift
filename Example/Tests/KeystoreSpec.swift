////
////  KeystoreSpec.swift
////  nearclientios
////
////  Created by Dmytro Kurochka on 26.11.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//@testable import nearclientios
//
//let NETWORK_ID_SINGLE_KEY = "singlekeynetworkid"
//let ACCOUNT_ID_SINGLE_KEY = "singlekey_accountid"
//let secretKey = "2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw"
//let KEYPAIR_SINGLE_KEY = try! KeyPairEd25519(secretKey: secretKey)
//
//class KeyStoreSpec: Behavior<KeyStore> {
//  override class func spec(_ context: @escaping () -> KeyStore) {
//    let keyStore = context()
//
//    describe("Should store and retrieve keys") {
//
//      beforeEach {
//        try! await(keyStore.setKey(networkId: NETWORK_ID_SINGLE_KEY,
//                                   accountId: ACCOUNT_ID_SINGLE_KEY,
//                                   keyPair: KEYPAIR_SINGLE_KEY))
//      }
//
//      afterEach {
//        try! await(keyStore.clear())
//      }
//
//      it("Get all keys with empty network returns empty list") {
//        let emptyList = try! await(keyStore.getAccounts(networkId: "emptynetwork"))
//        expect(emptyList.count).to(equal(0))
//      }
//
//      it("Get all keys with single key in keystore") {
//        let accountIds = try! await(keyStore.getAccounts(networkId: NETWORK_ID_SINGLE_KEY))
//        expect(accountIds).to(equal([ACCOUNT_ID_SINGLE_KEY]))
//      }
//
//      it("Get not-existing account") {
//        let account = try! await(keyStore.getKey(networkId: "somenetwork", accountId: "someaccount"))
//        expect(account).to(beNil())
//      }
//
//      it("Get account id from a network with single key") {
//        let key = try! await(keyStore.getKey(networkId: NETWORK_ID_SINGLE_KEY,
//                                             accountId: ACCOUNT_ID_SINGLE_KEY)) as? KeyPairEd25519
//        expect(key).to(equal(KEYPAIR_SINGLE_KEY))
//      }
//
//      it("Get networks") {
//        let networks = try! await(keyStore.getNetworks())
//        expect(networks).to(equal([NETWORK_ID_SINGLE_KEY]))
//      }
//
//      it("Add two keys to network and retrieve them") {
//        let networkId = "twoKeyNetwork"
//        let accountId1 = "acc1"
//        let accountId2 = "acc2"
//        let key1Expected = try! keyPairFromRandom() as! KeyPairEd25519
//        let key2Expected = try! keyPairFromRandom() as! KeyPairEd25519
//        try! await(keyStore.setKey(networkId: networkId, accountId: accountId1, keyPair: key1Expected))
//        try! await(keyStore.setKey(networkId: networkId, accountId: accountId2, keyPair: key2Expected))
//        let key1 = try! await(keyStore.getKey(networkId: networkId, accountId: accountId1)) as! KeyPairEd25519
//        let key2 = try! await(keyStore.getKey(networkId: networkId, accountId: accountId2)) as! KeyPairEd25519
//        expect(key1).to(equal(key1Expected))
//        expect(key2).to(equal(key2Expected))
//        let accountIds = try! await(keyStore.getAccounts(networkId: networkId))
//        expect(accountIds.sorted()).to(equal([accountId1, accountId2].sorted()))
//        let networks = try! await(keyStore.getNetworks())
//        expect(networks.sorted()).to(equal([NETWORK_ID_SINGLE_KEY, networkId].sorted()))
//      }
//    }
//  }
//}
