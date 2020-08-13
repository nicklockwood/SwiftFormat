//
//  AstronautView.swift
//  Moonshot
//
//  Created by Nick Lockwood on 27/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct AstronautView: View {
  let astronaut: Astronaut
  let missions: [Mission]

  var body: some View {
    GeometryReader { geometry in
      ScrollView(.vertical) {
        VStack {
          Image(self.astronaut.id)
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width)

          Text(self.astronaut.description)
            .padding()
            .layoutPriority(1)

          ForEach(self.missions) { mission in
            NavigationLink(
              destination: MissionView(mission: mission)
            ) {
              HStack {
                Image(mission.image)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 44, height: 44)

                VStack(alignment: .leading) {
                  Text(mission.displayName)
                    .font(.headline)
                  Text(mission.formattedLaunchDate)
                    .foregroundColor(.secondary)
                }

                Spacer()
              }
              .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
          }

          Spacer(minLength: 25)
        }
      }
    }
    .navigationBarTitle(Text(astronaut.name), displayMode: .inline)
  }

  init(astronaut: Astronaut) {
    self.astronaut = astronaut
    let allMissions: [Mission] = Bundle.main.decode("missions.json")
    missions = allMissions.filter {
      $0.crew.contains(where: { $0.name == astronaut.id })
    }
  }
}

struct AstronautView_Previews: PreviewProvider {
  static let astronauts: [Astronaut] = Bundle.main.decode("astronauts.json")

  static var previews: some View {
    NavigationView {
      AstronautView(astronaut: astronauts[0])
    }
  }
}
