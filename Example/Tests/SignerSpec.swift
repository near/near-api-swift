//
//  SignerSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 28.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios

class SignerSpec: XCTestCase {
  func testNoKeyThrowsError() async throws {
    let signer = InMemorySigner(keyStore: InMemoryKeyStore())
    await XCTAssertThrowsError(try await signer.signMessage(message: "message".baseDecoded, accountId: "user", networkId: "network")) { error in
      XCTAssertTrue(error is InMemorySignerError)
    }
  }
}
