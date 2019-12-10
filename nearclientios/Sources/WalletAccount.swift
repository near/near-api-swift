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
import KeychainAccess

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
  case noRegisteredURLSchemes
  case successUrlWrongScheme
  case failureUrlWrongScheme
  case callbackUrlParamsNotValid
}

internal protocol WalletStorage: class {
  subscript(key: String) -> String? {get set}
}

internal struct WalletAccount {
  private let _walletBaseUrl: String
  private let _authDataKey: String
  private let _keyStore: KeyStore
  private var _authData: AuthDataProtocol
  private let _networkId: String
  private let storage: WalletStorage
}

let WALLET_STORAGE_SERVICE = "nearlib.wallet"

extension Keychain: WalletStorage {}

extension WalletAccount {
  init(near: Near, appKeyPrefix: String? = nil,
       storage: WalletStorage = Keychain(service: WALLET_STORAGE_SERVICE)) throws {
    let keyPrefix = appKeyPrefix ?? (near.config.contractName ?? "default")
    let authDataKey = keyPrefix + LOCAL_STORAGE_KEY_SUFFIX
    guard let keyStore = (near.connection.signer as? InMemorySigner)?.keyStore else {throw WalletAccountError.noKeyStore}
    let authData = AuthData(accountId: storage[authDataKey])
    self.init(_walletBaseUrl: near.config.walletUrl, _authDataKey: authDataKey,
              _keyStore: keyStore, _authData: authData, _networkId: near.config.networkId, storage: storage)
  }
}

extension WalletAccount {
  /**
   - Example:
        walletAccount.isSignedIn()
   - Returns: Returns true, if this WalletAccount is authorized with the wallet.
   */
  func isSignedIn() -> Bool {
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
  func requestSignIn(contractId: String, title: String,
                     successUrl: URL? = nil, failureUrl: URL? = nil, appUrl: URL? = nil) throws -> Promise<Void> {
    guard getAccountId().isEmpty else {return .value(())}
    guard try await(_keyStore.getKey(networkId: _networkId, accountId: getAccountId())) == nil else {return .value(())}

    guard let appUrlSchemes = UIApplication.urlSchemes?.compactMap(URL.init(string:)), !appUrlSchemes.isEmpty else {
      throw WalletAccountError.noRegisteredURLSchemes
    }
    if let successUrlScheme = successUrl?.scheme, appUrlSchemes.map({$0.absoluteString}).filter({$0.hasPrefix(successUrlScheme)}).isEmpty {
      throw WalletAccountError.successUrlWrongScheme
    }
    if let failureUrlScheme = failureUrl?.scheme, appUrlSchemes.map({$0.absoluteString}).filter({$0.hasPrefix(failureUrlScheme)}).isEmpty {
      throw WalletAccountError.failureUrlWrongScheme
    }
    let firstAppUrlScheme = appUrlSchemes.first!
    let redirectUrl = appUrl ?? firstAppUrlScheme.appendingPathComponent("://")
    var newUrlComponents = URLComponents(string: _walletBaseUrl + LOGIN_WALLET_URL_SUFFIX)
    let successUrlPath = (successUrl ?? redirectUrl.appendingPathComponent("success")).absoluteString
    let failureUrlPath = (failureUrl ?? redirectUrl.appendingPathComponent("failure")).absoluteString

    let title = URLQueryItem(name: "title", value: title)
    let contract_id = URLQueryItem(name: "contract_id", value: contractId)
    let success_url = URLQueryItem(name: "success_url", value: successUrlPath)
    let failure_url = URLQueryItem(name: "failure_url", value: failureUrlPath)
    let app_url = URLQueryItem(name: "app_url", value: redirectUrl.absoluteString)
    let accessKey = try keyPairFromRandom(curve: .ED25519)
    let public_key = URLQueryItem(name: "public_key", value: accessKey.getPublicKey().toString())

    newUrlComponents?.queryItems = [title, contract_id, success_url, failure_url, app_url, public_key]
    let accountId = PENDING_ACCESS_KEY_PREFIX + accessKey.getPublicKey().toString()
    try await(_keyStore.setKey(networkId: _networkId, accountId: accountId, keyPair: accessKey))
    if let openUrl = newUrlComponents?.url {
      UIApplication.shared.openURL(openUrl)
    }
    return .value(())
  }

  /**
      Complete sign in for a given account id and public key. To be invoked by the app when getting a callback from the wallet.
   */
  mutating func completeSignIn(_ app: UIApplication,
                      open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) throws {
    guard let params = url.queryParameters else {throw WalletAccountError.callbackUrlParamsNotValid}
    if let publicKey = params["public_key"], let accountId = params["account_id"] {
      _authData = AuthData(accountId: accountId)
      storage[_authDataKey] = accountId
      try await(_moveKeyFromTempToPermanent(accountId: accountId, publicKey: publicKey))
    }
  }

  private func _moveKeyFromTempToPermanent(accountId: String, publicKey: String) throws -> Promise<Void> {
    let accountId = PENDING_ACCESS_KEY_PREFIX + publicKey
    guard let keyPair = try await(_keyStore.getKey(networkId: _networkId,
                                                   accountId: accountId)) else {throw WalletAccountError.noKeyPair}
    try await(_keyStore.setKey(networkId: _networkId, accountId: accountId, keyPair: keyPair))
    try await(_keyStore.removeKey(networkId: _networkId, accountId: PENDING_ACCESS_KEY_PREFIX + publicKey))
    return .value(())
  }

  /**
    Sign out from the current account
   */
  private mutating func signOut() {
    _authData = AuthData(accountId: nil)
    storage[_authDataKey] = nil
  }
}
