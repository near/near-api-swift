//
//  AccountInfo.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

/**
// Format of the account stored on disk.
*/
internal protocol AccountInfo {
  var account_id: String {get}
  var private_key: String {get}
}
