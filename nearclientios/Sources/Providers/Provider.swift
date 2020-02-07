//
//  Provider.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit

public typealias Number = Int

public struct SyncInfo: Codable {
  let latest_block_hash: String
  let latest_block_height: Number
  let latest_block_time: String
  let latest_state_root: String
  let syncing: Bool
}

public struct Validator: Codable {}

public struct NodeStatusResult: Codable {
  let chain_id: String
  let rpc_addr: String
  let sync_info: SyncInfo
  let validators: [Validator]
}

public typealias BlockHash = String
public typealias BlockHeight = Number
//typealias BlockId = BlockHash | BlockHeight
// TODO find correct representation way for this
public typealias BlockId = BlockHash

public enum ExecutionStatusBasic: String, Decodable {
  case unknown = "Unknown"
  case pending = "Pending"
  case failure = "Failure"
}

public enum ExecutionStatus: Decodable, Equatable {
  case successValue(String)
  case basic(ExecutionStatusBasic)
  case successReceiptId(String)
  case failure(ExecutionError)

  private enum CodingKeys: String, CodingKey {
    case successValue = "SuccessValue"
    case failure = "Failure"
    case successReceiptId = "SuccessReceiptId"
  }

  public init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer(), let status = try? container.decode(ExecutionStatusBasic.self) {
      self = .basic(status)
      return
    }
    let container = try? decoder.container(keyedBy: CodingKeys.self)
    if let value = try? container?.decode(String.self, forKey: .successValue) {
      self = .successValue(value)
      return
    }
    if let value = try? container?.decode(String.self, forKey: .successReceiptId) {
      self = .successReceiptId(value)
      return
    }
    if let value = try? container?.decode(ExecutionError.self, forKey: .failure) {
      self = .failure(value)
      return
    }
    throw DecodingError.notExpected
  }
}

public enum FinalExecutionStatusBasic: String, Codable {
  case notStarted = "NotStarted"
  case started = "Started"
  case failure = "Failure"
}

public struct ExecutionError: Codable, Equatable{
  let error_message: String?
  let error_type: String?

  init(error_message: String? = nil, error_type: String? = nil) {
    self.error_message = error_message
    self.error_type = error_type
  }
}

public enum FinalExecutionStatus: Decodable, Equatable {
  case successValue(String)
  case basic(ExecutionStatusBasic)
  case failure(ExecutionError)

  private enum CodingKeys: String, CodingKey {
    case successValue = "SuccessValue"
    case failure = "Failure"
  }

  public init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer(), let status = try? container.decode(ExecutionStatusBasic.self) {
      self = .basic(status)
      return
    }
    let container = try? decoder.container(keyedBy: CodingKeys.self)
    if let value = try? container?.decode(String.self, forKey: .successValue) {
      self = .successValue(value)
      return
    }
    if let value = try? container?.decode(ExecutionError.self, forKey: .failure) {
      self = .failure(value)
      return
    }
    throw DecodingError.notExpected
  }
}

public struct ExecutionOutcomeWithId: Decodable, Equatable {
  let id: String
  let outcome: ExecutionOutcome
}

public struct ExecutionOutcome: Decodable, Equatable {
  let status: ExecutionStatus
  let logs: [String]
  let receipt_ids: [String]
  let gas_burnt: Number
}

public struct FinalExecutionOutcome: Decodable, Equatable {
  let status: FinalExecutionStatus
  let transaction: ExecutionOutcomeWithId
  let receipts: [ExecutionOutcomeWithId]
}

public struct TotalWeight: Codable {
  let num: Number
}

public struct BlockHeader: Codable {
  let approval_mask: String
  let approval_sigs: String
  let hash: String
  let height: Number
  let prev_hash: String
  let prev_state_root: String
  let timestamp: Number
  let total_weight: TotalWeight
  let tx_root: String
}

public typealias ChunkHash = String
public typealias ShardId = Int
// TODO find correct representation way for this
//public typealias BlockShardId = [BlockId, ShardId]
public typealias BlockShardId = [BlockId]
// TODO find correct representation way for this
//internal typealias ChunkId = ChunkHash | BlockShardId
public typealias ChunkId = ChunkHash

public struct ValidatorProposal: Codable {}

public struct ChunkHeader: Codable {
  let balance_burnt: String
  let chunk_hash: ChunkHash
  let encoded_length: Number
  let encoded_merkle_root: String
  let gas_limit: Number
  let gas_used: Number
  let height_created: Number
  let height_included: Number
  let outgoing_receipts_root: String
  let prev_block_hash: String
  let prev_state_num_parts: Number
  let prev_state_root_hash: String
  let rent_paid: String
  let shard_id: Number
  let signature: String
  let tx_root: String
  let validator_proposals: [ValidatorProposal]
  let validator_reward: String
}

public struct Receipt: Codable {}

public struct ChunkResult: Codable {
  let header: ChunkHeader
  let receipts: [Receipt]
  let transactions: [Transaction]
}

public struct TransactionBody: Codable {}

public struct Transaction: Codable {
  let hash: String
  let public_key: String
  let signature: String
  let body: TransactionBody
}

public struct BlockResult: Codable {
  let header: BlockHeader
  let transactions: [Transaction]
}

public enum ProviderType {
  case jsonRPC(URL)
}

public protocol Provider {
  func getNetwork() throws -> Promise<Network>
  func status() throws -> Promise<NodeStatusResult>
  func sendTransaction(signedTransaction: SignedTransaction) throws -> Promise<FinalExecutionOutcome>
  func txStatus(txHash: [UInt8], accountId: String) throws -> Promise<FinalExecutionOutcome>
  func query<T: Decodable>(path: String, data: String) throws -> Promise<T>
  func block(blockId: BlockId) throws -> Promise<BlockResult>
  func chunk(chunkId: ChunkId) throws -> Promise<ChunkResult>
}

public func getTransactionLastResult(txResult: FinalExecutionOutcome) -> Any? {
  if case .successValue(let value) = txResult.status, let data = Data(base64Encoded: value) {
    do {
      return try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
      return String(data: data,
                    encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
  }
  return nil
}
