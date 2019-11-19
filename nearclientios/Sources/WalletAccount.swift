//
//  WalletAccount.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

let LOGIN_WALLET_URL_SUFFIX = "/login/"

let LOCAL_STORAGE_KEY_SUFFIX = "_wallet_auth_key"

/// storage key for a pending access key (i.e. key has been generated but we are not sure it was added yet)
let PENDING_ACCESS_KEY_PREFIX = "pending_key"

internal protocol AuthDataProtocol {
  var accountId: String? {get}
}

internal struct AuthData: AuthDataProtocol {
  let accountId: String?
}

internal enum WalletAccountError: Error {
  case noKeyStore
  case noKeyPair
}

internal final class WalletAccount {
  private let _walletBaseUrl: String
  private let _authDataKey: String
  private let _keyStore: KeyStore
  private var _authData: AuthDataProtocol
  private let _networkId: String
}

extension WalletAccount {
  init(near: Near, appKeyPrefix: String?) throws {
    let keyPrefix = appKeyPrefix ?? (near.config.contractName ?? "default")
    let authDataKey = keyPrefix + LOCAL_STORAGE_KEY_SUFFIX
    guard let keyStore = (near.connection.signer as? InMemorySigner)?.keyStore else {throw WalletAccountError.noKeyStore}
    //TODO: change
//    this._authData = JSON.parse(window.localStorage.getItem(this._authDataKey) || '{}');
    let authData = AuthData(accountId: "")
    self.init(_walletBaseUrl: near.config.walletUrl, _authDataKey: authDataKey,
                _keyStore: keyStore, _authData: authData, _networkId: near.config.networkId)
  }
}

extension WalletAccount {
  /**
   - Example:
        walletAccount.isSignedIn()
   - Returns: Returns true, if this WalletAccount is authorized with the wallet.
   */
  private func isSignedIn() -> Bool {
      return _authData.accountId != nil
  }

  /**
   - Example:
        walletAccount.getAccountId()
    - Returns: Authorized Account ID.
   */
  private func getAccountId() -> String {
      return _authData.accountId ?? ""
  }

  /**
   Redirects current page to the wallet authentication page.
   - Parameters:
        - contractId: contractId contract ID of the application
        - accountId: title name of the application
        - networkId: successUrl url to redirect on success
        - failureUrl: failureUrl url to redirect on failure
   */
  private func requestSignIn(contractId: String, title: String,
                             successUrl: String, failureUrl: String) throws -> Promise<Void> {
    if try await(_keyStore.getKey(networkId: _networkId, accountId: getAccountId())) != nil {
      return .value(())
    }

    //TODO: was window.location.href. iOS??
//    let currentUrl = URL(window.location.href)
    let currentUrl = URL(string: "")
    var newUrlComponents = URLComponents(string: _walletBaseUrl + LOGIN_WALLET_URL_SUFFIX)

    let title = URLQueryItem(name: "title", value: title)
    let contract_id = URLQueryItem(name: "contract_id", value: contractId)
    let success_url = URLQueryItem(name: "success_url", value: successUrl)
    let failure_url = URLQueryItem(name: "failure_url", value: failureUrl)
    let app_url = URLQueryItem(name: "app_url", value: currentUrl?.absoluteString)
    let accessKey = try keyPairFromRandom(curve: .ED25519)
    let public_key = URLQueryItem(name: "public_key", value: accessKey.getPublicKey().toString())

    newUrlComponents?.queryItems = [title, contract_id, success_url, failure_url, app_url, public_key]
    let accountId = PENDING_ACCESS_KEY_PREFIX + accessKey.getPublicKey().toString()
    try await(_keyStore.setKey(networkId: _networkId,
                                 accountId: accountId,
                                 keyPair: accessKey))
//    TODO: ??
//    window.location.assign(newUrlComponents?.url)
  }

  /**
      Complete sign in for a given account id and public key. To be invoked by the app when getting a callback from the wallet.
   */
  private func _completeSignInWithAccessKey() {
    // TODO??
    //      let currentUrl = URL(window.location.href)
//    let currentUrl = URL(string: "")
//    if let publicKey = currentUrl?.query.get("public_key"),
//      let accountId = currentUrl?.query.get("account_id") {
//      _authData = AuthData(accountId: accountId)
      //TODO ??
//      window.localStorage.setItem(this._authDataKey, JSON.stringify(this._authData))
//      try await(_moveKeyFromTempToPermanent(accountId, publicKey))
//    }
//    currentUrl.searchParams.delete("public_key")
//    currentUrl.searchParams.delete("account_id")
//    window.history.replaceState({}, document.title, currentUrl.toString())
  }

  private func _moveKeyFromTempToPermanent(accountId: String, publicKey: String) throws {
    let accountId = PENDING_ACCESS_KEY_PREFIX + publicKey
    guard let keyPair = try await(_keyStore.getKey(networkId: _networkId,
                                                   accountId: accountId)) else {throw WalletAccountError.noKeyPair}
    try await(_keyStore.setKey(networkId: _networkId, accountId: accountId, keyPair: keyPair))
    try await(_keyStore.removeKey(networkId: _networkId, accountId: PENDING_ACCESS_KEY_PREFIX + publicKey))
  }

  /**
    Sign out from the current account
   */
  private func signOut() {
    _authData = AuthData(accountId: nil)
    //TODO:
//    window.localStorage.removeItem(this._authDataKey)
  }
}
