//
//  Network.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

internal protocol NetworkProtocol {
  var name: String {get}
  var chainId: String {get}
  var _defaultProvider: ((_ providers: Any) -> Any)? {get}
}

internal struct Network: NetworkProtocol {
  let name: String
  let chainId: String
  var _defaultProvider: ((_ providers: Any) -> Any)?
}
