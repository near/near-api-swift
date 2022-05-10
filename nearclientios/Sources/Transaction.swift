//
//  Transaction.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

public struct FunctionCallPermission {
  public let allowance: UInt128?
  public let receiverId: String
  public let methodNames: [String]
}

extension FunctionCallPermission: Decodable {
  private enum CodingKeys: String, CodingKey {
    case allowance, receiverId, methodNames
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let allowanceLiteral = try container.decode(String?.self, forKey: .allowance)
    allowance = allowanceLiteral != nil ? UInt128(stringLiteral: allowanceLiteral!) : nil
    receiverId = try container.decode(String.self, forKey: .receiverId)
    methodNames = try container.decode([String].self, forKey: .methodNames)
  }
}

extension FunctionCallPermission: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try allowance.serialize(to: &writer)
    try receiverId.serialize(to: &writer)
    try methodNames.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.allowance = try .init(from: &reader)
    self.receiverId = try .init(from: &reader)
    self.methodNames = try .init(from: &reader)
  }
}

public struct FullAccessPermission: Equatable {}

extension FullAccessPermission: BorshCodable {
  public func serialize(to writer: inout Data) throws {}

  public init(from reader: inout BinaryReader) throws {
    self.init()
  }
}

public enum AccessKeyPermission {
  case functionCall(FunctionCallPermission)
  case fullAccess(FullAccessPermission)

  var rawValue: UInt8 {
    switch self {
    case .functionCall: return 0
    case .fullAccess: return 1
    }
  }
}

public enum NEARDecodingError: Error {
  case notExpected
}

extension AccessKeyPermission: Decodable {
  private enum CodingKeys: String, CodingKey {
    case functionCall = "FunctionCall"
  }

  public init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer() {
      let value = try? container.decode(String.self)
      if value == "FullAccess" {
        self = .fullAccess(FullAccessPermission())
        return
      }
    }
    if let container = try? decoder.container(keyedBy: CodingKeys.self) {
      let permission = try container.decode(FunctionCallPermission.self, forKey: .functionCall)
      self = .functionCall(permission)
    } else {
      throw NEARDecodingError.notExpected
    }
  }
}

extension AccessKeyPermission: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try rawValue.serialize(to: &writer)
    switch self {
    case .functionCall(let permission): try permission.serialize(to: &writer)
    case .fullAccess(let permission): try permission.serialize(to: &writer)
    }
  }

  public init(from reader: inout BinaryReader) throws {
    let rawValue = try UInt8(from: &reader)
    switch rawValue {
    case 0: self = .functionCall(try FunctionCallPermission(from: &reader))
    case 1: self = .fullAccess(try FullAccessPermission(from: &reader))
    default: fatalError()
    }
  }
}

public struct AccessKey: Decodable {
  public var nonce: UInt64
  public let permission: AccessKeyPermission
}

extension AccessKey: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try nonce.serialize(to: &writer)
    try permission.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.nonce = try .init(from: &reader)
    self.permission = try .init(from: &reader)
  }
}

public func fullAccessKey() -> AccessKey {
  let fullAccess = FullAccessPermission()
  let permission = AccessKeyPermission.fullAccess(fullAccess)
  return AccessKey(nonce: 0, permission: permission)
}

public func functionCallAccessKey(receiverId: String, methodNames: [String], allowance: UInt128?) -> AccessKey {
  let callPermission = FunctionCallPermission(allowance: allowance, receiverId: receiverId, methodNames: methodNames)
  let permission = AccessKeyPermission.functionCall(callPermission)
  return AccessKey(nonce: 0, permission: permission)
}

public protocol IAction {}

public struct CreateAccount: IAction {}

extension CreateAccount: BorshCodable {
  public func serialize(to writer: inout Data) throws {}

  public init(from reader: inout BinaryReader) throws {
    self.init()
  }
}

public struct DeployContract: IAction {
  public let code: [UInt8]
}

extension DeployContract: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try code.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    let code: [UInt8] = try .init(from: &reader)
    self.init(code: code)
  }
}

public struct FunctionCall: IAction {
  public let methodName: String
  public let args: [UInt8]
  public let gas: UInt64
  public let deposit: UInt128
}

extension FunctionCall: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try methodName.serialize(to: &writer)
    try args.serialize(to: &writer)
    try gas.serialize(to: &writer)
    try deposit.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.methodName = try .init(from: &reader)
    self.args = try .init(from: &reader)
    self.gas = try .init(from: &reader)
    self.deposit = try .init(from: &reader)
  }
}

public struct Transfer: IAction {
  public let deposit: UInt128
}

extension Transfer: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try deposit.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.deposit = try .init(from: &reader)
  }
}

public struct Stake: IAction {
  public let stake: UInt128
  public let publicKey: PublicKey
}

extension Stake: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try stake.serialize(to: &writer)
    try publicKey.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.stake = try .init(from: &reader)
    self.publicKey = try .init(from: &reader)
  }
}

public struct AddKey: IAction {
  public let publicKey: PublicKey
  public let accessKey: AccessKey
}

extension AddKey: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try publicKey.serialize(to: &writer)
    try accessKey.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.publicKey = try .init(from: &reader)
    self.accessKey = try .init(from: &reader)
  }
}

public struct DeleteKey: IAction {
  public let publicKey: PublicKey
}

extension DeleteKey: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try publicKey.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.publicKey = try .init(from: &reader)
  }
}

public struct DeleteAccount: IAction {
  public let beneficiaryId: String
}

extension DeleteAccount: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try beneficiaryId.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.beneficiaryId = try .init(from: &reader)
  }
}

func createAccount() -> Action {
  return .createAccount(CreateAccount())
}

func deployContract(code: [UInt8]) -> Action {
  return .deployContract(DeployContract(code: code))
}

func functionCall(methodName: String, args: [UInt8], gas: UInt64, deposit: UInt128) -> Action {
  return .functionCall(FunctionCall(methodName: methodName, args: args, gas: gas, deposit: deposit))
}

func transfer(deposit: UInt128) -> Action {
  return .transfer(Transfer(deposit: deposit))
}

func stake(stake: UInt128, publicKey: PublicKey) -> Action {
  return .stake(Stake(stake: stake, publicKey: publicKey))
}

func addKey(publicKey: PublicKey, accessKey: AccessKey) -> Action {
  return .addKey(AddKey(publicKey: publicKey, accessKey: accessKey))
}

func deleteKey(publicKey: PublicKey) -> Action {
  return .deleteKey(DeleteKey(publicKey: publicKey))
}

func deleteAccount(beneficiaryId: String) -> Action {
  return .deleteAccount(DeleteAccount(beneficiaryId: beneficiaryId))
}

//public struct SignaturePayload: FixedLengthByteArray, BorshCodable {
//  public static let fixedLength: UInt32 = 64
//  public let bytes: [UInt8]
//  public init(bytes: [UInt8]) {
//    self.bytes = bytes
//  }
//}

public struct CodableSignature {
  let keyType: KeyType
  let bytes: [UInt8]

  init(signature: [UInt8], curve: KeyType) {
    self.keyType = curve
    self.bytes = signature
  }
}

extension CodableSignature: BorshCodable {

  public func serialize(to writer: inout Data) throws {

    try keyType.serialize(to: &writer)
    writer.append(bytes, count: Int(keyType == .ED25519 ? 64 : 65))
  }

  public init(from reader: inout BinaryReader) throws {
    self.keyType = try .init(from: &reader)
    self.bytes = reader.read(count: keyType == .ED25519 ? 64 : 65)
  }
}

public struct BlockHashPayload: FixedLengthByteArray, BorshCodable {
  public static let fixedLength: UInt32 = 32
  public let bytes: [UInt8]
  public init(bytes: [UInt8]) {
    self.bytes = bytes
  }
}

public struct CodableTransaction {
  public let signerId: String
  public let publicKey: PublicKey
  public let nonce: UInt64
  public let receiverId: String
  public let blockHash: BlockHashPayload
  public let actions: [Action]
}

extension CodableTransaction: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try signerId.serialize(to: &writer)
    try publicKey.serialize(to: &writer)
    try nonce.serialize(to: &writer)
    try receiverId.serialize(to: &writer)
    try blockHash.serialize(to: &writer)
    try actions.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.signerId = try .init(from: &reader)
    self.publicKey = try .init(from: &reader)
    self.nonce = try .init(from: &reader)
    self.receiverId = try .init(from: &reader)
    self.blockHash = try .init(from: &reader)
    self.actions = try .init(from: &reader)
  }
}

public struct SignedTransaction {
  let transaction: CodableTransaction
  let signature: CodableSignature
}

extension SignedTransaction: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try transaction.serialize(to: &writer)
    try signature.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.transaction = try .init(from: &reader)
    self.signature = try .init(from: &reader)
  }
}

public enum Action {
  case createAccount(CreateAccount)
  case deployContract(DeployContract)
  case functionCall(FunctionCall)
  case transfer(Transfer)
  case stake(Stake)
  case addKey(AddKey)
  case deleteKey(DeleteKey)
  case deleteAccount(DeleteAccount)

  var rawValue: UInt8 {
    switch self {
    case .createAccount: return 0
    case .deployContract: return 1
    case .functionCall: return 2
    case .transfer: return 3
    case .stake: return 4
    case .addKey: return 5
    case .deleteKey: return 6
    case .deleteAccount: return 7
    }
  }
}

extension Action: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try rawValue.serialize(to: &writer)
    switch self {
    case .createAccount(let payload): try payload.serialize(to: &writer)
    case .deployContract(let payload): try payload.serialize(to: &writer)
    case .functionCall(let payload): try payload.serialize(to: &writer)
    case .transfer(let payload): try payload.serialize(to: &writer)
    case .stake(let payload): try payload.serialize(to: &writer)
    case .addKey(let payload): try payload.serialize(to: &writer)
    case .deleteKey(let payload): try payload.serialize(to: &writer)
    case .deleteAccount(let payload): try payload.serialize(to: &writer)
    }
  }

  public init(from reader: inout BinaryReader) throws {
    let rawValue = try UInt8.init(from: &reader)
    switch rawValue {
    case 0: self = .createAccount(try CreateAccount(from: &reader))
    case 1: self = .deployContract(try DeployContract(from: &reader))
    case 2: self = .functionCall(try FunctionCall(from: &reader))
    case 3: self = .transfer(try Transfer(from: &reader))
    case 4: self = .stake(try Stake(from: &reader))
    case 5: self = .addKey(try AddKey(from: &reader))
    case 6: self = .deleteKey(try DeleteKey(from: &reader))
    case 7: self = .deleteAccount(try DeleteAccount(from: &reader))
    default: fatalError()
    }
  }
}

enum SignError: Error {
  case noPublicKey
}

func signTransaction(receiverId: String, nonce: UInt64, actions: [Action], blockHash: [UInt8],
                     signer: Signer, accountId: String, networkId: String) async throws -> ([UInt8], SignedTransaction) {
  guard let publicKey = try await signer.getPublicKey(accountId: accountId, networkId: networkId) else {
    throw SignError.noPublicKey
  }
  let transaction = CodableTransaction(signerId: accountId,
                                       publicKey: publicKey,
                                       nonce: nonce,
                                       receiverId: receiverId,
                                       blockHash: BlockHashPayload(bytes: blockHash),
                                       actions: actions)
  let message = try BorshEncoder().encode(transaction)
  let hash = message.digest
  let signature = try await signer.signMessage(message: message.bytes, accountId: accountId, networkId: networkId)
  
  let signedTx = SignedTransaction(transaction: transaction, signature: CodableSignature(signature: signature.signature, curve: publicKey.keyType))
  return (hash, signedTx)
}
