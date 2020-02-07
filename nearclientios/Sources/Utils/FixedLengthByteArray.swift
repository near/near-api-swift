//
//  FixedLengthByteArray.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 25.11.2019.
//

import Foundation

public protocol FixedLengthByteArray {
  static var fixedLength: UInt32 {get}
  var bytes: [UInt8] {get}
  init(bytes: [UInt8]) throws
}

extension FixedLengthByteArray {
  public func serialize(to writer: inout Data) throws {
    writer.append(bytes, count: Int(Self.fixedLength))
  }

  public init(from reader: inout BinaryReader) throws {
    try self.init(bytes: reader.read(count: Self.fixedLength))
  }
}
