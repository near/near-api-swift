//
//  Connection.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

internal struct ConnectionConfig {
  let networkId: String
  let providerType: ProviderType
  let signerType: SignerType
}


extension ConnectionConfig {
  func provider() -> Provider {
    switch providerType {
    case .jsonRPC(let url): return JSONRPCProvider(url: url)
    }
  }
}

extension ConnectionConfig {
  func signer() -> Signer {
    switch signerType {
    case .inMemory(let keyStore): return InMemorySigner(keyStore: keyStore)
    }
  }
}

internal struct Connection {
  private let networkId: String
  private let provider: Provider
  private let signer: Signer
}

extension Connection {
  static func fromConfig(config: ConnectionConfig) throws -> Connection {
    let provider = config.provider()
    let signer = config.signer()
    return Connection(networkId: config.networkId, provider: provider, signer: signer)
  }
}
