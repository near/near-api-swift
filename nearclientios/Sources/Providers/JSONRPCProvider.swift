//
//  JSONRPCProvider.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

internal enum TypedError: Error {
  case error(type: String = "UntypedError", message: String?)
}

internal final class JSONRPCProvider {
  /// Keep ids unique across all connections
  private var _nextId = 123

  private let connection: ConnectionInfo

  init(url: URL, network: Network? = nil) {
    self.connection = ConnectionInfo(url: url)
  }
}

extension JSONRPCProvider {
  private func getId() -> Int {
    _nextId += 1
    return _nextId
  }

  private func sendJsonRpc<T: Decodable>(method: String, params: [Any]) throws -> Promise<T> {
    let request: [String: Any] = ["method": method,
                                  "params": params,
                                  "id": getId(),
                                  "jsonrpc": "2.0"]
    return fetchJson(connection: connection, json: request)
      .map {try JSONDecoder().decode(T.self, from: $0)}
  }
}

extension JSONRPCProvider: Provider {
  func getNetwork() -> Promise<Network> {
    let result: Network = Network(name: "test", chainId: "test")
    return .value(result)
  }

  func status() throws -> Promise<NodeStatusResult> {
    return try sendJsonRpc(method: "status", params: [])
  }

  func sendTransaction(signedTransaction: SignedTransaction) throws -> Promise<FinalExecutionOutcome> {
    let bytes = signedTransaction.encode()
    let params = [Data(bytes: bytes, count: bytes.count).base64EncodedString()]
    return try sendJsonRpc(method: "broadcast_tx_commit", params: params)
  }

  func txStatus(txHash: [UInt8], accountId: String) throws -> Promise<FinalExecutionOutcome> {
    let params = [txHash.baseEncoded, accountId]
    return try sendJsonRpc(method: "tx", params: params)
  }

  func query<T: Decodable>(path: String, data: String) throws -> Promise<T> {
    return try sendJsonRpc(method: "query", params: [path, data])
  }

  func block(blockId: BlockId) throws -> Promise<BlockResult> {
    return try sendJsonRpc(method: "block", params: [blockId])
  }

  func chunk(chunkId: ChunkId) throws -> Promise<ChunkResult> {
    return try sendJsonRpc(method: "chunk", params: [chunkId])
  }
}
