//
//  Provider.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit

internal typealias Number = Int

internal struct SyncInfo: Codable {
  let latest_block_hash: String
  let latest_block_height: Number
  let latest_block_time: String
  let latest_state_root: String
  let syncing: Bool
}

internal struct Validator: Codable {}

internal struct NodeStatusResult: Codable {
  let chain_id: String
  let rpc_addr: String
  let sync_info: SyncInfo
  let validators: [Validator]
}

internal typealias BlockHash = String
internal typealias BlockHeight = Number
//typealias BlockId = BlockHash | BlockHeight
// TODO find correct representation way for this
internal typealias BlockId = BlockHash

internal enum ExecutionStatusBasic: String, Decodable {
  case unknown = "Unknown"
  case pending = "Pending"
  case failure = "Failure"
}

internal enum ExecutionStatus: Decodable, Equatable {
  case successValue(String)
  case basic(ExecutionStatusBasic)
  case successReceiptId(String)
  case failure(ExecutionError)

  private enum CodingKeys: String, CodingKey {
    case successValue = "SuccessValue"
    case failure = "Failure"
    case successReceiptId = "SuccessReceiptId"
  }

  init(from decoder: Decoder) throws {
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

internal enum FinalExecutionStatusBasic: String, Codable {
  case notStarted = "NotStarted"
  case started = "Started"
  case failure = "Failure"
}

internal struct ExecutionError: Codable, Equatable{
  let error_message: String?
  let error_type: String?

  init(error_message: String? = nil, error_type: String? = nil) {
    self.error_message = error_message
    self.error_type = error_type
  }
}

internal enum FinalExecutionStatus: Decodable, Equatable {
  case successValue(String)
  case basic(ExecutionStatusBasic)
  case failure(ExecutionError)

  private enum CodingKeys: String, CodingKey {
    case successValue = "SuccessValue"
    case failure = "Failure"
  }

  init(from decoder: Decoder) throws {
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

internal struct ExecutionOutcomeWithId: Decodable, Equatable {
  let id: String
  let outcome: ExecutionOutcome
}

internal struct ExecutionOutcome: Decodable, Equatable {
  let status: ExecutionStatus
  let logs: [String]
  let receipt_ids: [String]
  let gas_burnt: Number
}

internal struct FinalExecutionOutcome: Decodable, Equatable {
  let status: FinalExecutionStatus
  let transaction: ExecutionOutcomeWithId
  let receipts: [ExecutionOutcomeWithId]
}

internal struct TotalWeight: Codable {
  let num: Number
}

internal struct BlockHeader: Codable {
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

internal typealias ChunkHash = String
internal typealias ShardId = Int
// TODO find correct representation way for this
//internal typealias BlockShardId = [BlockId, ShardId]
internal typealias BlockShardId = [BlockId]
// TODO find correct representation way for this
//internal typealias ChunkId = ChunkHash | BlockShardId
internal typealias ChunkId = ChunkHash

internal struct ValidatorProposal: Codable {}

internal struct ChunkHeader: Codable {
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

internal struct Receipt: Codable {}

internal struct ChunkResult: Codable {
  let header: ChunkHeader
  let receipts: [Receipt]
  let transactions: [Transaction]
}

internal struct TransactionBody: Codable {}

internal struct Transaction: Codable {
  let hash: String
  let public_key: String
  let signature: String
  let body: TransactionBody
}

internal struct BlockResult: Codable {
  let header: BlockHeader
  let transactions: [Transaction]
}

internal enum ProviderType {
  case jsonRPC(URL)
}

internal protocol Provider {
  func getNetwork() throws -> Promise<Network>
  func status() throws -> Promise<NodeStatusResult>
  func sendTransaction(signedTransaction: SignedTransaction) throws -> Promise<FinalExecutionOutcome>
  func txStatus(txHash: [UInt8], accountId: String) throws -> Promise<FinalExecutionOutcome>
  func query<T: Decodable>(path: String, data: String) throws -> Promise<T>
  func block(blockId: BlockId) throws -> Promise<BlockResult>
  func chunk(chunkId: ChunkId) throws -> Promise<ChunkResult>
}

internal func getTransactionLastResult(txResult: FinalExecutionOutcome) -> Any? {
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
