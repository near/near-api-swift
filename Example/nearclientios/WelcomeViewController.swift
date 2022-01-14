//
//  ViewController.swift
//  nearclientios
//
//  Created by dmitrykurochka on 10/28/2019.
//  Copyright (c) 2019 dmitrykurochka. All rights reserved.
//

import UIKit
import nearclientios
import PromiseKit
import AwaitKit

protocol WalletSignInDelegate: class {
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
    walletAccount = setupWallet()
    setupUI(with: walletAccount!)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func setupWallet() -> WalletAccount {
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
    return try! WalletAccount(near: near!)
  }
  
  private func setupUI(with wallet: WalletAccount) {
    if wallet.isSignedIn() {
     showAccountState(with: wallet)
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
    let appName = UIApplication.name ?? "signInTitle"
    (UIApplication.shared.delegate as? AppDelegate)?.walletSignIn = self
    try! `await`(walletAccount!.requestSignIn(contractId: "farts.testnet",
                                            title: appName,
                                            successUrl: URL(string: "nearclientios://success"),
                                            failureUrl: URL(string: "nearclientios://fail"),
                                            appUrl: URL(string: "nearclientios://")))
  }
}

extension WelcomeViewController: WalletSignInDelegate {
  func completeSignIn(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
    do {
      try `await`(walletAccount!.completeSignIn(app, open: url, options: options))
    } catch {
      let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
      present(alert, animated: true, completion: nil)
    }
    setupUI(with: walletAccount!)
  }
}

