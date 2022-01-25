//
//  KeyStore.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

/**
* Key store interface for `InMemorySigner`.
*/
public protocol KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws -> Void
  func getKey(networkId: String, accountId: String) async throws -> KeyPair?
  func removeKey(networkId: String, accountId: String) async throws -> Void
  func clear() async throws -> Void
  func getNetworks() async throws -> [String]
  func getAccounts(networkId: String) async throws -> [String]
}
