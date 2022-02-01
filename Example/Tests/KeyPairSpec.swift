//
//  KeyPairSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 27.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios

class KeyPairSpec: XCTestCase {
  
  func testSignAndVerify() {
    let keyPair = try! KeyPairEd25519(secretKey: "26x56YPzPDro5t2smQfGcYAPy3j7R2jB2NUb7xKbAGK23B6x4WNQPh3twb6oDksFov5X8ts5CtntUNbpQpAKFdbR")
    XCTAssertEqual(keyPair.getPublicKey().toString(), "ed25519:AYWv9RAN1hpSQA4p1DLhCNnpnNXwxhfH9qeHN8B4nJ59")
    let message = "message".data(using: .utf8)!.digest
    let signature = try! keyPair.sign(message: message)
    XCTAssertEqual(signature.signature.baseEncoded, "26gFr4xth7W9K7HPWAxq3BLsua8oTy378mC1MYFiEXHBBpeBjP8WmJEJo8XTBowetvqbRshcQEtBUdwQcAqDyP8T")
  }
  
  func testSignAndVerifyWithRandom() {
    let keyPair = try! KeyPairEd25519.fromRandom()
    let message = "message".data(using: .utf8)!.digest
    let signature = try! keyPair.sign(message: message)
    XCTAssertTrue(try! keyPair.verify(message: message, signature: signature.signature))
  }
  
  func testSignAndVerifyWithSepc256k1Random() {
    let keyPair = try! KeyPairSecp256k1.fromRandom()
    let message = "message".data(using: .utf8)!.digest
    let signature = try! keyPair.sign(message: message)
    XCTAssertTrue(try! keyPair.verify(message: message, signature: signature.signature))
  }
  
  func testSecp256k1InitFromSecret() {
    let keyPair = try! KeyPairSecp256k1(secretKey: "Cqmi5vHc59U1MHhq7JCxTSJentvVBYMcKGUA7s7kwnKn")
    XCTAssertEqual(keyPair.getPublicKey().toString(), "secp256k1:45KcWwYt6MYRnnWFSxyQVkuu9suAzxoSkUMEnFNBi9kDayTo5YPUaqMWUrf7YHUDNMMj3w75vKuvfAMgfiFXBy28")
  }
  
  func testInitFromSecret() {
    let keyPair = try! KeyPairEd25519(secretKey: "5JueXZhEEVqGVT5powZ5twyPP8wrap2K7RdAYGGdjBwiBdd7Hh6aQxMP1u3Ma9Yanq1nEv32EW7u8kUJsZ6f315C")
    XCTAssertEqual(keyPair.getPublicKey().toString(), "ed25519:EWrekY1deMND7N3Q7Dixxj12wD7AVjFRt2H9q21QHUSW")
  }
  
  func testConvertToString() {
    let keyPair = try! KeyPairEd25519.fromRandom()
    let newKeyPair = try! keyPairFromString(encodedKey: keyPair.toString()) as! KeyPairEd25519
    XCTAssertEqual(newKeyPair.getSecretKey(), keyPair.getSecretKey())
    let keyString = "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw"
    let keyPair2 = try! keyPairFromString(encodedKey: keyString)
    XCTAssertEqual(keyPair2.toString(), keyString)
  }

}
