//
//  FileManager.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 08.11.2019.
//

import Foundation

public extension FileManager {
  func ensureDir(path: String) throws -> Void {
    try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
  }

  var targetDirectory: URL {
    let paths = urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
}
