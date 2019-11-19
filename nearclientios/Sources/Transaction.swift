//
//  Transaction.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit
import AwaitKit

internal struct FunctionCallPermission {
  let allowance: BigInt?
  let receiverId: String
  let methodNames: [String]
}

internal struct FullAccessPermission {}

internal enum AccessKeyPermission {
  case functionCall(FunctionCallPermission)
  case fullAccess(FullAccessPermission)
}

extension AccessKeyPermission: Codable {
  //TODO: implement
  func encode(to encoder: Encoder) throws {

  }

  init(from decoder: Decoder) throws {

  }
}

internal struct AccessKey: Codable {
  let nonce: Number
  let permission: AccessKeyPermission
}

internal func fullAccessKey() -> AccessKey {
  let fullAccess = FullAccessPermission()
  let permission = AccessKeyPermission.fullAccess(fullAccess)
  return AccessKey(nonce: 0, permission: permission)
}

internal func functionCallAccessKey(receiverId: String, methodNames: [String], allowance: BigInt?) -> AccessKey {
  let callPermission = FunctionCallPermission(allowance: allowance, receiverId: receiverId, methodNames: methodNames)
  let permission = AccessKeyPermission.functionCall(callPermission)
  return AccessKey( nonce: 0, permission: permission)
}

internal protocol IAction {}

internal struct CreateAccount: IAction {}

internal struct DeployContract: IAction {
  let code: [UInt8]
}

internal struct FunctionCall: IAction {
  let methodName: String
  let args: [UInt8]
  let gas: Number
  let deposit: BigInt
}

internal struct Transfer: IAction {
  let deposit: BigInt
}

internal struct Stake: IAction {
  let stake: BigInt
  let publicKey: PublicKey
}

internal struct AddKey: IAction {
  let publicKey: PublicKey
  let accessKey: AccessKey
}

internal struct DeleteKey: IAction {
  let publicKey: PublicKey
}

internal struct DeleteAccount: IAction {
  let beneficiaryId: String
}

func createAccount() -> Action {
  return .createAccount(CreateAccount())
}

func deployContract(code: [UInt8]) -> Action {
  return .deployContract(DeployContract(code: code))
}

func functionCall(methodName: String, args: [UInt8], gas: Number, deposit: BigInt) -> Action {
  return .functionCall(FunctionCall(methodName: methodName, args: args, gas: gas, deposit: deposit))
}

func transfer(deposit: BigInt) -> Action {
  return .transfer(Transfer(deposit: deposit))
}

func stake(stake: BigInt, publicKey: PublicKey) -> Action {
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

internal struct SignedTransaction {

  struct Signature {
    let keyType: KeyType
    let data: [UInt8]

    init(signature: [UInt8]) {
      self.keyType = KeyType.ED25519
      self.data = signature
    }
  }

  struct Transaction {
    let signerId: String
    let publicKey: PublicKey
    let nonce: Number
    let receiverId: String
    let actions: [Action]
    let blockHash: [UInt8]
  }

  let transaction: Transaction
  let signature: Signature

  func encode() -> [UInt8] {
    return []
    //TODO
    //      return serialize(SCHEMA, this)
  }
}

internal enum Action {
  case createAccount(CreateAccount)
  case deployContract(DeployContract)
  case functionCall(FunctionCall)
  case transfer(Transfer)
  case stake(Stake)
  case addKey(AddKey)
  case deleteKey(DeleteKey)
  case deleteAccount(DeleteAccount)
}

//let SCHEMA = Map<Function, Any>([
//    [Signature, {kind: "struct", fields: [
//        ["keyType", "u8"],
//        ["data", [32]]
//    ]}],
//    [SignedTransaction, {kind: "struct", fields: [
//        ["transaction", Transaction],
//        ["signature", Signature]
//    ]}],
//    [Transaction, { kind: "struct", fields: [
//        ["signerId", "string"],
//        ["publicKey", PublicKey],
//        ["nonce", "u64"],
//        ["receiverId", "string"],
//        ["blockHash", [32]],
//        ["actions", [Action]]
//    ]}],
//    [PublicKey, { kind: "struct", fields: [
//        ["keyType", "u8"],
//        ["data", [32]]
//    ]}],
//    [AccessKey, { kind: "struct", fields: [
//        ["nonce", "u64"],
//        ["permission", AccessKeyPermission],
//    ]}],
//    [AccessKeyPermission, {kind: "enum", field: "enum", values: [
//        ["functionCall", FunctionCallPermission],
//        ["fullAccess", FullAccessPermission],
//    ]}],
//    [FunctionCallPermission, {kind: "struct", fields: [
//        ["allowance", {kind: "option", type: "u128"}],
//        ["receiverId", "string"],
//        ["methodNames", ["string"]],
//    ]}],
//    [FullAccessPermission, {kind: "struct", fields: []}],
//    [Action, {kind: "enum", field: "enum", values: [
//        ["createAccount", CreateAccount],
//        ["deployContract", DeployContract],
//        ["functionCall", functionCall],
//        ["transfer", transfer],
//        ["stake", stake],
//        ["addKey", addKey],
//        ["deleteKey", deleteKey],
//        ["deleteAccount", deleteAccount],
//    ]}],
//    [CreateAccount, { kind: "struct", fields: [] }],
//    [DeployContract, { kind: "struct", fields: [
//        ["code", ["u8"]]
//    ]}],
//    [FunctionCall, { kind: "struct", fields: [
//        ["methodName", "string"],
//        ["args", ["u8"]],
//        ["gas", "u64"],
//        ["deposit", "u128"]
//    ]}],
//    [Transfer, { kind: "struct", fields: [
//        ["deposit", "u128"]
//    ]}],
//    [Stake, { kind: "struct", fields: [
//        ["stake", "u128"],
//        ["publicKey", PublicKey]
//    ]}],
//    [AddKey, { kind: "struct", fields: [
//        ["publicKey", PublicKey],
//        ["accessKey", AccessKey]
//    ]}],
//    [DeleteKey, { kind: "struct", fields: [
//        ["publicKey", PublicKey]
//    ]}],
//    [DeleteAccount, { kind: "struct", fields: [
//        ["beneficiaryId", "string"]
//    ]}],
//])

enum SignError: Error {
  case noPublicKey
}

func signTransaction(receiverId: String, nonce: Number, actions: [Action], blockHash: [UInt8],
                     signer: Signer, accountId: String, networkId: String) throws -> Promise<([UInt8], SignedTransaction)> {
  guard let publicKey = try await(signer.getPublicKey(accountId: accountId, networkId: networkId)) else {
    throw SignError.noPublicKey
  }
  let transaction = SignedTransaction.Transaction(signerId: accountId, publicKey: publicKey, nonce: nonce,
                                receiverId: receiverId, actions: actions, blockHash: blockHash)
  //TODO
  //let message = serialize(SCHEMA, transaction)
  let message = [UInt8]()
  let hash = message.digest
  let signature = try await(signer.signMessage(message: message, accountId: accountId, networkId: networkId))
  let signedTx = SignedTransaction(transaction: transaction, signature: Signature(signature: signature.signature)
  return .value((hash, signedTx))
}
