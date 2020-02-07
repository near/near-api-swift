//
//  Connection.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public protocol ConnectionConfigProtocol {
  var networkId: String {get}
  var providerType: ProviderType {get}
  var signerType: SignerType {get}
}

public struct ConnectionConfig: ConnectionConfigProtocol {
  public let networkId: String
  public let providerType: ProviderType
  public let signerType: SignerType
}

public extension ConnectionConfigProtocol {
  func provider() -> Provider {
    switch providerType {
    case .jsonRPC(let url): return JSONRPCProvider(url: url)
    }
  }
}

public extension ConnectionConfigProtocol {
  func signer() -> Signer {
    switch signerType {
    case .inMemory(let keyStore): return InMemorySigner(keyStore: keyStore)
    }
  }
}

public struct Connection {
  let networkId: String
  let provider: Provider
  let signer: Signer
}

public extension Connection {
  static func fromConfig(config: ConnectionConfigProtocol) throws -> Connection {
    let provider = config.provider()
    let signer = config.signer()
    return Connection(networkId: config.networkId, provider: provider, signer: signer)
  }
}
