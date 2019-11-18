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

  private func sendJsonRpc(method: String, params: [Any]) -> Promise<Data> {
    let request: [String: Any] = ["method": method,
                                  "params": params,
                                  "id": getId(),
                                  "jsonrpc": "2.0"]
    return fetchJson(connection: connection, json: request)
  }
}

extension JSONRPCProvider: Provider {
  func getNetwork() -> Promise<Network> {
    let result: Network = NetworkImpl(name: "test", chainId: "test")
    return .value(result)
  }

  func status() -> Promise<NodeStatusResult> {
    return sendJsonRpc(method: "status", params: [])
      .then {response -> Promise<NodeStatusResult> in
        do {
          let result = try JSONDecoder().decode(NodeStatusResult.self, from: response)
          return Promise.value(result)
        } catch let error {
          return Promise(error: error)
        }
    }
  }

  func sendTransaction(signedTransaction: SignedTransaction) -> Promise<FinalExecutionOutcome> {
    let bytes = signedTransaction.encode()
    let params = [Data(bytes: bytes, count: bytes.count).base64EncodedString()]
    return sendJsonRpc(method: "broadcast_tx_commit", params: params)
      .map(adaptTransactionResult)
  }

  func txStatus(txHash: [UInt8], accountId: String) -> Promise<FinalExecutionOutcome> {
    let params = [txHash.baseEncoded, accountId]
    return sendJsonRpc(method: "tx", params: params)
      .map(adaptTransactionResult)
  }

  func query<T: Codable>(path: String, data: String) -> Promise<T> {
    return sendJsonRpc(method: "query", params: [path, data])
      .then { response -> Promise<T> in
        do {
          let result = try JSONDecoder().decode(T.self, from: response)
          return Promise.value(result)
        } catch let error {
          return Promise(error: error)
        }
    }
//      Error("Quering \(path) failed: \(error.localizedDescription).\n\(JSON.stringify(result, null, 2))")
  }

  func block(blockId: BlockId) -> Promise<BlockResult> {
    return sendJsonRpc(method: "block", params: [blockId])
  }

  func chunk(chunkId: ChunkId) -> Promise<ChunkResult> {
    return sendJsonRpc(method: "chunk", params: [chunkId])
  }
}
