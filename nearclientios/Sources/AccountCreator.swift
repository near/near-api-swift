//
//  AccountCreator.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public protocol AccountCreator {
  func createAccount(newAccountId: String, publicKey: PublicKey) async throws -> Void
}

public struct LocalAccountCreator {
  let masterAccount: Account
  let initialBalance: UInt128
}

extension LocalAccountCreator: AccountCreator {
  public func createAccount(newAccountId: String, publicKey: PublicKey) async throws -> Void {
    let _ = try await masterAccount.createAccount(newAccountId: newAccountId, publicKey: publicKey, amount: initialBalance)
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
  public func createAccount(newAccountId: String, publicKey: PublicKey) async throws -> Void {
    // no-op
  }
}
