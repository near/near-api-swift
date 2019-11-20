//
//  AccountCreator.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit
import BigInt

internal protocol AccountCreator {
  func createAccount(newAccountId: String, publicKey: PublicKey) throws -> Promise<Void>
}

internal struct LocalAccountCreator {
  let masterAccount: Account
  let initialBalance: BigInt
}

extension LocalAccountCreator: AccountCreator {
  func createAccount(newAccountId: String, publicKey: PublicKey) throws -> Promise<Void> {
    return try masterAccount.createAccount(newAccountId: newAccountId, publicKey: publicKey, amount: initialBalance).asVoid()
  }
}

internal struct UrlAccountCreator {
  let connection: Connection
  let helperConnection: ConnectionInfo
}

extension UrlAccountCreator {
  init(connection: Connection, helperUrl: URL) {
    self.init(connection: connection, helperConnection: ConnectionInfo(url: helperUrl))
  }
}

extension UrlAccountCreator: AccountCreator {
  func createAccount(newAccountId: String, publicKey: PublicKey) throws -> Promise<Void> {
    return .value(())
  }
}
