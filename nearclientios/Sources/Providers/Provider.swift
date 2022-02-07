//
//  Provider.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

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
public enum BlockId {
  case blockHash(String)
  case blockHeight(Int)
}
public enum GasBlockId {
  case blockHash(String)
  case blockHeight(Int)
  case null
}

public struct BlockReference {
  let blockId: BlockId?
  let finality: Finality?
}


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
    throw NEARDecodingError.notExpected
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
    throw NEARDecodingError.notExpected
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
  private enum CodingKeys : String, CodingKey {
          case status, transaction = "transaction_outcome", receipts = "receipts_outcome"
      }
}

public struct TotalWeight: Codable {
  let num: Number
}

public struct BlockHeader: Codable {
  let height: Number
  let epoch_id: String
  let next_epoch_id: String
  let hash: String
  let prev_hash: String
  let prev_state_root: String
  let chunk_receipts_root: String
  let chunk_headers_root: String
  let chunk_tx_root: String
  let outcome_root: String
  let chunks_included: Number
  let challenges_root: String
  let timestamp: Number
  let timestamp_nanosec: String
  let random_value: String
  let validator_proposals: [ValidatorProposal]
  let chunk_mask: [Bool]
  let gas_price: String
  let rent_paid: String
  let validator_reward: String
  let total_supply: String
  //let challenges_result: [Any]
  let last_final_block: String
  let last_ds_final_block: String
  let next_bp_hash: String
  let block_merkle_root: String
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
  let transactions: [Transaction]?
}

public struct BlockChange: Codable {
  let type: String
  let account_id: String
}

public struct BlockChangeResult: Codable {
  let block_hash: String
  let changes: [BlockChange]
}

public struct ChangeResult: Codable {
  let block_hash: String
  //let changes: [Any]
}

public struct GasPrice: Codable {
  let gas_price: String
}

public enum ProviderType {
  case jsonRPC(URL)
}

public protocol Provider {
  func getNetwork() async throws -> Network
  func status() async throws -> NodeStatusResult
  func sendTransaction(signedTransaction: SignedTransaction) async throws -> FinalExecutionOutcome
  func txStatus(txHash: [UInt8], accountId: String) async throws -> FinalExecutionOutcome
  func query<T: Decodable>(params: [String: Any]) async throws -> T
  func block(blockQuery: BlockReference) async throws -> BlockResult
  func blockChanges(blockQuery: BlockReference) async throws -> BlockChangeResult
  func chunk(chunkId: ChunkId) async throws -> ChunkResult
  func gasPrice(blockId: GasBlockId) async throws -> GasPrice
//  func accessKeyChanges(accountIdArray: [String], blockQuery: BlockReference) async throws -> ChangeResult
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
