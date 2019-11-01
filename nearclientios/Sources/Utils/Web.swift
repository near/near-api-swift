//
//  Web.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation

internal struct ConnectionInfo {
  let url: URL
  let user: String? = nil
  let password: String? = nil
  let allowInsecure: Bool? = nil
  let timeout: TimeInterval? = nil
  let headers: [String: Any]? = nil
}
