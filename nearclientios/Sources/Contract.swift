//
//  Contract.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

//TODO complete this part

internal protocol ContractOptionsProtocol {
  var viewMethods: [String] {get}
  var changeMethods: [String] {get}
  var sender: String? {get}
}

internal struct ContractOptions: ContractOptionsProtocol {
  let viewMethods: [String]
  let changeMethods: [String]
  let sender: String?
}

internal struct Contract {
  let account: Account
  let contractId: String
  let viewMethods: [String]
  let changeMethods: [String]
  let sender: String?
}

extension Contract {
  init(account: Account, contractId: String, options:  ContractOptionsProtocol) {
    self.init(account: account, contractId: contractId, viewMethods: options.viewMethods, changeMethods: options.changeMethods, sender: nil)
  }
}
