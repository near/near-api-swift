//
//  Web.swift
//  nearclientios
//
//  Created by Dmitry Kurochka on 10/30/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import Foundation
import PromiseKit

internal struct ConnectionInfo {
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

private func fetch(url: URL, params: [String: Any]?) -> Promise<Data> {
  let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
  var request = URLRequest(url: url)
  request.httpMethod = params.flatMap {_ in "POST"} ?? "GET"
  request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-type")
  request.httpBody = params.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
  return Promise.init { seal in
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error { return seal.reject(error) }
      let result = data.flatMap {try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Any]}
      if result?["ok"] as? Bool == true, let data = data {
        seal.fulfill(data)
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

internal func fetchJson(connection: ConnectionInfo, json: [String: Any]?) -> Promise<Data> {
  let url = connection.url
  return fetch(url: url, params: json)
}

func fetchJson(url: URL, json: [String: Any]?) -> Promise<Data> {
  return fetch(url: url, params: json)
}
