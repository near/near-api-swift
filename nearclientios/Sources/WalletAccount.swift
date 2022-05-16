//
//  WalletAccount.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import KeychainAccess

public let APP_SCHEME = "x-nearclientios"

let LOGIN_WALLET_URL_SUFFIX = "/login/"

let LOCAL_STORAGE_KEY_SUFFIX = "_wallet_auth_key"

/// storage key for a pending access key (i.e. key has been generated but we are not sure it was added yet)
let PENDING_ACCESS_KEY_PREFIX = "pending_key"

public protocol AuthDataProtocol {
  var accountId: String? {get}
}

public struct AuthData: AuthDataProtocol {
  public let accountId: String?
}

public enum WalletAccountError: Error {
  case noKeyStore
  case noKeyPair
  case noRegisteredURLSchemes
  case successUrlWrongScheme
  case failureUrlWrongScheme
  case callbackUrlParamsNotValid
}

public protocol WalletStorage: AnyObject {
  subscript(key: String) -> String? {get set}
}

public let WALLET_STORAGE_SERVICE = "nearlib.wallet"

extension Keychain: WalletStorage {}

public protocol ExternalAuthService {
  func openURL(_ url: URL, presentingViewController: UIViewController) -> Bool
}

public actor WalletAccount {
  private let _walletBaseUrl: String
  private let _authDataKey: String
  private let _keyStore: KeyStore
  private var _authData: AuthDataProtocol
  private let _networkId: String
  private let storage: WalletStorage
  private let authService: ExternalAuthService

  public init(near: Near, authService: ExternalAuthService, appKeyPrefix: String? = nil,
       storage: WalletStorage = Keychain(service: WALLET_STORAGE_SERVICE)) throws {
    let keyPrefix = appKeyPrefix ?? (near.config.contractName ?? "default")
    let authDataKey = keyPrefix + LOCAL_STORAGE_KEY_SUFFIX
    guard let keyStore = (near.connection.signer as? InMemorySigner)?.keyStore else {throw WalletAccountError.noKeyStore}
    let authData = AuthData(accountId: storage[authDataKey])
    _walletBaseUrl = near.config.walletUrl
    _authDataKey = authDataKey
    _keyStore = keyStore
    _authData = authData
    _networkId = near.config.networkId
    self.storage = storage
    self.authService = authService
  }
}

extension WalletAccount {
  /**
   - Example:
        walletAccount.isSignedIn()
   - Returns: Returns true, if this WalletAccount is authorized with the wallet.
   */
  public func isSignedIn() -> Bool {
      return _authData.accountId != nil
  }

  /**
   - Example:
        walletAccount.getAccountId()
    - Returns: Authorized Account ID.
   */
  public func getAccountId() -> String {
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
  @discardableResult
  public func requestSignIn(contractId: String?, title: String, presentingViewController: UIViewController, successUrl: URL = URL(string: APP_SCHEME + "://success")!, failureUrl: URL = URL(string: APP_SCHEME + "://fail")!, appUrl: URL = URL(string: APP_SCHEME + "://")!, curve: KeyType = .ED25519) async throws -> Bool {
    guard getAccountId().isEmpty else {return true}
    guard try await _keyStore.getKey(networkId: _networkId, accountId: getAccountId()) == nil else {return true}
    
    var newUrlComponents = URLComponents(string: _walletBaseUrl + LOGIN_WALLET_URL_SUFFIX)
    let title = URLQueryItem(name: "referrer", value: title)
    let contract_id = URLQueryItem(name: "contract_id", value: contractId)
    let success_url = URLQueryItem(name: "success_url", value: successUrl.absoluteString)
    let failure_url = URLQueryItem(name: "failure_url", value: failureUrl.absoluteString)
    let app_url = URLQueryItem(name: "app_url", value: appUrl.absoluteString)
    let accessKey = try keyPairFromRandom(curve: curve)
    let public_key = URLQueryItem(name: "public_key", value: accessKey.getPublicKey().toString())
    
    newUrlComponents?.queryItems = [title, contract_id, success_url, failure_url, app_url, public_key]
    let accountId = PENDING_ACCESS_KEY_PREFIX + accessKey.getPublicKey().toString()
    try await _keyStore.setKey(networkId: _networkId, accountId: accountId, keyPair: accessKey)
    if let openUrl = newUrlComponents?.url {
      return await MainActor.run {
        authService.openURL(openUrl, presentingViewController: presentingViewController)
      }
    }
    return false
  }

  /**
      Complete sign in for a given account id and public key. To be invoked by the app when getting a callback from the wallet.
   */
  public func completeSignIn(url: URL) async throws -> Void {
    guard let params = url.queryParameters else {throw WalletAccountError.callbackUrlParamsNotValid}
    if let publicKey = params["public_key"], let accountId = params["account_id"] {
      _authData = AuthData(accountId: accountId)
      storage[_authDataKey] = accountId
      try await _moveKeyFromTempToPermanent(accountId: accountId, publicKey: publicKey)
    }
  }
  
  public func completeSignIn(withKeyPair keyPair: KeyPair, accountId: String) async throws -> Void {
    _authData = AuthData(accountId: accountId)
    storage[_authDataKey] = accountId
    try await _keyStore.setKey(networkId: _networkId, accountId: accountId, keyPair: keyPair)
  }

  private func _moveKeyFromTempToPermanent(accountId: String, publicKey: String) async throws -> Void {
    let pendingAccountId = PENDING_ACCESS_KEY_PREFIX + publicKey
    guard let keyPair = try await (_keyStore.getKey(networkId: _networkId,
                                                   accountId: pendingAccountId)) else {throw WalletAccountError.noKeyPair}
    try await _keyStore.setKey(networkId: _networkId, accountId: accountId, keyPair: keyPair)
    try await _keyStore.removeKey(networkId: _networkId, accountId: PENDING_ACCESS_KEY_PREFIX + publicKey)
  }

  /**
    Sign out from the current account
   */
  public func signOut() {
    _authData = AuthData(accountId: nil)
    storage[_authDataKey] = nil
  }
}
