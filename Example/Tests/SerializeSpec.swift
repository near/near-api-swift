//
//  SerializeSpec.swift
//  nearclientios_Example
//
//  Created by Dmytro Kurochka on 27.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.

import XCTest
@testable import nearclientios

internal struct Test {
  let x: UInt32
  let y: UInt32
  let z: String
  let q: [UInt128]
}

extension Test: BorshCodable {
  func serialize(to writer: inout Data) throws {
    try x.serialize(to: &writer)
    try y.serialize(to: &writer)
    try z.serialize(to: &writer)
    try q.serialize(to: &writer)
  }

  init(from reader: inout BinaryReader) throws {
    self.x = try .init(from: &reader)
    self.y = try .init(from: &reader)
    self.z = try .init(from: &reader)
    self.q = try .init(from: &reader)
  }
}

class SerializeSpec: XCTestCase {
  func testSerializeObject() {
    let value = Test(x: 255,
                     y: 20,
                     z: "123",
                     q: [1, 2, 3])
    let buf = try! BorshEncoder().encode(value)
    let new_value = try! BorshDecoder().decode(Test.self, from: buf)
    XCTAssertEqual(new_value.x, 255)
    XCTAssertEqual(new_value.y, 20)
    XCTAssertEqual(new_value.z, "123")
    XCTAssertEqual(new_value.q, [1, 2, 3])
  }
  func testSerializeAndSignMultiActionTransaction() async {
    let keyStore = InMemoryKeyStore()
    let keyPair = try! keyPairFromString(encodedKey: "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw") as! KeyPairEd25519
    try! await keyStore.setKey(networkId: "test", accountId: "test.near", keyPair: keyPair)
    let publicKey = keyPair.getPublicKey()
    let actions = [createAccount(),
                   deployContract(code: [1, 2, 3]),
                   functionCall(methodName: "qqq", args: [1, 2, 3], gas: 1000, deposit: 1000000),
                   transfer(deposit: 123),
                   stake(stake: 1000000, publicKey: publicKey),
                   addKey(publicKey: publicKey,
                          accessKey: functionCallAccessKey(receiverId: "zzz",
                                                           methodNames: ["www"],
                                                           allowance: nil)),
                   deleteKey(publicKey: publicKey),
                   deleteAccount(beneficiaryId: "123")]
    let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
    let (hash, _) = try! await signTransaction(receiverId: "123",
                                               nonce: 1,
                                               actions: actions,
                                               blockHash: blockHash,
                                               signer: InMemorySigner(keyStore: keyStore),
                                               accountId: "test.near",
                                               networkId: "test")
    XCTAssertEqual(hash.baseEncoded, "Fo3MJ9XzKjnKuDuQKhDAC6fra5H2UWawRejFSEpPNk3Y")
  }
  
  func testSerializeTransferTransaction() {
    let actions = [transfer(deposit: 1)]
    let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
    let transaction = CodableTransaction(signerId: "test.near",
                                         publicKey: try! PublicKey.fromString(encodedKey: "Anu7LYDfpLtkP7E16LT9imXF694BdQaa9ufVkQiwTQxC"),
                                         nonce: 1,
                                         receiverId: "whatever.near",
                                         blockHash: BlockHashPayload(bytes: blockHash),
                                         actions: actions)
    let serialized = try! BorshEncoder().encode(transaction)
    XCTAssertEqual(serialized.hexString, "09000000746573742e6e65617200917b3d268d4b58f7fec1b150bd68d69be3ee5d4cc39855e341538465bb77860d01000000000000000d00000077686174657665722e6e6561720fa473fd26901df296be6adc4cc4df34d040efa2435224b6986910e630c2fef6010000000301000000000000000000000000000000")

    let deserialized = try! BorshDecoder().decode(CodableTransaction.self, from: serialized)
    let roundTripped = try! BorshEncoder().encode(deserialized)
    XCTAssertEqual(roundTripped, serialized)
  }
  func testSerializeAndSignTransferTransaction() async {
    let keyStore = InMemoryKeyStore()
    let keyPair = try! keyPairFromString(encodedKey: "ed25519:3hoMW1HvnRLSFCLZnvPzWeoGwtdHzke34B2cTHM8rhcbG3TbuLKtShTv3DvyejnXKXKBiV7YPkLeqUHN1ghnqpFv") as! KeyPairEd25519
    try! await keyStore.setKey(networkId: "test", accountId: "test.near", keyPair: keyPair)
    let actions = [transfer(deposit: 1)]
    let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
    let (_, signedTx) = try! await signTransaction(receiverId: "whatever.near",
                                                   nonce: 1,
                                                   actions: actions,
                                                   blockHash: blockHash,
                                                   signer: InMemorySigner(keyStore: keyStore),
                                                   accountId: "test.near",
                                                   networkId: "test")
    let base64 = signedTx.signature.bytes.data.base64EncodedString()
    XCTAssertEqual(base64, "lpqDMyGG7pdV5IOTJVJYBuGJo9LSu0tHYOlEQ+l+HE8i3u7wBZqOlxMQDtpuGRRNp+ig735TmyBwi6HY0CG9AQ==")
    let serialized = try! BorshEncoder().encode(signedTx)
    XCTAssertEqual(serialized.hexString, "09000000746573742e6e65617200917b3d268d4b58f7fec1b150bd68d69be3ee5d4cc39855e341538465bb77860d01000000000000000d00000077686174657665722e6e6561720fa473fd26901df296be6adc4cc4df34d040efa2435224b6986910e630c2fef601000000030100000000000000000000000000000000969a83332186ee9755e4839325525806e189a3d2d2bb4b4760e94443e97e1c4f22deeef0059a8e9713100eda6e19144da7e8a0ef7e539b20708ba1d8d021bd01")
  }
  
  func testSerializeAndSignSecp256k1TransferTransaction() async {
    let keyStore = InMemoryKeyStore()
    //    let keyPair = try! KeyPairSecp256k1(secretKey: "Cqmi5vHc59U1MHhq7JCxTSJentvVBYMcKGUA7s7kwnKn")
    //XCTAssertEqual(keyPair.getPublicKey().toString(), "secp256k1:QYkvGGNVpePURHmKh4GtTMNSHSFmkAUowm1wrciqLrLGnKNWZgouUxHJUuKiaTwRJxUQ4ghnZ9uLXDFau6UDjQDn")

    let keyPair = try! keyPairFromString(encodedKey: "secp256k1:Cqmi5vHc59U1MHhq7JCxTSJentvVBYMcKGUA7s7kwnKn") as! KeyPairSecp256k1
    try! await keyStore.setKey(networkId: "test", accountId: "test.near", keyPair: keyPair)
    let actions = [transfer(deposit: 1)]
    let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
    let (_, signedTx) = try! await signTransaction(receiverId: "whatever.near",
                                                   nonce: 1,
                                                   actions: actions,
                                                   blockHash: blockHash,
                                                   signer: InMemorySigner(keyStore: keyStore),
                                                   accountId: "test.near",
                                                   networkId: "test")
    let base64 = signedTx.signature.bytes.data.base64EncodedString()
    XCTAssertEqual(base64, "lpqDMyGG7pdV5IOTJVJYBuGJo9LSu0tHYOlEQ+l+HE8i3u7wBZqOlxMQDtpuGRRNp+ig735TmyBwi6HY0CG9AQ==")
    let serialized = try! BorshEncoder().encode(signedTx)
    XCTAssertEqual(serialized.hexString, "09000000746573742e6e65617200917b3d268d4b58f7fec1b150bd68d69be3ee5d4cc39855e341538465bb77860d01000000000000000d00000077686174657665722e6e6561720fa473fd26901df296be6adc4cc4df34d040efa2435224b6986910e630c2fef601000000030100000000000000000000000000000000969a83332186ee9755e4839325525806e189a3d2d2bb4b4760e94443e97e1c4f22deeef0059a8e9713100eda6e19144da7e8a0ef7e539b20708ba1d8d021bd01")
  }

  func testSerializePassRoundtrip() {
    let json: [String: String] = loadJSON(name: "Transaction")!
    let data = json["data"].flatMap {Data(fromHexEncodedString: $0)}
    let deserialized = try! BorshDecoder().decode(CodableTransaction.self, from: data!)
    let serialized = try! BorshEncoder().encode(deserialized)
    XCTAssertEqual(serialized, data)

  }
}
  
  private class BundleTargetingClass {}
  func loadJSON<T>(name: String) -> T? {
    guard let filePath = Bundle(for: BundleTargetingClass.self).url(forResource: name, withExtension: "json") else {
      return nil
    }
    guard let jsonData = try? Data(contentsOf: filePath, options: []) else {
      return nil
    }
    guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
      return nil
    }
    return json as? T
  }
  
  extension Data {
  
      // Convert 0 ... 9, a ... f, A ...F to their decimal value,
      // return nil for all other input characters
      fileprivate func decodeNibble(_ u: UInt16) -> UInt8? {
          switch(u) {
          case 0x30 ... 0x39:
              return UInt8(u - 0x30)
          case 0x41 ... 0x46:
              return UInt8(u - 0x41 + 10)
          case 0x61 ... 0x66:
              return UInt8(u - 0x61 + 10)
          default:
              return nil
          }
      }
  
      init?(fromHexEncodedString string: String) {
          var str = string
          if str.count%2 != 0 {
              // insert 0 to get even number of chars
              str.insert("0", at: str.startIndex)
          }
  
          let utf16 = str.utf16
          self.init(capacity: utf16.count/2)
  
          var i = utf16.startIndex
          while i != str.utf16.endIndex {
              guard let hi = decodeNibble(utf16[i]),
                  let lo = decodeNibble(utf16[utf16.index(i, offsetBy: 1, limitedBy: utf16.endIndex)!]) else {
                      return nil
              }
              var value = hi << 4 + lo
              self.append(&value, count: 1)
              i = utf16.index(i, offsetBy: 2, limitedBy: utf16.endIndex)!
          }
      }

}
//class SerializeSpec: QuickSpec {
//  private var provider: Provider!
//
//  override func spec() {
//    describe("SerializeSpec") {
//      it("should serialize object") {
//        let value = Test(x: 255,
//                         y: 20,
//                         z: "123",
//                         q: [1, 2, 3])
//        let buf = try! BorshEncoder().encode(value)
//        let new_value = try! BorshDecoder().decode(Test.self, from: buf)
//        expect(new_value.x).to(equal(255))
//        expect(new_value.y).to(equal(20))
//        expect(new_value.z).to(equal("123"))
//        expect(new_value.q).to(equal([1, 2, 3]))
//      }
//
//      it("should serialize and sign multi-action tx") {
//        let keyStore = InMemoryKeyStore()
//        let keyPair = try! keyPairFromString(encodedKey: "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw") as! KeyPairEd25519
//        try! await(keyStore.setKey(networkId: "test", accountId: "test.near", keyPair: keyPair))
//        let publicKey = keyPair.getPublicKey()
//        let actions = [createAccount(),
//                       deployContract(code: [1, 2, 3]),
//                       functionCall(methodName: "qqq", args: [1, 2, 3], gas: 1000, deposit: 1000000),
//                       transfer(deposit: 123),
//                       stake(stake: 1000000, publicKey: publicKey),
//                       addKey(publicKey: publicKey,
//                              accessKey: functionCallAccessKey(receiverId: "zzz",
//                                                               methodNames: ["www"],
//                                                               allowance: nil)),
//                       deleteKey(publicKey: publicKey),
//                       deleteAccount(beneficiaryId: "123")]
//        let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
//        let (hash, _) = try! await(signTransaction(receiverId: "123",
//                                                   nonce: 1,
//                                                   actions: actions,
//                                                   blockHash: blockHash,
//                                                   signer: InMemorySigner(keyStore: keyStore),
//                                                   accountId: "test.near",
//                                                   networkId: "test"))
//        expect(hash.baseEncoded).to(equal("Fo3MJ9XzKjnKuDuQKhDAC6fra5H2UWawRejFSEpPNk3Y"))
//      }
//
//      it("should serialize transfer tx") {
//        let actions = [transfer(deposit: 1)]
//        let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
//        let transaction = CodableTransaction(signerId: "test.near",
//                                             publicKey: try! PublicKey.fromString(encodedKey: "Anu7LYDfpLtkP7E16LT9imXF694BdQaa9ufVkQiwTQxC"),
//                                             nonce: 1,
//                                             receiverId: "whatever.near",
//                                             blockHash: BlockHashPayload(bytes: blockHash),
//                                             actions: actions)
//        let serialized = try! BorshEncoder().encode(transaction)
//        expect(serialized.hexString)
//          .to(equal("09000000746573742e6e65617200917b3d268d4b58f7fec1b150bd68d69be3ee5d4cc39855e341538465bb77860d01000000000000000d00000077686174657665722e6e6561720fa473fd26901df296be6adc4cc4df34d040efa2435224b6986910e630c2fef6010000000301000000000000000000000000000000"))
//
//        let deserialized = try! BorshDecoder().decode(CodableTransaction.self, from: serialized)
//        let roundTripped = try! BorshEncoder().encode(deserialized)
//        expect(roundTripped).to(equal(serialized))
//      }
//
//      it("serialize and sign transfer tx") {
//        let keyStore = InMemoryKeyStore()
//        let keyPair = try! keyPairFromString(encodedKey: "ed25519:3hoMW1HvnRLSFCLZnvPzWeoGwtdHzke34B2cTHM8rhcbG3TbuLKtShTv3DvyejnXKXKBiV7YPkLeqUHN1ghnqpFv") as! KeyPairEd25519
//        try! await(keyStore.setKey(networkId: "test", accountId: "test.near", keyPair: keyPair))
//        let actions = [transfer(deposit: 1)]
//        let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".baseDecoded
//        let (_, signedTx) = try! await(signTransaction(receiverId: "whatever.near",
//                                                       nonce: 1,
//                                                       actions: actions,
//                                                       blockHash: blockHash,
//                                                       signer: InMemorySigner(keyStore: keyStore),
//                                                       accountId: "test.near",
//                                                       networkId: "test"))
//        let base64 = signedTx.signature.data.bytes.data.base64EncodedString()
//        expect(base64).to(
//          equal("lpqDMyGG7pdV5IOTJVJYBuGJo9LSu0tHYOlEQ+l+HE8i3u7wBZqOlxMQDtpuGRRNp+ig735TmyBwi6HY0CG9AQ=="))
//        let serialized = try! BorshEncoder().encode(signedTx)
//        expect(serialized.hexString).to(equal( "09000000746573742e6e65617200917b3d268d4b58f7fec1b150bd68d69be3ee5d4cc39855e341538465bb77860d01000000000000000d00000077686174657665722e6e6561720fa473fd26901df296be6adc4cc4df34d040efa2435224b6986910e630c2fef601000000030100000000000000000000000000000000969a83332186ee9755e4839325525806e189a3d2d2bb4b4760e94443e97e1c4f22deeef0059a8e9713100eda6e19144da7e8a0ef7e539b20708ba1d8d021bd01"))
//      }
//
//      it("serialize pass roundtrip test") {
//        let json: [String: String] = loadJSON(name: "Transaction")!
//        let data = json["data"].flatMap {Data(fromHexEncodedString: $0)}
//        let deserialized = try! BorshDecoder().decode(CodableTransaction.self, from: data!)
//        let serialized = try! BorshEncoder().encode(deserialized)
//        expect(serialized).to(equal(data))
//      }
//    }
//  }
//}
