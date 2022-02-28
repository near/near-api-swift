//
//  ProviderSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 27.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nearclientios

class ProviderSpec: XCTestCase {
  private var provider: Provider!
  override func setUp() {
    let url = getConfig(env: .ci).nodeUrl
    self.provider = JSONRPCProvider(url: url)
  }
  
  func testFetchNodeStatus() async {
    let response = try! await self.provider.status()
    XCTAssertTrue(response.chainId.contains("ci-testnet"))
  }
  
  func testFetchNetworkInfo() async {
    let response = try! await self.provider.networkInfo()
    XCTAssertNotNil(response.peerMaxCount)
  }
  
  func testCorrectFinalTransactionResult() {
    let outcome = ExecutionOutcome(status: .successReceiptId("11112"),
                                   logs: [],
                                   receiptIds: ["11112"],
                                   gasBurnt: 1)
    let transaction = ExecutionOutcomeWithId(id: "11111", outcome: outcome)
    let firstRecipientOutcome = ExecutionOutcome(status: .successValue("e30="),
                                                 logs: [],
                                                 receiptIds: ["11112"],
                                                 gasBurnt: 9001)
    let secondRecipientOutcome = ExecutionOutcome(status: .successValue(""),
                                                  logs: [],
                                                  receiptIds: [],
                                                  gasBurnt: 0)
    let receipts = [ExecutionOutcomeWithId(id: "11112", outcome: firstRecipientOutcome),
                    ExecutionOutcomeWithId(id: "11113", outcome: secondRecipientOutcome)]
    let result = FinalExecutionOutcome(status: .successValue("e30="),
                                       transactionOutcome: transaction,
                                       receiptsOutcome: receipts, receipts: nil)
    XCTAssertNotNil(getTransactionLastResult(txResult: result))
  }
  
  func testFinalTransactionResultWithNil() {
    let outcome = ExecutionOutcome(status: .successReceiptId("11112"),
                                   logs: [],
                                   receiptIds: ["11112"],
                                   gasBurnt: 1)
    let transaction = ExecutionOutcomeWithId(id: "11111", outcome: outcome)
    let firstRecipientOutcome = ExecutionOutcome(status: .failure(ExecutionError()),
                                                 logs: [],
                                                 receiptIds: ["11112"],
                                                 gasBurnt: 9001)
    let secondRecipientOutcome = ExecutionOutcome(status: .successValue(""),
                                                  logs: [],
                                                  receiptIds: [],
                                                  gasBurnt: 0)
    let receipts = [ExecutionOutcomeWithId(id: "11112", outcome: firstRecipientOutcome),
                    ExecutionOutcomeWithId(id: "11113", outcome: secondRecipientOutcome)]
    let result = FinalExecutionOutcome(status: .failure(ExecutionError()),
                                       transactionOutcome: transaction,
                                       receiptsOutcome: receipts, receipts: nil)
    XCTAssertNil(getTransactionLastResult(txResult: result))
  }
  
  func testFetchBlockInfo() async throws {
    let status = try await self.provider.status()
    
    let height = status.syncInfo.latestBlockHeight - 1
    let blockHeight = BlockId.blockHeight(height)
    let response = try await provider.block(blockQuery: BlockReference.blockId(blockHeight))
    XCTAssertEqual(response.header.height, height)
    
    let sameBlock = try await provider.block(blockQuery: BlockReference.blockId(BlockId.blockHash(response.header.hash)))
    XCTAssertEqual(sameBlock.header.height, height)
    
    let optimisticBlock = try await provider.block(blockQuery: BlockReference.finality(Finality.optimistic))
    XCTAssertLessThan(optimisticBlock.header.height - height, 5)
    
    let finalBlock = try await provider.block(blockQuery: BlockReference.finality(Finality.final))
    XCTAssertLessThan(finalBlock.header.height - height, 5)
  }
  
  func testFetchBlockChanges() async throws {
    let status = try await self.provider.status()
    let latestHash = BlockId.blockHash(status.syncInfo.latestBlockHash)
    let blockQuery = BlockReference.blockId(latestHash)
    let response = try await self.provider.blockChanges(blockQuery: blockQuery)
    XCTAssertNotNil(response.blockHash)
    XCTAssertNotNil(response.changes)
    
    let latestHeight = BlockId.blockHeight(status.syncInfo.latestBlockHeight)
    let blockQuery2 = BlockReference.blockId(latestHeight)
    let response2 = try await self.provider.blockChanges(blockQuery: blockQuery2)
    XCTAssertNotNil(response2.blockHash)
    XCTAssertNotNil(response2.changes)
    
    let blockQuery3 = BlockReference.finality(Finality.final)
    let response3 = try await self.provider.blockChanges(blockQuery: blockQuery3)
    XCTAssertNotNil(response3.blockHash)
    XCTAssertNotNil(response3.changes)
  }
  
  func testFetchChunkInfo() async throws {
    let status = try await self.provider.status()
    let height = status.syncInfo.latestBlockHeight - 1
    let blockShardId = BlockShardId(blockId: BlockId.blockHeight(height), shardId: 0)
    let chunkId = ChunkId.blockShardId(blockShardId)
    let response = try await self.provider.chunk(chunkId: chunkId)
    XCTAssertEqual(response.header.shardId, 0)
    
    let sameChunk = try await self.provider.chunk(chunkId: ChunkId.chunkHash(response.header.chunkHash))
    XCTAssertEqual(sameChunk.header.chunkHash, response.header.chunkHash)
    XCTAssertEqual(sameChunk.header.shardId, 0)
  }
  
  func testGasPrice() async throws {
    let status = try await self.provider.status()
    
    let blockHeight = NullableBlockId.blockHeight(status.syncInfo.latestBlockHeight)
    let response1 = try await self.provider.gasPrice(blockId: blockHeight)
    XCTAssertGreaterThan(Int(response1.gasPrice) ?? 0, 0)
    
    let blockHash = NullableBlockId.blockHash(status.syncInfo.latestBlockHash)
    let response2 = try await self.provider.gasPrice(blockId: blockHash)
    XCTAssertGreaterThan(Int(response2.gasPrice) ?? 0, 0)
    
    let response3 = try await self.provider.gasPrice(blockId: NullableBlockId.null)
    XCTAssertGreaterThan(Int(response3.gasPrice) ?? 0, 0)
  }
  
  func testExperimentalGenesisConfig() async throws {
    let response = try await self.provider.experimentalGenesisConfig()
    
    XCTAssertNotNil(response.chainId)
    XCTAssertNotNil(response.genesisHeight)
  }
  
  func testExperimentalProtocolConfig() async throws {
    let status = try await self.provider.status()
    let latestHash = BlockId.blockHash(status.syncInfo.latestBlockHash)
    let blockQuery = BlockReference.blockId(latestHash)
    let response = try await self.provider.experimentalProtocolConfig(blockQuery: blockQuery)
    
    XCTAssertNotNil(response.chainId)
    XCTAssertNotNil(response.genesisHeight)
    XCTAssertNotNil(response.runtimeConfig)
    XCTAssertNotNil(response.runtimeConfig?.storageAmountPerByte)
  }

  func testFetchValidatorInfo() async throws {
    let validators = try await self.provider.validators(blockId: NullableBlockId.null)
    XCTAssertGreaterThanOrEqual(validators.currentValidators.count, 1)
  }
  
  func testAccessKeyChanges() async throws {
    let status = try await self.provider.status()
    let changes = try await provider.accessKeyChanges(accountIdArray: [testAccountName], blockQuery: BlockReference.blockId(BlockId.blockHash(status.syncInfo.latestBlockHash)))
    XCTAssertEqual(status.syncInfo.latestBlockHash, changes.blockHash)
    XCTAssertNotNil(changes.changes)
  }
  
  func testSingleAccessKeyChanges() async throws {
    let status = try await self.provider.status()
    let near = try await TestUtils.setUpTestConnection()
    let testAccount = try await near.account(accountId: testAccountName)
    let keyBox = try await testAccount.getAccessKeys()
    let publicKey = keyBox.keys.first?.publicKey
    let accessKeyWithPublicKey = AccessKeyWithPublicKey(accountId: testAccountName, publicKey: publicKey!)

    let changes = try await self.provider.singleAccessKeyChanges(accessKeyArray: [accessKeyWithPublicKey], blockQuery: BlockReference.blockId(BlockId.blockHash(status.syncInfo.latestBlockHash)))
    XCTAssertEqual(status.syncInfo.latestBlockHash, changes.blockHash)
    XCTAssertNotNil(changes.changes)
  }
  
  func testAccountChanges() async throws {
    let status = try await self.provider.status()
    let changes = try await self.provider.accountChanges(accountIdArray: [testAccountName], blockQuery: BlockReference.blockId(BlockId.blockHash(status.syncInfo.latestBlockHash)))
    XCTAssertEqual(status.syncInfo.latestBlockHash, changes.blockHash)
    XCTAssertNotNil(changes.changes)
  }
  
  func testContractStateChanges() async throws {
    let status = try await self.provider.status()
    let changes = try await self.provider.contractStateChanges(accountIdArray: [testAccountName], blockQuery: BlockReference.blockId(BlockId.blockHash(status.syncInfo.latestBlockHash)), keyPrefix: nil)
    XCTAssertEqual(status.syncInfo.latestBlockHash, changes.blockHash)
    XCTAssertNotNil(changes.changes)
  }
  
  func testContractCodeChanges() async throws {
    let status = try await self.provider.status()
    let changes = try await self.provider.contractCodeChanges(accountIdArray: [testAccountName], blockQuery: BlockReference.blockId(BlockId.blockHash(status.syncInfo.latestBlockHash)))
    XCTAssertEqual(status.syncInfo.latestBlockHash, changes.blockHash)
    XCTAssertNotNil(changes.changes)
  }

  func testTransactionStatus() async throws {
    let near = try await TestUtils.setUpTestConnection()
    let testAccount = try await near.account(accountId: testAccountName)
    let sender = try await TestUtils.createAccount(masterAccount: testAccount)
    let receiver = try await TestUtils.createAccount(masterAccount: testAccount)
    let outcome = try await sender.sendMoney(receiverId: receiver.accountId, amount: UInt128(1))
    let response = try await self.provider.txStatus(txHash: outcome.transactionOutcome.id.baseDecoded, accountId: sender.accountId)
    XCTAssertEqual(response, outcome)
  }
  
  func testTransactionStatusWithReceipts() async throws {
    let near = try await TestUtils.setUpTestConnection()
    let testAccount = try await near.account(accountId: testAccountName)
    let sender = try await TestUtils.createAccount(masterAccount: testAccount)
    let receiver = try await TestUtils.createAccount(masterAccount: testAccount)
    let outcome = try await sender.sendMoney(receiverId: receiver.accountId, amount: UInt128(1))
    let response = try await self.provider.experimentalTxStatusWithReceipts(txHash: outcome.transactionOutcome.id.baseDecoded, accountId: sender.accountId)
    XCTAssertNil(outcome.receipts)
    XCTAssertNotNil(response.receipts)
  }
}
