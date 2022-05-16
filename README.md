# nearclientios

[![Build Status](https://travis-ci.com/nearprotocol/near-client-ios.svg?branch=master)](https://travis-ci.com/nearprotocol/near-client-ios)
[![Version](https://img.shields.io/cocoapods/v/nearclientios.svg?style=flat)](https://cocoapods.org/pods/nearclientios)
[![License MIT](https://img.shields.io/github/license/nearprotocol/near-client-ios)](https://github.com/nearprotocol/near-client-ios/blob/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/nearclientios.svg?style=flat)](https://cocoapods.org/pods/nearclientios)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

# Usage

```swift
import nearclientios
class ViewController: UIViewController, WalletSignInDelegate {
  private var walletAccount: WalletAccount?
  private var near: Near?

  override func viewDidLoad() {
    super.viewDidLoad()
    let keyStore = KeychainKeyStore(keychain: .init(service: "example.keystore"))
    let config = NearConfig(
      networkId: "testnet", // "default" for mainnet 
      nodeUrl: URL(string: "https://rpc.testnet.near.org")!, // "https://rpc.mainnet.near.org" for mainnet
      masterAccount: nil,
      keyPath: nil,
      helperUrl: nil,
      initialBalance: nil,
      providerType: .jsonRPC(URL(string: "https://rpc.testnet.near.org")!), // "https://rpc.mainnet.near.org" for mainnet
      signerType: .inMemory(keyStore),
      keyStore: keyStore,
      contractName: nil,
      walletUrl: "https://wallet.testnet.near.org" // "https://wallet.near.org" for mainnet
    )
    near = try Near(config: config)
    walletAccount = try! WalletAccount(near: near!, authService: DefaultAuthService.shared) // a failed try here represents a configuration error, not a runtime error. It's safe to store a `WalletAccount!`.
    let appName = UIApplication.name ?? "signInTitle"
    DefaultAuthService.shared.walletSignIn = self
    try! await walletAccount!.requestSignIn(contractId: nil, title: appName, presentingViewController: self)
  }
  func completeSignIn(url: URL) async {
    try! await walletAccount?.completeSignIn(url: url)
    MainActor.run {
      //do any additional UI work on the main thread after sign in is complete
    }
  }
}
```

## Requirements

nearclientios makes use of Swift's async/await and thus requires iOS 13.

## Installation

nearclientios is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'nearclientios'
```

## Author

NEAR Inc

## License

nearclientios is available under the MIT license. See the LICENSE file for more info.
