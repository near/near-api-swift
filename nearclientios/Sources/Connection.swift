//
//  Connection.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

internal protocol ConnectionConfigProtocol {
  var networkId: String {get}
  var providerType: ProviderType {get}
  var signerType: SignerType {get}
}

internal struct ConnectionConfig: ConnectionConfigProtocol {
  let networkId: String
  let providerType: ProviderType
  let signerType: SignerType
}

internal extension ConnectionConfigProtocol {
  func provider() -> Provider {
    switch providerType {
    case .jsonRPC(let url): return JSONRPCProvider(url: url)
    }
  }
}

internal extension ConnectionConfigProtocol {
  func signer() -> Signer {
    switch signerType {
    case .inMemory(let keyStore): return InMemorySigner(keyStore: keyStore)
    }
  }
}

internal struct Connection {
  let networkId: String
  let provider: Provider
  let signer: Signer
}

internal extension Connection {
  static func fromConfig(config: ConnectionConfigProtocol) throws -> Connection {
    let provider = config.provider()
    let signer = config.signer()
    return Connection(networkId: config.networkId, provider: provider, signer: signer)
  }
}
