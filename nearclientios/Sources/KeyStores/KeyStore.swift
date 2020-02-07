//
//  KeyStore.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit

/**
* Key store interface for `InMemorySigner`.
*/
public protocol KeyStore {
  func setKey(networkId: String, accountId: String, keyPair: KeyPair) -> Promise<Void>
  func getKey(networkId: String, accountId: String) -> Promise<KeyPair?>
  func removeKey(networkId: String, accountId: String) -> Promise<Void>
  func clear() -> Promise<Void>
  func getNetworks() throws -> Promise<[String]>
  func getAccounts(networkId: String) throws -> Promise<[String]>
}
