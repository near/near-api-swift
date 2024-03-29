//
//  AccountViewController.swift
//  nearclientios_Example
//
//  Created by Viktor Siruk on 06.02.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import nearclientios

struct AccountStateField {
  let title: String
  let value: String
}

class AccountViewController: UITableViewController {
  
  private var walletAccount: WalletAccount?
  private var near: Near?
  private var accountState: AccountState?
  private var data = [AccountStateField]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Near account"
    setupSignOutButton()
    Task {
      accountState = try await fetchAccountState()
      await setupData(with: accountState!)
    }
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

extension AccountViewController {
  private func setupSignOutButton() {
    navigationItem.hidesBackButton = true
    let newBackButton = UIBarButtonItem(title: "Sign out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(AccountViewController.back(sender:)))
    self.navigationItem.leftBarButtonItem = newBackButton
  }
  
  @objc private func back(sender: UIBarButtonItem) {
    Task {
      await walletAccount?.signOut()
      navigationController?.popViewController(animated: true)
    }
  }
}

enum AccountError: Error {
  case cannotFetchAccountState
}

extension AccountViewController {
  func setup(near: Near, wallet: WalletAccount) {
    self.near = near
    walletAccount = wallet
  }
  
  private func fetchAccountState() async throws -> AccountState {
    do {
      let account = try await near!.account(accountId: walletAccount!.getAccountId())
      let state = try await account.state()
      return state
    } catch {
      throw AccountError.cannotFetchAccountState
    }
  }
  
  private func setupData(with accountState: AccountState) async {
    data.append(AccountStateField(title: "Account ID", value: await walletAccount!.getAccountId()))
    let account = try! await near!.account(accountId: walletAccount!.getAccountId())
    let accountBalance = try! await account.getAccountBalance()
    let balance = "\(accountBalance.available.toNearAmount(fracDigits: 5)) Ⓝ"
    data.append(AccountStateField(title: "Balance", value: balance))
    data.append(AccountStateField(title: "Storage (used/paid)", value: "\(accountState.storageUsage.toStorageUnit())/\(accountState.storagePaidAt.toStorageUnit())"))
    await MainActor.run {
      tableView.reloadData()
    }
  }
}

extension AccountViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return data.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier")
    if cell == nil {
      cell = UITableViewCell(style: .value1, reuseIdentifier: "cellIdentifier")
    }
    let field = data[indexPath.row]
    cell!.textLabel?.text = field.title
    cell!.detailTextLabel?.text = field.value
    return cell!
  }
}

extension Int {
  func toStorageUnit() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: self))!
  }
}
