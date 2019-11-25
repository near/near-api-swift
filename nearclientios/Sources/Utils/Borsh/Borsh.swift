//
//  Borsh.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 23.11.2019.
//

import Foundation

internal typealias BorshCodable = BorshSerializable & BorshDeserializable

internal enum BorshDecodingError: Error {
  case unknownData
}
