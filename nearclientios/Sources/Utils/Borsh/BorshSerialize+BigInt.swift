//
//  BorshSerialize+BigInt.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 21.11.2019.
//

import Foundation
import BigInt

extension BigUInt: BorshSerializable {
  func serialize(to data: inout Data) throws {
    let bytes = serialize() //big-endian
    //TODO convert to little endian
    data.append(contentsOf: bytes.bytes)
  }
}

//extension BigInt: BorshSerializable {
//  func serialize(to data: inout Data) throws {
    //TODO implement
//    throw fatalError("Not implemented yet")
//  }
//}
