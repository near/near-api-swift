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

public protocol AccountCreator {
  func createAccount(newAccountId: String, publicKey: PublicKey) throws -> Promise<Void>
}

public struct LocalAccountCreator {
  let masterAccount: Account
  let initialBalance: UInt128
}

extension LocalAccountCreator: AccountCreator {
  public func createAccount(newAccountId: String, publicKey: PublicKey) throws -> Promise<Void> {
    return try masterAccount.createAccount(newAccountId: newAccountId, publicKey: publicKey, amount: initialBalance).asVoid()
  }
}

public struct UrlAccountCreator {
  let connection: Connection
  let helperConnection: ConnectionInfo
}

extension UrlAccountCreator {
  init(connection: Connection, helperUrl: URL) {
    self.init(connection: connection, helperConnection: ConnectionInfo(url: helperUrl))
  }
}

extension UrlAccountCreator: AccountCreator {
  public func createAccount(newAccountId: String, publicKey: PublicKey) throws -> Promise<Void> {
    return .value(())
  }
}
