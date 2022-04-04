//
//  ViewController.swift
//  nearclientios
//
//  Created by dmitrykurochka on 10/28/2019.
//  Copyright (c) 2019 dmitrykurochka. All rights reserved.
//

import UIKit
import nearclientios

class WelcomeViewController: UIViewController, WalletSignInDelegate {
  
  private var walletAccount: WalletAccount?
  private var near: Near?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task {
      walletAccount = await setupWallet()
      await setupUI(with: walletAccount!)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func setupWallet() async -> WalletAccount {
    let keyStore = KeychainKeyStore(keychain: .init(service: "example.keystore"))
    let config = NearConfig(
      networkId: "testnet",  // "default" for mainnet
      nodeUrl: URL(string: "https://rpc.testnet.near.org")!, // "https://rpc.mainnet.near.org" for mainnet
      masterAccount: nil,
      keyPath: nil,
      helperUrl: nil,
      initialBalance: nil,
      providerType: .jsonRPC(URL(string: "https://rpc.testnet.near.org")!), // "https://rpc.mainnet.near.org" for mainnet
      signerType: .inMemory(keyStore),
      keyStore: keyStore,
      contractName: nil,
      walletUrl: "https://wallet.testnet.near.org"  // "https://wallet.near.org" for mainnet
    )
    near =  Near(config: config)
    return try! WalletAccount(near: near!, authService: DefaultAuthService.shared) // a failed try here represents a configuration error, not a runtime error. It's safe to store a `WalletAccount!`.
  }
  
  private func setupUI(with wallet: WalletAccount) async {
    if await wallet.isSignedIn() {
      await MainActor.run {
        showAccountState(with: wallet)
      }
    } else {
      //Hide preloader
    }
  }
  
  private func showAccountState(with wallet: WalletAccount) {
    guard let accountVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else {
      return
    }
    accountVC.setup(near: near!, wallet: wallet)
    navigationController?.pushViewController(accountVC, animated: true)
  }
  
  @IBAction func tapShowAuthForm(_ sender: UIButton) {
    Task {
      let appName = UIApplication.name ?? "signInTitle"
      DefaultAuthService.shared.walletSignIn = self
      try! await walletAccount!.requestSignIn(contractId: nil, title: appName, presentingViewController: self)
    }
  }
  
  func completeSignIn(url: URL) async {
    do {
      try await walletAccount?.completeSignIn(url: url)
    } catch {
      await MainActor.run {
        let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { [weak self] _ in
          self?.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
      }
    }
    await setupUI(with: walletAccount!)
  }
}
