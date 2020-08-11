//
//  Bundle+Decodable.swift
//  Moonshot
//
//  Created by Nick Lockwood on 27/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

extension Bundle {
  func decode<T: Decodable>(_ file: String) -> T {
    guard let url = url(forResource: file, withExtension: nil) else {
      fatalError("Failed to locate \(file) in bundle.")
    }

    guard let data = try? Data(contentsOf: url) else {
      fatalError("Failed to load \(file) from bundle.")
    }

    let decoder = JSONDecoder()
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "y-MM-dd"
    decoder.dateDecodingStrategy = .formatted(dateFormatter)
    guard let loaded = try? decoder.decode(T.self, from: data) else {
      fatalError("Failed to decode \(file) from bundle.")
    }

    return loaded
  }
}
