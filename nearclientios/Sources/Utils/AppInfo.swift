//
//  AppInfo.swift
//  nearclientios
//
//  Created by Dmytro Kurochka on 10.12.2019.
//

import Foundation
import UIKit

extension UIApplication {
  static var urlSchemes: [String]? {
    return (Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])?.first?["CFBundleURLSchemes"] as? [String]
  }
}
