//
//  Account.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt

internal struct FinalExecutionOutcome {
  let smt: Int
}

internal struct Account {
  func createAccount(newAccountId: String, publicKey: PublicKey, amount: BigInt) -> Promise<FinalExecutionOutcome> {
    return .value(FinalExecutionOutcome(smt: 0))
  }
}
