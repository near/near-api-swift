////
////  KeyPairSpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 27.11.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//@testable import nearclientios
//
//class KeyPairSpec: QuickSpec {
//
//  override func spec() {
//    describe("KeyPair") {
//      it("it should sign and verify") {
//        let keyPair = try! KeyPairEd25519(secretKey: "26x56YPzPDro5t2smQfGcYAPy3j7R2jB2NUb7xKbAGK23B6x4WNQPh3twb6oDksFov5X8ts5CtntUNbpQpAKFdbR")
//        expect(keyPair.getPublicKey().toString()).to(equal("ed25519:AYWv9RAN1hpSQA4p1DLhCNnpnNXwxhfH9qeHN8B4nJ59"))
//        let message = "message".data(using: .utf8)!.digest
//        let signature = try! keyPair.sign(message: message)
//        expect(signature.signature.baseEncoded ).to(equal("26gFr4xth7W9K7HPWAxq3BLsua8oTy378mC1MYFiEXHBBpeBjP8WmJEJo8XTBowetvqbRshcQEtBUdwQcAqDyP8T"))
//      }
//
//      it("it should sign and verify with random") {
//        let keyPair = try! KeyPairEd25519.fromRandom()
//        let message = "message".data(using: .utf8)!.digest
//        let signature = try! keyPair.sign(message: message)
//        expect(try! keyPair.verify(message: message, signature: signature.signature)).to(beTrue())
//      }
//
//      it("it should init from secret") {
//        let keyPair = try! KeyPairEd25519(secretKey: "5JueXZhEEVqGVT5powZ5twyPP8wrap2K7RdAYGGdjBwiBdd7Hh6aQxMP1u3Ma9Yanq1nEv32EW7u8kUJsZ6f315C")
//        expect(keyPair.getPublicKey().toString()).to(equal("ed25519:EWrekY1deMND7N3Q7Dixxj12wD7AVjFRt2H9q21QHUSW"))
//      }
//
//      it("it should convert to string") {
//        let keyPair = try! KeyPairEd25519.fromRandom()
//        let newKeyPair = try! keyPairFromString(encodedKey: keyPair.toString()) as! KeyPairEd25519
//        expect(newKeyPair.getSecretKey()).to(equal(keyPair.getSecretKey()))
//        let keyString = "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw"
//        let keyPair2 = try! keyPairFromString(encodedKey: keyString)
//        expect(keyPair2.toString()).to(equal(keyString))
//      }
//    }
//  }
//}
