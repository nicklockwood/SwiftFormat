//
//  Mission.swift
//  Moonshot
//
//  Created by Nick Lockwood on 27/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

struct Mission: Codable, Identifiable {
  struct CrewRole: Codable {
    var name: String
    var role: String
  }

  var id: Int
  var launchDate: Date?
  var crew: [CrewRole]
  var description: String

  var displayName: String {
    "Apollo \(id)"
  }

  var image: String {
    "apollo\(id)"
  }

  var formattedLaunchDate: String {
    guard let date = launchDate else {
      return "N/A"
    }
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }
}
