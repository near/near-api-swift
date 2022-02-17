////
////  WalletAccountSpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 28.11.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//import KeychainAccess
//@testable import nearclientios
//
//internal class MockAuthService: ExternalAuthService {
//  var urls: [URL] = []
//
//  func openURL(_ url: URL) -> Bool {
//    urls.append(url)
//    return true
//  }
//}
//
//class WalletAccountSpec: XCTestCase {
//
//  var walletAccount: WalletAccount!
//  var keyStore: KeyStore!
//  let walletUrl = "http://example.com/wallet"
//  var authService: MockAuthService!
//  var nearFake: Near!
//  var testStorage: Keychain!
//
//  override func setUp() {
//    self.keyStore = InMemoryKeyStore()
//    self.nearFake = try! Near(config: NearConfig(networkId: "networkId",
//                                                 nodeUrl: URL(string: self.walletUrl)!,
//                                                 masterAccount: nil,
//                                                 keyPath: nil,
//                                                 helperUrl: nil,
//                                                 initialBalance: nil,
//                                                 providerType: .jsonRPC(URL(string: self.walletUrl)!),
//                                                 signerType: .inMemory(self.keyStore),
//                                                 keyStore: self.keyStore,
//                                                 contractName: "contractId",
//                                                 walletUrl: self.walletUrl))
//    self.testStorage = Keychain(service: "TEST_WALLET_STORAGE_SERVICE")
//    self.authService = MockAuthService()
//    self.walletAccount = try! WalletAccount(near: self.nearFake,
//                                            authService: self.authService,
//                                            storage: self.testStorage)
//  }
//
//  override func tearDown() {
//    try! self.testStorage.removeAll()
//  }
//
//  func testNotSignedInByDefault() async {
//    let signedIn = await walletAccount.isSignedIn()
//    XCTAssertFalse(signedIn)
//  }
//
////  func testCanRequestSignIn() async throws {
////    try await(self.walletAccount.requestSignIn(contractId: "signInContract",
////                                               title: "signInTitle",
////                                               successUrl: URL(string: "customscheme://success"),
////                                               failureUrl: URL(string: "customscheme://fail"),
////                                               appUrl: URL(string: "customscheme://")))
////    let accounts = try await(self.keyStore.getAccounts(networkId: "networkId"))
////    XCTAssertEqual(accounts.count, 1)
////    XCTAssertTrue(accounts[0].hasPrefix("pending_key"))
////    XCTAssertEqual(self.authService.urls.count, 1)
////
////    let newUrl = self.authService.urls.last!
////    XCTAssertEqual(newUrl.scheme, "http")
////    XCTAssertEqual(newUrl.host, "example.com")
////    let params = newUrl.queryParameters!
////    XCTAssertEqual(params["title"], "signInTitle")
////    XCTAssertEqual(params["contract_id"], "signInContract")
////    XCTAssertEqual(params["success_url"], "customscheme://success")
////    XCTAssertEqual(params["failure_url"], "customscheme://fail")
////    let keyPair = try await self.keyStore.getKey(networkId: "networkId", accountId: accounts[0])
////    XCTAssertEqual(params["public_key"], keyPair?.getPublicKey().toString())
////  }
//
//  func testCompleteSignIn() async throws {
//    let keyPair = try keyPairFromRandom() as! KeyPairEd25519
//    try await self.keyStore.setKey(networkId: "networkId",
//                                   accountId: "pending_key" + keyPair.getPublicKey().toString(),
//                                   keyPair: keyPair)
//    let public_key = keyPair.getPublicKey().toString()
//    let url = URL(string: "customscheme://success?account_id=near.account&public_key=\(public_key)")!
//    try await self.walletAccount.completeSignIn(UIApplication.shared, open: url)
//    let testKeyPair = try await self.keyStore.getKey(networkId: "networkId",
//                                                     accountId: "near.account")
//    XCTAssertEqual(testKeyPair as? KeyPairEd25519, keyPair)
//    let signedIn = await self.walletAccount.isSignedIn()
//    XCTAssertTrue(signedIn)
//    let accountId = await self.walletAccount.getAccountId()
//    XCTAssertEqual(accountId, "near.account")
//  }
//
//}
//
//
////  override func spec() {
////    describe("WalletAccountSpec") {
////
////      it("can complete sign in") {
////        do {
////          let keyPair = try keyPairFromRandom() as! KeyPairEd25519
////          try await(self.keyStore.setKey(networkId: "networkId",
////                                         accountId: "pending_key" + keyPair.getPublicKey().toString(),
////                                         keyPair: keyPair))
////          let public_key = keyPair.getPublicKey().toString()
////          let url = URL(string: "customscheme://success?account_id=near.account&public_key=\(public_key)")!
////          try await(self.walletAccount.completeSignIn(UIApplication.shared, open: url))
////          let testKeyPair = try await(self.keyStore.getKey(networkId: "networkId",
////                                                           accountId: "near.account"))
////          expect(testKeyPair as? KeyPairEd25519).to(equal(keyPair))
////          expect(self.walletAccount.isSignedIn()).to(beTrue())
////          expect(self.walletAccount.getAccountId()).to(equal("near.account"))
////        } catch let error {
////          fail("\(error)")
////        }
////      }
////    }
////  }
////}
