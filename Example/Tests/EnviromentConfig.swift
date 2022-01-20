//
//  EnviromentConfig.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 27.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

internal enum Environment: String {
  case production, development, local, test, testRemote = "test-remote", ci, ciStaging = "ci-staging"
}

internal struct EnvironmentConfig {
  let networkId: String
  let nodeUrl: URL
  let masterAccount: String
}

func getConfig(env: Environment) -> EnvironmentConfig {
  switch env {
  case .production, .development:
    return EnvironmentConfig(networkId: "default",
                             nodeUrl: URL(string: "https://rpc.nearprotocol.com")!,
                             masterAccount: "test.near")
  case .local:
            //process.env.HOME ?
//            "masterAccount": "\(process.env.HOME)/.near/validator_key.json"]
    return EnvironmentConfig(networkId: "local",
                             nodeUrl: URL(string: "http://localhost:3030")!,
                             masterAccount: "test.near")
  case .test:
    return EnvironmentConfig(networkId: "local",
                             nodeUrl: URL(string: "http://localhost:3030")!,
                             masterAccount: "test.near")
  case .testRemote, .ci:
    return EnvironmentConfig(networkId: "shared-test",
                             nodeUrl: URL(string: "https://rpc.ci-testnet.near.org")!,
                             masterAccount: "test.near")
  case .ciStaging:
    return EnvironmentConfig(networkId: "shared-test-staging",
                             nodeUrl: URL(string: "http://staging-shared-test.nearprotocol.com:3030")!,
                             masterAccount: "test.near")
  }
}
