//
//  WalletAccount.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

let LOGIN_WALLET_URL_SUFFIX = "/login/"

let LOCAL_STORAGE_KEY_SUFFIX = "_wallet_auth_key"

/// storage key for a pending access key (i.e. key has been generated but we are not sure it was added yet)
let PENDING_ACCESS_KEY_PREFIX = "pending_key"

internal struct WalletAccount {
  private let walletBaseUrl: String
  private let authDataKey: String
  private let keyStore: KeyStore
  private let authData: Any
  private let networkId: String

  init(near: Near, appKeyPrefix: String?) {
//    self.networkId = near.config.networkId
//    self.walletBaseUrl = near.config.walletUrl
//    let appKeyPrefix = appKeyPrefix ?? (near.config.contractName ?? "default")
//    self.authDataKey = appKeyPrefix + LOCAL_STORAGE_KEY_SUFFIX
//    self.keyStore = near.connection.signer.keyStore
//    self.authData =
  }
}
