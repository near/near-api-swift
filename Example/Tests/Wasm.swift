//
//  Wasm.swift
//  nearclientios_Tests
//
//  Created by Dmytro Kurochka on 04.12.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

internal class Wasm {
  lazy var data: Data = {
    let testBundle = Bundle(for: type(of: self))
    guard let fileURL = testBundle.url(forResource: "main", withExtension: "wasm") else { fatalError() }
    return try! Data(contentsOf: fileURL)
  }()
}
