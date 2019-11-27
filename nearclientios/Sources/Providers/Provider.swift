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

internal struct NodeStatusResult: Codable {
  let chain_id: String
  let rpc_addr: Number
  let sync_info: SyncInfo
  let validators: [String]
}

internal typealias BlockHash = String
internal typealias BlockHeight = Number
//typealias BlockId = BlockHash | BlockHeight
// TODO find correct representation way for this
internal typealias BlockId = BlockHash

internal enum ExecutionStatusBasic: String {
  case unknown = "Unknown"
  case pending = "Pending"
  case failure = "Failure"
}

internal struct ExecutionStatus: Codable, Equatable {
  let SuccessValue: String?
  let SuccessReceiptId: String?
  let Failure: ExecutionError?

  init(SuccessValue: String? = nil, SuccessReceiptId: String? = nil, Failure: ExecutionError? = nil) {
    self.SuccessValue = SuccessValue
    self.SuccessReceiptId = SuccessReceiptId
    self.Failure = Failure
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

internal struct FinalExecutionStatus: Codable, Equatable {
  let SuccessValue: String?
  let Failure: ExecutionError?

  init(SuccessValue: String? = nil, Failure: ExecutionError? = nil) {
    self.SuccessValue = SuccessValue
    self.Failure = Failure
  }
}

internal struct ExecutionOutcomeWithId: Codable, Equatable {
  let id: String
  let outcome: ExecutionOutcome
}

internal struct ExecutionOutcome: Codable, Equatable {
// TODO find correct representation way for this
//  var status: ExecutionStatus | ExecutionStatusBasic
  let status: ExecutionStatus
  let logs: [String]
  let receipt_ids: [String]
  let gas_burnt: Number
}

internal struct FinalExecutionOutcome: Codable, Equatable {
  // TODO find correct representation way for this
//    status: FinalExecutionStatus | FinalExecutionStatusBasic
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
  if let success = txResult.status.SuccessValue, let data = Data(base64Encoded: success) {
    return try? JSONSerialization.jsonObject(with: data, options: [])
  }
  return nil
}
