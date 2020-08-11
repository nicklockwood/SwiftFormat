//
//  ContentView.swift
//  Moonshot
//
//  Created by Nick Lockwood on 27/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  let astronauts: [Astronaut] = Bundle.main.decode("astronauts.json")
  let missions: [Mission] = Bundle.main.decode("missions.json")

  @State var showCrew = false

  var body: some View {
    NavigationView {
      List(missions) { mission in
        NavigationLink(
          destination: MissionView(mission: mission)
        ) {
          Image(mission.image)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)

          VStack(alignment: .leading) {
            Text(mission.displayName)
              .font(.headline)
            Text(self.showCrew ?
              self.astronauts(in: mission) :
              mission.formattedLaunchDate
            )
          }
        }
      }
      .navigationBarTitle("Moonshot")
      .navigationBarItems(trailing: Button(action: {
        self.showCrew.toggle()
      }) {
        Text(self.showCrew ? "Show Date" : "Show Crew")
      })
    }
  }

  func astronauts(in mission: Mission) -> String {
    astronauts.filter { astronaut in
      mission.crew.contains(where: { $0.name == astronaut.id })
    }
    .map(\.name)
    .joined(separator: ", ")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
