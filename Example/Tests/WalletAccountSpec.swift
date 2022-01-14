////
////  WalletAccountSpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 28.11.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//import Quick
//import Nimble
//import AwaitKit
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
//class WalletAccountSpec: QuickSpec {
//
//  var walletAccount: WalletAccount!
//  var keyStore: KeyStore!
//  let walletUrl = "http://example.com/wallet"
//  var authService: MockAuthService!
//  var nearFake: Near!
//  var testStorage: Keychain!
//
//
//  override func spec() {
//    describe("WalletAccountSpec") {
//      beforeEach {
//        self.keyStore = InMemoryKeyStore()
//        self.nearFake = try! Near(config: NearConfig(networkId: "networkId",
//                                                     nodeUrl: URL(string: self.walletUrl)!,
//                                                     masterAccount: nil,
//                                                     keyPath: nil,
//                                                     helperUrl: nil,
//                                                     initialBalance: nil,
//                                                     providerType: .jsonRPC(URL(string: self.walletUrl)!),
//                                                     signerType: .inMemory(self.keyStore),
//                                                     keyStore: self.keyStore,
//                                                     contractName: "contractId",
//                                                     walletUrl: self.walletUrl))
//        self.testStorage = Keychain(service: "TEST_WALLET_STORAGE_SERVICE")
//        self.authService = MockAuthService()
//        self.walletAccount = try! WalletAccount(near: self.nearFake,
//                                                storage: self.testStorage,
//                                                authService: self.authService)
//      }
//
//      afterEach {
//        try! self.testStorage.removeAll()
//      }
//
//      it("not signed in by default") {
//        expect(self.walletAccount.isSignedIn()).notTo(beTrue())
//      }
//
//      it("can request sign in") {
//        do {
//          try await(self.walletAccount.requestSignIn(contractId: "signInContract",
//                                                      title: "signInTitle",
//                                                      successUrl: URL(string: "customscheme://success"),
//                                                      failureUrl: URL(string: "customscheme://fail"),
//                                                      appUrl: URL(string: "customscheme://")))
//          let accounts = try await(self.keyStore.getAccounts(networkId: "networkId"))
//          expect(accounts).to(haveCount(1))
//          expect(accounts[0]).to(beginWith("pending_key"))
//          expect(self.authService.urls).to(haveCount(1))
//          let newUrl = self.authService.urls.last!
//          expect(newUrl.scheme).to(equal("http"))
//          expect(newUrl.host).to(equal("example.com"))
//          let params = newUrl.queryParameters!
//          expect(params["title"]).to(equal("signInTitle"))
//          expect(params["contract_id"]).to(equal("signInContract"))
//          expect(params["success_url"]).to(equal("customscheme://success"))
//          expect(params["failure_url"]).to(equal("customscheme://fail"))
//          let keyPair = try await(self.keyStore.getKey(networkId: "networkId", accountId: accounts[0]))
//          expect(params["public_key"]).to(equal(keyPair?.getPublicKey().toString()))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//
//      it("can complete sign in") {
//        do {
//          let keyPair = try keyPairFromRandom() as! KeyPairEd25519
//          try await(self.keyStore.setKey(networkId: "networkId",
//                                         accountId: "pending_key" + keyPair.getPublicKey().toString(),
//                                         keyPair: keyPair))
//          let public_key = keyPair.getPublicKey().toString()
//          let url = URL(string: "customscheme://success?account_id=near.account&public_key=\(public_key)")!
//          try await(self.walletAccount.completeSignIn(UIApplication.shared, open: url))
//          let testKeyPair = try await(self.keyStore.getKey(networkId: "networkId",
//                                                           accountId: "near.account"))
//          expect(testKeyPair as? KeyPairEd25519).to(equal(keyPair))
//          expect(self.walletAccount.isSignedIn()).to(beTrue())
//          expect(self.walletAccount.getAccountId()).to(equal("near.account"))
//        } catch let error {
//          fail("\(error)")
//        }
//      }
//    }
//  }
//}
