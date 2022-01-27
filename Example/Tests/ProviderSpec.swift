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
    XCTAssertTrue(response.chain_id.contains("ci-testnet"))
  }
  
  func testCorrectFinalTransactionResult() {
    let outcome = ExecutionOutcome(status: .successReceiptId("11112"),
                                   logs: [],
                                   receipt_ids: ["11112"],
                                   gas_burnt: 1)
    let transaction = ExecutionOutcomeWithId(id: "11111", outcome: outcome)
    let firstRecipientOutcome = ExecutionOutcome(status: .successValue("e30="),
                                                 logs: [],
                                                 receipt_ids: ["11112"],
                                                 gas_burnt: 9001)
    let secondRecipientOutcome = ExecutionOutcome(status: .successValue(""),
                                                  logs: [],
                                                  receipt_ids: [],
                                                  gas_burnt: 0)
    let receipts = [ExecutionOutcomeWithId(id: "11112", outcome: firstRecipientOutcome),
                    ExecutionOutcomeWithId(id: "11113", outcome: secondRecipientOutcome)]
    let result = FinalExecutionOutcome(status: .successValue("e30="),
                                       transaction: transaction,
                                       receipts: receipts)
    XCTAssertNotNil(getTransactionLastResult(txResult: result))
  }
  
  func testFinalTransactionResultWithNil() {
    let outcome = ExecutionOutcome(status: .successReceiptId("11112"),
                                   logs: [],
                                   receipt_ids: ["11112"],
                                   gas_burnt: 1)
    let transaction = ExecutionOutcomeWithId(id: "11111", outcome: outcome)
    let firstRecipientOutcome = ExecutionOutcome(status: .failure(ExecutionError()),
                                                 logs: [],
                                                 receipt_ids: ["11112"],
                                                 gas_burnt: 9001)
    let secondRecipientOutcome = ExecutionOutcome(status: .successValue(""),
                                                  logs: [],
                                                  receipt_ids: [],
                                                  gas_burnt: 0)
    let receipts = [ExecutionOutcomeWithId(id: "11112", outcome: firstRecipientOutcome),
                    ExecutionOutcomeWithId(id: "11113", outcome: secondRecipientOutcome)]
    let result = FinalExecutionOutcome(status: .failure(ExecutionError()),
                                       transaction: transaction,
                                       receipts: receipts)
    XCTAssertNil(getTransactionLastResult(txResult: result))
  }
  
//  func testFetchBlockInfo() async {
//    let response = try! await provider.block(blockId: "1")
//    XCTAssertEqual(response.header.height, 1)
//    let sameBlock = try! await provider.block(blockId: response.header.hash)
//    XCTAssertEqual(sameBlock.header.height, 1)
//  }
  
//  func testFetchChunkInfo() async{
//    let response = try! await provider.chunk(chunkId: "[1, 0]")
//    XCTAssertEqual(response.header.shard_id, 0)
//    let sameChunk = try! await provider.chunk(chunkId: response.header.chunk_hash)
//    XCTAssertEqual(sameChunk.header.chunk_hash, response.header.chunk_hash)
//    XCTAssertEqual(sameChunk.header.shard_id, 0)
//  }
  
//  func testQueryAccount() async{
//    let response = try! await provider.query(path: "account/test.near", data: "")
//    XCTAssertEqual(response.code_hash, "11111111111111111111111111111111")
//  }

}
