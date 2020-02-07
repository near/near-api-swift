//
//  Borsh.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 23.11.2019.
//

import Foundation

public typealias BorshCodable = BorshSerializable & BorshDeserializable

public enum BorshDecodingError: Error {
  case unknownData
}
