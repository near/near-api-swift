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

internal struct ExecutionError {
  var error_message: String
  var error_type: String
}

internal enum FinalExecutionStatus {
  case SuccessValue(String?)
  case Failure(ExecutionError)
}

internal struct ExecutionOutcomeWithId {
  let id: String
  let outcome: ExecutionOutcome
}

internal struct ExecutionOutcome {
// TODO find correct representation way for this
//  var status: ExecutionStatus | ExecutionStatusBasic
  let status: ExecutionStatus
  let logs: [String]
  let receipt_ids: [String]
  let gas_burnt: Number
}

internal struct FinalExecutionOutcome {
  // TODO find correct representation way for this
//    status: FinalExecutionStatus | FinalExecutionStatusBasic
  let status: FinalExecutionStatus
  let transaction: ExecutionOutcomeWithId
  let receipts: [ExecutionOutcomeWithId]
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

internal protocol BlockResult {
  var header: BlockHeader {get}
  var transactions: [Transaction] {get}
}

func adaptTransactionResult(txResult: Data) -> FinalExecutionOutcome {
    // Fixing legacy transaction result
//    if ('transactions' in txResult) {
//        txResult = txResult as LegacyFinalTransactionResult;
//        let status;
//        if (txResult.status === LegacyFinalTransactionStatus.Unknown) {
//            status = FinalExecutionStatusBasic.NotStarted;
//        } else if (txResult.status === LegacyFinalTransactionStatus.Started) {
//            status = FinalExecutionStatusBasic.Started;
//        } else if (txResult.status === LegacyFinalTransactionStatus.Failed) {
//            status = FinalExecutionStatusBasic.Failure;
//        } else if (txResult.status === LegacyFinalTransactionStatus.Completed) {
//            let result = '';
//            for (let i = txResult.transactions.length - 1; i >= 0; --i) {
//                const r = txResult.transactions[i];
//                if (r.result && r.result.result && r.result.result.length > 0) {
//                    result = r.result.result;
//                    break;
//                }
//            }
//            status = {
//                SuccessValue: result,
//            };
//        }
//        txResult = {
//            status,
//            transaction: mapLegacyTransactionLog(txResult.transactions.splice(0, 1)[0]),
//            receipts: txResult.transactions.map(mapLegacyTransactionLog),
//        };
//    }
//
//    // Adapting from old error handling.
//    txResult.transaction = fixLegacyBasicExecutionOutcomeFailure(txResult.transaction);
//    txResult.receipts = txResult.receipts.map(fixLegacyBasicExecutionOutcomeFailure);
//
//    // Fixing master error status
//    if (txResult.status === FinalExecutionStatusBasic.Failure) {
//        const err = ([txResult.transaction, ...txResult.receipts]
//            .find(t => typeof t.outcome.status === 'object' && typeof t.outcome.status.Failure === 'object')
//            .outcome.status as ExecutionStatus).Failure;
//        txResult.status = {
//            Failure: err
//        };
//    }

//    return txResult;
}

internal enum ProviderType {
  case jsonRPC(URL)
}

internal protocol Provider {
  func getNetwork() -> Promise<Network>
  func status() -> Promise<NodeStatusResult>

  func sendTransaction(signedTransaction: SignedTransaction) -> Promise<FinalExecutionOutcome>
  func txStatus(txHash: [UInt8], accountId: String) -> Promise<FinalExecutionOutcome>
  func query<T: Codable>(path: String, data: String) -> Promise<T>
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
