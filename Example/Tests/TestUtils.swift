//
//  UtilsSpec.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 28.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

@testable import nearclientios

let networkId = "unittest"
let testAccountName = "test.near"

let INITIAL_BALANCE = UInt128(stringLiteral: "500000000000000000000000000")
// Length of a random account. Set to 40 because in the protocol minimal allowed top-level account length should be at
// least 32.
let RANDOM_ACCOUNT_LENGTH = 40;

enum TestUtils {}

extension TestUtils {

  static func setUpTestConnection() async throws -> Near {
    let keyStore = InMemoryKeyStore()
    let keyPair = try keyPairFromString(encodedKey: "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw")
    try! await(keyStore.setKey(networkId: networkId, accountId: testAccountName, keyPair: keyPair))
    let environment = getConfig(env: .ci)
    let config = NearConfig(networkId: networkId,
                            nodeUrl: environment.nodeUrl,
                            masterAccount: nil,
                            keyPath: nil,
                            helperUrl: nil,
                            initialBalance: nil,
                            providerType: .jsonRPC(environment.nodeUrl),
                            signerType: .inMemory(keyStore),
                            keyStore: keyStore,
                            contractName: "contractId",
                            walletUrl: environment.nodeUrl.absoluteString)
    return try await connect(config: config)
  }

  // Generate some unique string with a given prefix using the alice nonce.
  static func generateUniqueString(prefix: String) -> String {
    var result = prefix + "-\(Int(Date().timeIntervalSince1970 * 1000))" + "-\(Int.random(in: 0..<1000000))"
    let add_symbols = max(RANDOM_ACCOUNT_LENGTH - result.count, 1)
    for _ in 0..<add_symbols {
      result += "0"
    }

    return result
  }

  static func createAccount(masterAccount: Account, amount: UInt128 = INITIAL_BALANCE, trials: UInt32 = 5) async throws -> Account {
    try await masterAccount.fetchState()
    let newAccountName = generateUniqueString(prefix: "test")
    let newPublicKey = try await(masterAccount.connection.signer.createKey(accountId: newAccountName,
                                                                           networkId: networkId))
    try await masterAccount.createAccount(newAccountId: newAccountName, publicKey: newPublicKey, amount: amount)
    return Account(connection: masterAccount.connection, accountId: newAccountName)
  }

  static func deployContract(workingAccount: Account, contractId: String, amount: UInt128 = UInt128(10000000)) async throws -> Contract {
    let newPublicKey = try await workingAccount.connection.signer.createKey(accountId: contractId, networkId: networkId)
    let data = Wasm().data
    try await workingAccount.createAndDeployContract(contractId: contractId,
                                                     publicKey: newPublicKey,
                                                     data: data.bytes,
                                                     amount: amount)
    let options = ContractOptions(viewMethods: [.getValue, .getLastResult],
                                  changeMethods: [.setValue,  .callPromise],
                                  sender: nil)
    let contract = Contract(account: workingAccount, contractId: contractId, options: options)
    return contract
  }
}
