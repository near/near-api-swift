//
//  Provider.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import AnyCodable

public typealias Number = Int

public struct SyncInfo: Codable {
  let latestBlockHash: String
  let latestBlockHeight: Number
  let latestBlockTime: String
  let latestStateRoot: String
  let syncing: Bool
}

public struct Validator: Codable {}

public struct NodeStatusResult: Codable {
  let chainId: String
  let rpcAddr: String
  let syncInfo: SyncInfo
  let validators: [Validator]
}

public struct NetworkInfoResult: Decodable {
  let peerMaxCount: Number
}

public struct SimpleRPCResult: Decodable {
  public let id: String
  public let jsonrpc: String
  private let result: String
  
  public var hash: String {
    return result
  }

}

public typealias BlockHash = String
public typealias BlockHeight = Number
public enum BlockId {
  case blockHash(String)
  case blockHeight(Int)
}
public enum NullableBlockId {
  case blockHash(String)
  case blockHeight(Int)
  case null
}

public func typeEraseNullableBlockId(blockId: NullableBlockId) -> Any? {
  switch blockId {
  case .blockHeight(let height):
   return height
  case .blockHash(let hash):
    return hash
  case .null:
    return nil
  }
}

public enum BlockReference {
  case blockId(BlockId)
  case finality(Finality)
}

public func typeEraseBlockId(blockId: BlockId) -> Any {
  switch blockId {
  case .blockHeight(let height):
    return height
  case .blockHash(let hash):
    return hash
  }
}

public func typeEraseBlockReferenceParams(blockQuery: BlockReference) -> [String: Any] {
  var params: [String: Any] = [:]
  switch blockQuery {
  case .blockId(let blockId):
    params["block_id"] = typeEraseBlockId(blockId: blockId)
  case .finality(let finality):
    params["finality"] = finality.rawValue
  }
  
  return params
}

public struct AccessKeyWithPublicKey: Codable {
  let accountId: String
  let publicKey: String
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
  let errorMessage: String?
  let errorType: String?

  init(errorMessage: String? = nil, errorType: String? = nil) {
    self.errorMessage = errorMessage
    self.errorType = errorType
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
  let receiptIds: [String]
  let gasBurnt: Number
}

public struct FinalExecutionOutcome: Decodable, Equatable {
  let status: FinalExecutionStatus
  let transactionOutcome: ExecutionOutcomeWithId
  let receiptsOutcome: [ExecutionOutcomeWithId]
  let receipts: AnyDecodable?
}

public struct TotalWeight: Codable {
  let num: Number
}

public struct BlockHeader: Codable {
  let height: Number
  let epochId: String
  let nextEpochId: String
  let hash: String
  let prevHash: String
  let prevStateRoot: String
  let chunkReceiptsRoot: String
  let chunkHeadersRoot: String
  let chunkTxRoot: String
  let outcomeRoot: String
  let chunksIncluded: Number
  let challengesRoot: String
  let timestamp: Number
  let timestampNanosec: String
  let randomValue: String
  let validatorProposals: [ValidatorProposal]
  let chunkMask: [Bool]
  let gasPrice: String
  let rentPaid: String
  let validatorReward: String
  let totalSupply: String
  //let challenges_result: [Any]
  let lastFinalBlock: String
  let lastDsFinalBlock: String
  let nextBpHash: String
  let blockMerkleRoot: String
}

public typealias ChunkHash = String
public typealias ShardId = Number
public struct BlockShardId {
  let blockId: BlockId
  let shardId: ShardId
}

public enum ChunkId {
  case chunkHash(ChunkHash)
  case blockShardId(BlockShardId)
}

public struct ValidatorProposal: Codable {}

public struct ChunkHeader: Codable {
  let chunkHash: ChunkHash
  let prevBlockHash: String
  let outcomeRoot: String
  let prevStateRoot: String
  let encodedMerkleRoot: String
  let encodedLength: Number
  let heightCreated: Number
  let heightIncluded: Number
  let shardId: ShardId
  let gasUsed: Number
  let gasLimit: Number
  let rentPaid: String
  let validatorReward: String
  let balanceBurnt: String
  let outgoingReceiptsRoot: String
  let txRoot: String
  let validatorProposals: [ValidatorProposal]
  let signature: String
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
  let accountId: String
}

public struct BlockChangeResult: Codable {
  let blockHash: String
  let changes: [BlockChange]
}

public struct ChangeResult: Decodable {
  let blockHash: String
  let changes: [AnyDecodable]
}

public struct ExperimentalNearProtocolConfig: Decodable {
  let chainId: String
  let genesisHeight: Number
  let runtimeConfig: ExperimentalNearProtocolRuntimeConfig?
}

public struct ExperimentalNearProtocolRuntimeConfig: Decodable {
  let storageAmountPerByte: String
}

public struct GasPrice: Codable {
  let gasPrice: String
}

public struct EpochValidatorInfo: Decodable {
  // Validators for the current epoch.
  let nextValidators: [NextEpochValidatorInfo]
  // Validators for the next epoch.
  let currentValidators: [CurrentEpochValidatorInfo]
  // Fishermen for the current epoch.
  let nextFishermen: [ValidatorStakeView]
  // Fishermen for the next epoch.
  let currentFishermen: [ValidatorStakeView]
  // Proposals in the current epoch.
  let currentProposals: [ValidatorStakeView]
  // Kickout in the previous epoch.
  let prevEpochKickout: [ValidatorStakeView]
  // Epoch start height.
  let epochStartHeight: Number
}

public struct CurrentEpochValidatorInfo: Decodable {
  let accountId: String
  let publicKey: String
  let isSlashed: Bool
  let stake: String
  let shards: [Number]
  let numProducedBlocks: Number
  let numExpectedBlocks: Number
}

public struct NextEpochValidatorInfo: Decodable {
  let accountId: String
  let publicKey: String
  let stake: String
  let shards: [Number]
}

public struct ValidatorStakeView: Decodable {
  let accountId: String
  let publicKey: String
  let stake: String
}

public enum ProviderType {
  case jsonRPC(URL)
}

public protocol Provider {
  func getNetwork() async throws -> Network
  func status() async throws -> NodeStatusResult
  func networkInfo() async throws -> NetworkInfoResult
  func sendTransaction(signedTransaction: SignedTransaction) async throws -> FinalExecutionOutcome
  func sendTransactionAsync(signedTransaction: SignedTransaction) async throws -> SimpleRPCResult
  func txStatus(txHash: [UInt8], accountId: String) async throws -> FinalExecutionOutcome
  func experimentalTxStatusWithReceipts(txHash: [UInt8], accountId: String) async throws -> FinalExecutionOutcome
  func query<T: Decodable>(params: [String: Any]) async throws -> T
  func block(blockQuery: BlockReference) async throws -> BlockResult
  func blockChanges(blockQuery: BlockReference) async throws -> BlockChangeResult
  func chunk(chunkId: ChunkId) async throws -> ChunkResult
  func gasPrice(blockId: NullableBlockId) async throws -> GasPrice
  func experimentalGenesisConfig() async throws -> ExperimentalNearProtocolConfig
  func experimentalProtocolConfig(blockQuery: BlockReference) async throws -> ExperimentalNearProtocolConfig
  func validators(blockId: NullableBlockId) async throws -> EpochValidatorInfo
  func accessKeyChanges(accountIdArray: [String], blockQuery: BlockReference) async throws -> ChangeResult
  func singleAccessKeyChanges(accessKeyArray: [AccessKeyWithPublicKey], blockQuery: BlockReference) async throws -> ChangeResult
  func accountChanges(accountIdArray: [String], blockQuery: BlockReference) async throws -> ChangeResult
  func contractStateChanges(accountIdArray: [String], blockQuery: BlockReference, keyPrefix: String?) async throws -> ChangeResult
  func contractCodeChanges(accountIdArray: [String], blockQuery: BlockReference) async throws -> ChangeResult
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
