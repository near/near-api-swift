//
//  URL+Params.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 10.12.2019.
//

import Foundation

public extension URL {
  var queryParameters: [String: String]? {
    guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
      let queryItems = components.queryItems else { return nil }
    return queryItems.reduce(into: [String: String]()) { result, item in
      result[item.name] = item.value
    }
  }
}
