//
//  Web.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit

public struct ConnectionInfo {
  let url: URL
  let user: String? = nil
  let password: String? = nil
  let allowInsecure: Bool? = nil
  let timeout: TimeInterval? = nil
  let headers: [String: Any]? = nil
}

enum HTTPError: Error {
  case unknown
  case error(status: Int, message: String?)
}

private func fetch(url: URL, params: [String: Any]?) -> Promise<Any> {

  let session = URLSession.shared
  var request = URLRequest(url: url)
  request.httpMethod = params.flatMap {_ in "POST"} ?? "GET"
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  request.httpBody = params.flatMap { try? $0.toData() }
  return Promise.init { seal in
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error { return seal.reject(error) }
      let result = data.flatMap {try? $0.toDictionary()}
      if let json = result?["result"] {
        seal.fulfill(json)
      } else if let httpResponse = response as? HTTPURLResponse {
        let error = HTTPError.error(status: httpResponse.statusCode,
                                    message: data.flatMap({ String(data: $0, encoding: .utf8) }))
        seal.reject(error)
      } else {
        seal.reject(HTTPError.unknown)
      }
    }
    task.resume()
  }
}

public func fetchJson(connection: ConnectionInfo, json: [String: Any]?) -> Promise<Any> {
  let url = connection.url
  return fetch(url: url, params: json)
}

func fetchJson(url: URL, json: [String: Any]?) -> Promise<Any> {
  return fetch(url: url, params: json)
}
