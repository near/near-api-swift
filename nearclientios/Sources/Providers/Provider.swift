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

internal protocol SyncInfo {
  var latest_block_hash: String {get}
  var latest_block_height: Number {get}
  var latest_block_time: String {get}
  var latest_state_root: String {get}
  var syncing: Bool {get}
}

internal protocol NodeStatusResult {
  var chain_id: String {get}
  var rpc_addr: Number {get}
  var sync_info: SyncInfo {get}
  var validators: [String] {get}
}

internal typealias BlockHash = String
internal typealias BlockHeight = Int
//typealias BlockId = BlockHash | BlockHeight
// TODO find correct representation way for this
internal typealias BlockId = BlockHash

internal enum ExecutionStatusBasic: String {
  case unknown = "Unknown"
  case pending = "Pending"
  case failure = "Failure"
}

internal protocol ExecutionStatus {
  var SuccessValue: String? {get}
  var SuccessReceiptId: String? {get}
  var Failure: ExecutionError? {get}
}

internal enum FinalExecutionStatusBasic: String {
    case notStarted = "NotStarted"
    case started = "Started"
    case failure = "Failure"
}

internal protocol ExecutionError {
  var error_message: String {get}
  var error_type: String {get}
}

internal protocol FinalExecutionStatus {
  var SuccessValue: String? {get}
  var Failure: ExecutionError? {get}
}

internal protocol ExecutionOutcomeWithId {
  var id: String {get}
  var outcome: ExecutionOutcome {get}
}

internal protocol ExecutionOutcome {
// TODO find correct representation way for this
//  var status: ExecutionStatus | ExecutionStatusBasic
  var status: ExecutionStatus {get}
  var logs: [String] {get}
  var receipt_ids: [String] {get}
  var gas_burnt: Number {get}
}

internal protocol FinalExecutionOutcome {
  // TODO find correct representation way for this
//    status: FinalExecutionStatus | FinalExecutionStatusBasic
  var status: FinalExecutionStatus {get}
  var transaction: ExecutionOutcomeWithId {get}
  var receipts: [ExecutionOutcomeWithId] {get}
}

internal protocol TotalWeight {
  var num: Number {get}
}

internal protocol BlockHeader {
  var approval_mask: String {get}
  var approval_sigs: String {get}
  var hash: String {get}
  var height: Number {get}
  var prev_hash: String {get}
  var prev_state_root: String {get}
  var timestamp: Number {get}
  var total_weight: TotalWeight {get}
  var tx_root: String {get}
}

internal typealias ChunkHash = String
internal typealias ShardId = Int
// TODO find correct representation way for this
//internal typealias BlockShardId = [BlockId, ShardId]
internal typealias BlockShardId = [BlockId]
// TODO find correct representation way for this
//internal typealias ChunkId = ChunkHash | BlockShardId
internal typealias ChunkId = ChunkHash

internal protocol ChunkHeader {
  var balance_burnt: String {get}
  var chunk_hash: ChunkHash {get}
  var encoded_length: Number {get}
  var encoded_merkle_root: String {get}
  var gas_limit: Number {get}
  var gas_used: Number {get}
  var height_created: Number {get}
  var height_included: Number {get}
  var outgoing_receipts_root: String {get}
  var prev_block_hash: String {get}
  var prev_state_num_parts: Number {get}
  var prev_state_root_hash: String {get}
  var rent_paid: String {get}
  var shard_id: Number {get}
  var signature: String {get}
  var tx_root: String {get}
  var validator_proposals: [Any] {get}
  var validator_reward: String {get}
}

internal protocol ChunkResult {
  var header: ChunkHeader {get}
  var receipts: [Any] {get}
  var transactions: [Transaction] {get}
}

internal protocol Transaction {
  var hash: String {get}
  var public_key: String {get}
  var signature: String {get}
  var body: Any {get}
}

internal enum ProviderType {
  case jsonRPC(URL)
}

internal protocol Provider {
  func getNetwork() -> Promise<Network>
  func status() -> Promise<NodeStatusResult>

  func sendTransaction(signedTransaction: SignedTransaction) -> Promise<FinalExecutionOutcome>
  func txStatus(txHash: [UInt8], accountId: String) -> Promise<FinalExecutionOutcome>
  func query(path: String, data: String) -> Promise<Any>
  func block(blockId: BlockId) -> Promise<BlockResult>
  func chunk(chunkId: ChunkId) -> Promise<ChunkResult>
}

internal func getTransactionLastResult(txResult: FinalExecutionOutcome) -> Any? {
//    if (typeof txResult.status === 'object' && typeof txResult.status.SuccessValue === 'string') {
//        const value = Buffer.from(txResult.status.SuccessValue, 'base64').toString();
//        try {
//            return JSON.parse(value)
//        } catch (e) {
//            return value;
//        }
//    }
    return nil
}
