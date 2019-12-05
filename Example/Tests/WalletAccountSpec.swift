//
//  WalletAccountSpec.swift
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

class WalletAccountSpec: QuickSpec {

  //  var windowSpy
  //  var documentSpy
  //  var nearFake
  var walletAccount: WalletAccount!
  let keyStore = InMemoryKeyStore()
  let walletUrl = "http://example.com/wallet"

  lazy var nearFake = try! Near(config: NearConfig(networkId: "networkId",
                                                   nodeUrl: URL(string: walletUrl)!,
                                                   masterAccount: nil,
                                                   keyPath: nil,
                                                   helperUrl: nil,
                                                   initialBalance: nil,
                                                   providerType: .jsonRPC(URL(string: walletUrl)!),
                                                   signerType: .inMemory(keyStore),
                                                   keyStore: keyStore,
                                                   contractName: "contractId",
                                                   walletUrl: walletUrl))

  override func spec() {
    describe("WalletAccountSpec") {
      beforeEach {
        self.walletAccount = try! WalletAccount(near: self.nearFake)
      }

      it("not signed in by default") {
        expect(self.walletAccount.isSignedIn()).notTo(beTrue())
      }

      it("can request sign in") {
        //        let newUrl;
        //        windowSpy.mockImplementation(() => ({
        //            location: {
        //                href: 'http://example.com/location',
        //                assign(url) {
        //                    newUrl = url;
        //                }
        //            }
        //        }));

        try! await(self.walletAccount.requestSignIn(contractId: "signInContract",
                                                    title: "signInTitle",
                                                    successUrl: "http://example.com/success",
                                                    failureUrl: "http://example.com/fail"))

        let accounts = try! await(self.keyStore.getAccounts(networkId: "networkId"))
        expect(accounts).to(haveCount(1))
        expect(accounts[0]).to(beginWith("pending_key"))
        //        expect(url.parse(newUrl, true)).toMatchObject({
        //            protocol: 'http:',
        //            host: 'example.com',
        //            query: {
        //                title: 'signInTitle',
        //                contract_id: 'signInContract',
        //                success_url: 'http://example.com/success',
        //                failure_url: 'http://example.com/fail',
        //                public_key: (await keyStore.getKey('networkId', accounts[0])).publicKey.toString()
        //            }
        //        });
      }

//      it("can complete sign in") {
//        let keyPair = try! keyPairFromRandom() as! KeyPairEd25519
        //        var history = []
        //        windowSpy.mockImplementation(() => ({
        //            location: {
        //                href: `http://example.com/location?account_id=near.account&public_key=${keyPair.publicKey}`
        //            },
        //            history: {
        //                replaceState: (state, title, url) => history.push([state, title, url])
        //            },
        //            localStorage
        //        }))
        //        documentSpy.mockImplementation(() => ({
        //            title: 'documentTitle'
        //        }))
//        try! await(self.keyStore.setKey(networkId: "networkId",
//                                        accountId: "pending_key" + keyPair.getPublicKey().toString(),
//                                        keyPair: keyPair))

//        self.walletAccount._completeSignInWithAccessKey()
//        let testKeyPair = try! await(self.keyStore.getKey(networkId: "networkId", accountId: "near.account")) as! KeyPairEd25519
//        expect(testKeyPair).to(equal(keyPair))
        //        expect(localStorage.getItem('contractId_wallet_auth_key'));
        //        expect(history).toEqual([
        //            [{}, 'documentTitle', 'http://example.com/location']
        //        ]);
//      }
    }
  }
}
