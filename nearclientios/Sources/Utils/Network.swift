//
//  Network.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

internal protocol Network {
  var name: String {get}
  var chainId: String {get}
  var _defaultProvider: ((_ providers: Any) -> Any)? {get}
}

extension Network {
  var _defaultProvider: ((_ providers: Any) -> Any)? {return nil}
}

internal struct NetworkImpl: Network {
  let name: String
  let chainId: String
}
