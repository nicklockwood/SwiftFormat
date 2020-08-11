//
//  MissionView.swift
//  Moonshot
//
//  Created by Nick Lockwood on 27/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct MissionView: View {
  struct CrewMember {
    let role: String
    let astronaut: Astronaut
  }

  let mission: Mission
  let astronauts: [CrewMember]

  var body: some View {
    GeometryReader { geometry in
      ScrollView(.vertical) {
        VStack {
          Image(self.mission.image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: geometry.size.width * 0.7)
            .padding(.top)

          Text(self.mission.formattedLaunchDate)
            .padding()
            .font(.headline)

          Text(self.mission.description)
            .padding()

          ForEach(self.astronauts, id: \.role) { crewMember in
            NavigationLink(
              destination: AstronautView(
                astronaut: crewMember.astronaut
              )
            ) {
              HStack {
                Image(crewMember.astronaut.id)
                  .resizable()
                  .frame(width: 83, height: 60)
                  .clipShape(Capsule())
                  .overlay(
                    Capsule().stroke(Color.primary, lineWidth: 1)
                  )

                VStack(alignment: .leading) {
                  Text(crewMember.astronaut.name)
                    .font(.headline)
                  Text(crewMember.role)
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
      .navigationBarTitle(Text(self.mission.displayName), displayMode: .inline)
    }
  }

  init(mission: Mission) {
    self.mission = mission
    let allAstronauts: [Astronaut] = Bundle.main.decode("astronauts.json")
    astronauts = mission.crew.compactMap { crew in
      guard let astronaut = allAstronauts.first(where: {
        $0.id == crew.name
      }) else {
        return nil
      }
      return CrewMember(role: crew.role, astronaut: astronaut)
    }
  }
}

struct MissionView_Previews: PreviewProvider {
  static let missions: [Mission] = Bundle.main.decode("missions.json")

  static var previews: some View {
    MissionView(mission: missions[0])
  }
}
