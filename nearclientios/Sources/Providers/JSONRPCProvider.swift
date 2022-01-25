//
//  JSONRPCProvider.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

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

  private func sendJsonRpc<T: Decodable>(method: String, params: [Any]) async throws -> T {
    let request: [String: Any] = ["method": method,
                                  "params": params,
                                  "id": getId(),
                                  "jsonrpc": "2.0"]
    let json = try await fetchJson(connection: connection, json: request)

    let data = try JSONSerialization.data(withJSONObject: json, options: [])
//    debugPrint("=====================")
//    print(T.self)
//    print(String(decoding: data, as: UTF8.self))
//    debugPrint("=====================")
    do {
      let decoded = try JSONDecoder().decode(T.self, from: data)
      return decoded
    } catch let error {
      print(error)
      print(String(decoding: try! JSONSerialization.data(withJSONObject: request, options: []), as: UTF8.self))
      print(T.self)
      throw error
    }
  }
}

extension JSONRPCProvider: Provider {
  public func getNetwork() async -> Network {
    let result: Network = Network(name: "test", chainId: "test")
    return result
  }

  public func status() async throws -> NodeStatusResult {
    return try await sendJsonRpc(method: "status", params: [])
  }

  public func sendTransaction(signedTransaction: SignedTransaction) async throws -> FinalExecutionOutcome {
    let data = try BorshEncoder().encode(signedTransaction)
    let params = [data.base64EncodedString()]
//    debugPrint("params \(params)")
    return try await sendJsonRpc(method: "broadcast_tx_commit", params: params)
  }

  public func txStatus(txHash: [UInt8], accountId: String) async throws -> FinalExecutionOutcome {
    let params = [txHash.baseEncoded, accountId]
    return try await sendJsonRpc(method: "tx", params: params)
  }

  public func query<T: Decodable>(path: String, data: String) async throws -> T {
    return try await sendJsonRpc(method: "query", params: [path, data])
  }

  public func block(blockId: BlockId) async throws -> BlockResult {
    return try await sendJsonRpc(method: "block", params: [blockId])
  }

  public func chunk(chunkId: ChunkId) async throws -> ChunkResult {
    return try await sendJsonRpc(method: "chunk", params: [chunkId])
  }
}
