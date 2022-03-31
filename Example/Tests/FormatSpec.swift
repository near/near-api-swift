//
//  FormatSpec.swift
//  nearclientios_Tests
//
//  Created by Kevin McConnaughay on 3/22/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios

struct ynTestCase {
  let balance: String
  let fracDigits: Int?
  let expected: String
}

struct nyTestCase {
  let amount: String
  let expected: String
}

let yoctoToNearStringTestCases: [ynTestCase] = [
  ynTestCase(balance: "8999999999837087887", fracDigits: nil, expected: "0.000008999999999837087887"),
  ynTestCase(balance: "8099099999837087887", fracDigits: nil, expected: "0.000008099099999837087887"),
  ynTestCase(balance: "999998999999999837087887000", fracDigits: nil, expected: "999.998999999999837087887"),
  ynTestCase(balance: "1" + String(repeating: "0", count: 13), fracDigits: nil, expected: "0.00000000001"),
  ynTestCase(balance: "9999989999999998370878870000000", fracDigits: nil, expected: "9,999,989.99999999837087887"),
  ynTestCase(balance: "000000000000000000000000", fracDigits: nil, expected: "0"),
  ynTestCase(balance: "1000000000000000000000000", fracDigits: nil, expected: "1"),
  ynTestCase(balance: "999999999999999999000000", fracDigits: nil, expected: "0.999999999999999999"),
  ynTestCase(balance: "999999999999999999000000", fracDigits: 10, expected: "1"),
  ynTestCase(balance: "1003000000000000000000000", fracDigits: 3, expected: "1.003"),
  ynTestCase(balance: "3000000000000000000000", fracDigits: 3, expected: "0.003"),
  ynTestCase(balance: "3000000000000000000000", fracDigits: 4, expected: "0.003"),
  ynTestCase(balance: "3500000000000000000000", fracDigits: 3, expected: "0.004"),
  ynTestCase(balance: "03500000000000000000000", fracDigits: 3, expected: "0.004"),
  ynTestCase(balance: "10000000999999997410000000", fracDigits: nil, expected: "10.00000099999999741"),
  ynTestCase(balance: "10100000999999997410000000", fracDigits: nil, expected: "10.10000099999999741"),
  ynTestCase(balance: "10040000999999997410000000", fracDigits: 2, expected: "10.04"),
  ynTestCase(balance: "10999000999999997410000000", fracDigits: 2, expected: "11"),
  ynTestCase(balance: "1000000100000000000000000000000", fracDigits: nil, expected: "1,000,000.1"),
  ynTestCase(balance: "1000100000000000000000000000000", fracDigits: nil, expected: "1,000,100"),
  ynTestCase(balance: "910000000000000000000000", fracDigits: 0, expected: "1")
]

let nearStringToYoctoStringTestCases: [nyTestCase] = [
  nyTestCase(amount: "5.3", expected: "5300000000000000000000000"),
  nyTestCase(amount: "5", expected: "5000000000000000000000000"),
  nyTestCase(amount: "1", expected: "1000000000000000000000000"),
  nyTestCase(amount: "10", expected: "10000000000000000000000000"),
  nyTestCase(amount: "0.000008999999999837087887", expected: "8999999999837087887"),
  nyTestCase(amount: "0.000008099099999837087887", expected: "8099099999837087887"),
  nyTestCase(amount: "999.998999999999837087887000", expected: "999998999999999837087887000"),
  nyTestCase(amount: "0.000000000000001", expected: "1000000000"),
  nyTestCase(amount: "0", expected: "0"),
  nyTestCase(amount: "0.000", expected: "0"),
  nyTestCase(amount: "0.000001", expected: "1000000000000000000"),
  nyTestCase(amount: ".000001", expected: "1000000000000000000"),
  nyTestCase(amount: "000000.000001", expected: "1000000000000000000"),
  nyTestCase(amount: "1,000,000.1", expected: "1000000100000000000000000000000"),
]

class FormatSpec: XCTestCase {
  func testFormatNearAmount() throws {
    for testCase in yoctoToNearStringTestCases {
      let balance = UInt128(stringLiteral: testCase.balance)
      let formatResult = testCase.fracDigits != nil ? balance.toNearAmount(fracDigits: testCase.fracDigits!) : balance.toNearAmount()
      XCTAssertEqual(formatResult, testCase.expected)
    }
  }
  
  func testFormatNearAmountFromString() throws {
    for testCase in yoctoToNearStringTestCases {
      let balance = testCase.balance
      let formatResult = testCase.fracDigits != nil ? balance.toNearAmount(fracDigits: testCase.fracDigits!) : balance.toNearAmount()
      XCTAssertEqual(formatResult, testCase.expected)
    }
  }
  
  func testFormatYoctoAmount() throws {
    for testCase in nearStringToYoctoStringTestCases {
      let formatResult = try testCase.amount.toYoctoNearString()
      XCTAssertEqual(formatResult, testCase.expected)
    }
    
    XCTAssertThrowsError(try "".toYoctoNearString())
    XCTAssertThrowsError(try ".".toYoctoNearString())
  }
}
