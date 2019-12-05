//
//  FixedLengthByteArray.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 25.11.2019.
//

import Foundation

internal protocol FixedLengthByteArray {
  static var fixedLength: UInt32 {get}
  var bytes: [UInt8] {get}
  init(bytes: [UInt8]) throws
}

extension FixedLengthByteArray {
  func serialize(to writer: inout Data) throws {
    writer.append(bytes, count: Int(Self.fixedLength))
  }

  init(from reader: inout BinaryReader) throws {
    try self.init(bytes: reader.read(count: Self.fixedLength))
  }
}
