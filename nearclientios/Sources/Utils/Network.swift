//
//  Network.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public protocol NetworkProtocol {
  var name: String {get}
  var chainId: String {get}
  var _defaultProvider: ((_ providers: Any) -> Any)? {get}
}

public struct Network: NetworkProtocol {
  public let name: String
  public let chainId: String
  public var _defaultProvider: ((_ providers: Any) -> Any)?
}
