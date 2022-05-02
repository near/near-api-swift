//
//  BorshEncoder.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 23.11.2019.
//

import Foundation

public struct BorshEncoder {
  public init() {}
  public func encode<T>(_ value: T) throws -> Data where T : BorshSerializable {
    var writer = Data()
    try value.serialize(to: &writer)
    return writer
  }
}
