////
////  ProviderSpec.swift
////  nearclientios_Tests
////
////  Created by Dmytro Kurochka on 27.11.2019.
////  Copyright © 2019 CocoaPods. All rights reserved.
////
//
//import XCTest
//import Quick
//import Nimble
//import AwaitKit
//@testable import nearclientios
//
//class ProviderSpec: QuickSpec {
//  private var provider: Provider!
//
//  override func spec() {
//    describe("ProviderSpec") {
//
//      beforeEach {
//        let url = getConfig(env: .ci).nodeUrl
//        self.provider = JSONRPCProvider(url: url)
//      }
//
////      it("should fetch node status") {
////        let response = try! await(self.provider.status())
////        expect(response.chain_id).to(contain("test-chain"))
////      }
//
////      it("should fetch block info") {
////        let response = try! await(provider.block(blockId: 1))
////        expect(response.header.height).to(equal(1))
////        let sameBlock = try! await(provider.block(response.header.hash))
////        expect(sameBlock.header.height).to(equal(1))
////      }
////
////      it("should fetch chunk info") {
////        let response = try! await(provider.chunk(chunkId: [1, 0]))
////        expect(response.header.shard_id).to(equal(0))
////        let sameChunk = try! await(provider.chunk(response.header.chunk_hash))
////        expect(sameChunk.header.chunk_hash).to(equal(response.header.chunk_hash))
////        expect(sameChunk.header.shard_id).to(equal(0))
////      }
////
////      it("should query account") {
////        let response = try! await(provider.query("account/test.near", ""))
////        expect(response.code_hash).to(equal("11111111111111111111111111111111"))
////      }
//
//      it("should have correct final tx result") {
//        let outcome = ExecutionOutcome(status: .successReceiptId("11112"),
//                                       logs: [],
//                                       receipt_ids: ["11112"],
//                                       gas_burnt: 1)
//        let transaction = ExecutionOutcomeWithId(id: "11111", outcome: outcome)
//        let firstRecipientOutcome = ExecutionOutcome(status: .successValue("e30="),
//                                                     logs: [],
//                                                     receipt_ids: ["11112"],
//                                                     gas_burnt: 9001)
//        let secondRecipientOutcome = ExecutionOutcome(status: .successValue(""),
//                                                      logs: [],
//                                                      receipt_ids: [],
//                                                      gas_burnt: 0)
//        let receipts = [ExecutionOutcomeWithId(id: "11112", outcome: firstRecipientOutcome),
//                        ExecutionOutcomeWithId(id: "11113", outcome: secondRecipientOutcome)]
//        let result = FinalExecutionOutcome(status: .successValue("e30="),
//                                           transaction: transaction,
//                                           receipts: receipts)
//        expect(getTransactionLastResult(txResult: result)).notTo(beNil())
//      }
//
//      it("should have final tx result with nil") {
//        let outcome = ExecutionOutcome(status: .successReceiptId("11112"),
//                                       logs: [],
//                                       receipt_ids: ["11112"],
//                                       gas_burnt: 1)
//        let transaction = ExecutionOutcomeWithId(id: "11111", outcome: outcome)
//        let firstRecipientOutcome = ExecutionOutcome(status: .failure(ExecutionError()),
//                                                     logs: [],
//                                                     receipt_ids: ["11112"],
//                                                     gas_burnt: 9001)
//        let secondRecipientOutcome = ExecutionOutcome(status: .successValue(""),
//                                                      logs: [],
//                                                      receipt_ids: [],
//                                                      gas_burnt: 0)
//        let receipts = [ExecutionOutcomeWithId(id: "11112", outcome: firstRecipientOutcome),
//                        ExecutionOutcomeWithId(id: "11113", outcome: secondRecipientOutcome)]
//        let result = FinalExecutionOutcome(status: .failure(ExecutionError()),
//                                           transaction: transaction,
//                                           receipts: receipts)
//        expect(getTransactionLastResult(txResult: result)).to(beNil())
//      }
//    }
//  }
//}
//
