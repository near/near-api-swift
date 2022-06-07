//
//  Format.swift
//  nearclientios
//
//  Created by Kevin McConnaughay on 3/17/22.
//

import Foundation

// Exponent for calculating how many indivisible units are there in one NEAR.
public let NEAR_NOMINATION_EXP = 24

extension UInt128 {
  
  // Pre-calculate offsets used for rounding to different number of digits
  private static let roundingOffsets: [UInt128] = {
    var offsets: [UInt128] = []
    let multiplier = UInt128(10)
    var offset = UInt128(5)
    for _ in 0..<NEAR_NOMINATION_EXP {
      offsets.append(offset)
      offset *= multiplier
    }
    
    return offsets
  }()
  
  private func nearComponents(fracDigits: Int = NEAR_NOMINATION_EXP, exponent: Int = NEAR_NOMINATION_EXP) -> (String, String) {
    var balance = self
    if fracDigits != exponent {
      // Adjust balance for rounding at given number of digits
      let roundingExp = exponent - fracDigits - 1
      if roundingExp > 0 {
        balance += UInt128.roundingOffsets[roundingExp]
      }
    }
    
    let balanceString = balance.toString()
    let digitOffset = balanceString.count - exponent
    
    let wholeStr = String(digitOffset > 0 ? balanceString.prefix(digitOffset) : "0")
    var fractionStr = String(balanceString.suffix(digitOffset > 0 ? exponent : balanceString.count))
    
    fractionStr = String(String(fractionStr.reversed()).padding(toLength: exponent, withPad: "0", startingAt: 0).reversed())
    fractionStr = String(fractionStr.prefix(fracDigits))
    return (wholeStr, fractionStr)
  }
  
  /// Convert account balance value from internal indivisible units to NEAR.
  /// - Parameter fracDigits: number of fractional digits to preserve in formatted string. Balance is rounded to match given number of digits.
  /// - Returns: Value in Ⓝ
  public func toNearAmount(fracDigits: Int = NEAR_NOMINATION_EXP, withExponent exponent: Int = NEAR_NOMINATION_EXP) -> String {
    let (wholeStr, fractionStr) = nearComponents(fracDigits: fracDigits, exponent: exponent)
    return trimTrailingZeroes(value: "\(formatWithCommas(value: wholeStr)).\(fractionStr)")
  }
  
  /// Convert account balance value from internal indivisible units to NEAR
  /// - Parameter fracDigits: number of fractional digits to preserve in formatted string. Balance is rounded to match given number of digits.
  /// - Returns: Value as double in  Ⓝ
  public func toNearDouble(fracDigits: Int = NEAR_NOMINATION_EXP, withExponent exponent: Int = NEAR_NOMINATION_EXP) -> Double {
    let (wholeStr, fractionStr) = nearComponents(fracDigits: fracDigits, exponent: exponent)
    return Double("\(wholeStr).\(fractionStr)")!
  }
  
}

struct ConversionError: Error {
  let message = "Could not convert string to yoctoNEAR."
}

extension String {
  
  /// Convert human readable NEAR amount to internal indivisible units.
  /// Custom exponent here could be used for Fungible Tokens where the number of decimals differs from NEAR.
  /// - Returns: The parsed yoctoⓃ amount
  public func toYoctoNearString(withExponent exponent: Int = NEAR_NOMINATION_EXP) throws -> String {
    var parsed = self
    // Edge cases not covered by our numberyPattern regex.
    if (parsed == "" || parsed == ".") {
      throw ConversionError()
    }
    parsed = parsed.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    let numberyPattern = "^\\d*\\.?\\d*$"
    let numberyRegex = try! NSRegularExpression(pattern: numberyPattern)
    if numberyRegex.matches(in: parsed, options: [], range: NSRange(location: 0, length: parsed.utf16.count)).count != 1 {
      throw ConversionError()
    }
    parsed = parsed.prefix(1) == "." ? "0\(parsed)" : parsed
    let split = parsed.split(separator: ".")
    let wholePart = split[0]
    let fractionPart = split.indices.contains(1) ? split[1] : ""
    if split.count > 2 || fractionPart.count > exponent {
      throw ConversionError()
    }
    
    return trimLeadingZeroes(value: "\(wholePart)\(fractionPart.padding(toLength: exponent, withPad: "0", startingAt: 0))")
  }
  
  /// Convert human readable NEAR amount to internal indivisible units.
  /// Custom exponent here could be used for Fungible Tokens where the number of decimals differs from NEAR.
  /// - Returns: The parsed yoctoⓃ amount
  public func toYoctoNear(withExponent exponent: Int = NEAR_NOMINATION_EXP) throws -> UInt128 {
    return UInt128(stringLiteral: try self.toYoctoNearString(withExponent: exponent))
  }
  
  /// Convert account balance value from internal indivisible units to NEAR.
  /// - Parameter fracDigits: number of fractional digits to preserve in formatted string. Balance is rounded to match given number of digits.
  /// - Returns: Value in Ⓝ
  public func toNearAmount(fracDigits: Int = NEAR_NOMINATION_EXP) -> String {
    return UInt128(stringLiteral: self).toNearAmount(fracDigits: fracDigits)
  }
  
}

/// Returns a human-readable value with commas
/// - Parameter value: A value that may not contain commas
/// - Returns: A value with commas
private func formatWithCommas(value: String) -> String {
  var formatted = value
  let pattern = "(-?\\d+)(\\d{3})"
  let regex = try! NSRegularExpression(pattern: pattern)
  while regex.matches(in: formatted, options: [], range: NSRange(location: 0, length: formatted.utf16.count)).count > 0 {
    formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: NSRange(0..<formatted.utf16.count), withTemplate: "$1,$2")
  }
  
  return formatted
}

/// Removes leading zeroes from an input
/// - Parameter value: A value that may contain leading zeroes
/// - Returns: The value without the leading zeroes
private func trimLeadingZeroes(value: String) -> String {
  var formatted = value
  let pattern = "^0+"
  let regex = try! NSRegularExpression(pattern: pattern)
  formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: NSRange(0..<formatted.utf16.count), withTemplate: "")
  
  if (formatted == "") {
    return "0"
  }
  
  return formatted
}

/// Removes .000… from an input
/// - Parameter value: A value that may contain trailing zeroes in the decimals place
/// - Returns: The value without the trailing zeros
private func trimTrailingZeroes(value: String) -> String {
  var formatted = value
  let pattern = "\\.?0*$"
  let regex = try! NSRegularExpression(pattern: pattern)
  formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: NSRange(0..<formatted.utf16.count), withTemplate: "")
  
  return formatted
}
