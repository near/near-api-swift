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

public enum TypedError: Error {
  case error(type: String = "UntypedError", message: String?)
}

public final class JSONRPCProvider {
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
    let json = try await(fetchJson(connection: connection, json: request))
    let data = try JSONSerialization.data(withJSONObject: json, options: [])
//    debugPrint("=====================")
//    debugPrint(json)
//    debugPrint("=====================")
    let decoded = try JSONDecoder().decode(T.self, from: data)
    return .value(decoded)
  }
}

extension JSONRPCProvider: Provider {
  public func getNetwork() -> Promise<Network> {
    let result: Network = Network(name: "test", chainId: "test")
    return .value(result)
  }

  public func status() throws -> Promise<NodeStatusResult> {
    return try sendJsonRpc(method: "status", params: [])
  }

  public func sendTransaction(signedTransaction: SignedTransaction) throws -> Promise<FinalExecutionOutcome> {
    let data = try BorshEncoder().encode(signedTransaction)
    let params = [data.base64EncodedString()]
//    debugPrint("params \(params)")
    return try sendJsonRpc(method: "broadcast_tx_commit", params: params)
  }

  public func txStatus(txHash: [UInt8], accountId: String) throws -> Promise<FinalExecutionOutcome> {
    let params = [txHash.baseEncoded, accountId]
    return try sendJsonRpc(method: "tx", params: params)
  }

  public func query<T: Decodable>(path: String, data: String) throws -> Promise<T> {
    return try sendJsonRpc(method: "query", params: [path, data])
  }

  public func block(blockId: BlockId) throws -> Promise<BlockResult> {
    return try sendJsonRpc(method: "block", params: [blockId])
  }

  public func chunk(chunkId: ChunkId) throws -> Promise<ChunkResult> {
    return try sendJsonRpc(method: "chunk", params: [chunkId])
  }
}
