//
//  FormatSpec.swift
//  nearclientios_Tests
//
//  Created by Kevin McConnaughay on 3/22/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios

struct YNTestCase {
  let balance: String
  let fracDigits: Int?
  let expected: String
  let expectedDouble: Double
}

struct NYTestCase {
  let amount: String
  let expected: String
}

let yoctoToNearStringTestCases: [YNTestCase] = [
  YNTestCase(balance: "8999999999837087887", fracDigits: nil, expected: "0.000008999999999837087887", expectedDouble: 0.000008999999999837087887),
  YNTestCase(balance: "8099099999837087887", fracDigits: nil, expected: "0.000008099099999837087887", expectedDouble: 0.000008099099999837087887),
  YNTestCase(balance: "999998999999999837087887000", fracDigits: nil, expected: "999.998999999999837087887", expectedDouble: 999.998999999999837087887),
  YNTestCase(balance: "1" + String(repeating: "0", count: 13), fracDigits: nil, expected: "0.00000000001", expectedDouble: 0.00000000001),
  YNTestCase(balance: "9999989999999998370878870000000", fracDigits: nil, expected: "9,999,989.99999999837087887", expectedDouble: 9999989.99999999837087887),
  YNTestCase(balance: "000000000000000000000000", fracDigits: nil, expected: "0", expectedDouble: 0),
  YNTestCase(balance: "1000000000000000000000000", fracDigits: nil, expected: "1", expectedDouble: 1),
  YNTestCase(balance: "999999999999999999000000", fracDigits: nil, expected: "0.999999999999999999", expectedDouble: 0.999999999999999999),
  YNTestCase(balance: "999999999999999999000000", fracDigits: 10, expected: "1", expectedDouble: 1),
  YNTestCase(balance: "1003000000000000000000000", fracDigits: 3, expected: "1.003", expectedDouble: 1.003),
  YNTestCase(balance: "3000000000000000000000", fracDigits: 3, expected: "0.003", expectedDouble: 0.003),
  YNTestCase(balance: "3000000000000000000000", fracDigits: 4, expected: "0.003", expectedDouble: 0.003),
  YNTestCase(balance: "3500000000000000000000", fracDigits: 3, expected: "0.004", expectedDouble: 0.004),
  YNTestCase(balance: "03500000000000000000000", fracDigits: 3, expected: "0.004", expectedDouble: 0.004),
  YNTestCase(balance: "10000000999999997410000000", fracDigits: nil, expected: "10.00000099999999741", expectedDouble: 10.00000099999999741),
  YNTestCase(balance: "10100000999999997410000000", fracDigits: nil, expected: "10.10000099999999741", expectedDouble: 10.10000099999999741),
  YNTestCase(balance: "10040000999999997410000000", fracDigits: 2, expected: "10.04", expectedDouble: 10.04),
  YNTestCase(balance: "10999000999999997410000000", fracDigits: 2, expected: "11", expectedDouble: 11),
  YNTestCase(balance: "1000000100000000000000000000000", fracDigits: nil, expected: "1,000,000.1", expectedDouble: 1000000.1),
  YNTestCase(balance: "1000100000000000000000000000000", fracDigits: nil, expected: "1,000,100", expectedDouble: 1000100),
  YNTestCase(balance: "910000000000000000000000", fracDigits: 0, expected: "1", expectedDouble: 1)
]

let nearStringToYoctoStringTestCases: [NYTestCase] = [
  NYTestCase(amount: "5.3", expected: "5300000000000000000000000"),
  NYTestCase(amount: "5", expected: "5000000000000000000000000"),
  NYTestCase(amount: "1", expected: "1000000000000000000000000"),
  NYTestCase(amount: "10", expected: "10000000000000000000000000"),
  NYTestCase(amount: "0.000008999999999837087887", expected: "8999999999837087887"),
  NYTestCase(amount: "0.000008099099999837087887", expected: "8099099999837087887"),
  NYTestCase(amount: "999.998999999999837087887000", expected: "999998999999999837087887000"),
  NYTestCase(amount: "0.000000000000001", expected: "1000000000"),
  NYTestCase(amount: "0", expected: "0"),
  NYTestCase(amount: "0.000", expected: "0"),
  NYTestCase(amount: "0.000001", expected: "1000000000000000000"),
  NYTestCase(amount: ".000001", expected: "1000000000000000000"),
  NYTestCase(amount: "000000.000001", expected: "1000000000000000000"),
  NYTestCase(amount: "1,000,000.1", expected: "1000000100000000000000000000000"),
]

class FormatSpec: XCTestCase {
  func testFormatNearAmount() throws {
    for testCase in yoctoToNearStringTestCases {
      let balance = UInt128(stringLiteral: testCase.balance)
      let formatResult = balance.toNearAmount(fracDigits: testCase.fracDigits ?? NEAR_NOMINATION_EXP)
      let doubleResult = balance.toNearDouble(fracDigits: testCase.fracDigits ?? NEAR_NOMINATION_EXP)
      XCTAssertEqual(formatResult, testCase.expected)
      XCTAssertTrue(fabs(doubleResult - testCase.expectedDouble) < .ulpOfOne)
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
