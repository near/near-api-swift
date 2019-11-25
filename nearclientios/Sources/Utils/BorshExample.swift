//
//  Borsh.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 21.11.2019.
//

import Foundation


struct Man {
  let height: Double
  let weight: Int32
}

extension Man: BorshDeserializable {
  init(from reader: inout BinaryReader) throws {
    self.height = try .init(from: &reader)
    self.weight = try .init(from: &reader)
  }
}

extension Man: BorshSerializable {
  func serialize(to writer: inout Data) throws {
    try height.serialize(to: &writer)
    try weight.serialize(to: &writer)
  }
}

//protocol BorshSchemaProtocol {
//  static var fields: [BorshSchemaField] {get}
//}
//
//protocol BorshSchemaFieldProtocol {
//  var key: String {get}
//  var value: BorshCodable {get}
//}
//
//struct BorshSchemaField: BorshSchemaFieldProtocol {
//  let key: String
//  let value: BorshCodable
//}
//
//extension BorshSerializable {
//  func encode(to encoder: Encoder) throws -> Data {
//    let mirror = Mirror(reflecting: self)
//    for child in mirror.children {
//        print("Property name:", child.label)
//        print("Property value:", child.value)
//    }
//    return Data()
//  }
//}
