//
//  ViewController.swift
//  nearclientios
//
//  Created by dmitrykurochka on 10/28/2019.
//  Copyright (c) 2019 dmitrykurochka. All rights reserved.
//

import UIKit
import nearclientios

protocol WalletSignInDelegate: AnyObject {
  func completeSignIn(_ app: UIApplication,
                      open url: URL, options: [UIApplication.OpenURLOptionsKey: Any])
}

class WelcomeViewController: UIViewController {
  
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
    let keyStore = InMemoryKeyStore()
    let config = NearConfig(networkId: "testnet",
                            nodeUrl: URL(string: "https://rpc.testnet.near.org")!,
                            masterAccount: nil,
                            keyPath: nil,
                            helperUrl: nil,
                            initialBalance: nil,
                            providerType: .jsonRPC(URL(string: "https://rpc.testnet.near.org")!),
                            signerType: .inMemory(keyStore),
                            keyStore: keyStore,
                            contractName: "myContractId",
                            walletUrl: "https://wallet.testnet.near.org")
    near = try! Near(config: config)
    return try! WalletAccount(near: near!, authService: UIApplication.shared)
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
      (UIApplication.shared.delegate as? AppDelegate)?.walletSignIn = self
      try! await walletAccount!.requestSignIn(contractId: "myContractId",
                                            title: appName,
                                            successUrl: URL(string: "nearclientios://success"),
                                            failureUrl: URL(string: "nearclientios://fail"),
                                            appUrl: URL(string: "nearclientios://"))
    }
  }
  
  func _completeSignIn(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) async {
    do {
      try await walletAccount?.completeSignIn(app, open: url, options: options)
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

extension WelcomeViewController: WalletSignInDelegate {
  func completeSignIn(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
    Task {
      await _completeSignIn(app, open: url, options: options)
    }
  }
}

