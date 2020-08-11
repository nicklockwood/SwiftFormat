//
//  ContentView.swift
//  GuessTheFlag
//
//  Created by Nick Lockwood on 25/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct Shake: GeometryEffect {
  var amount: CGFloat = 10
  var shakesPerUnit = 4
  var animatableData: CGFloat

  func effectValue(size _: CGSize) -> ProjectionTransform {
    ProjectionTransform(CGAffineTransform(translationX:
      amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
      y: 0))
  }
}

struct ContentView: View {
  @State private var countries = ["Estonia", "France", "Germany", "Ireland", "Italy", "Nigeria", "Poland", "Russia", "Spain", "The UK", "The US"].shuffled()
  @State private var correctAnswer = Int.random(in: 0 ... 2)

  @State private var showingScore = false
  @State private var scoreTitle = ""
  @State private var scoreMessage = ""
  @State private var score = 0

  @State private var flagAngles = [0.0, 0.0, 0.0]
  @State private var flagOpacities = [1.0, 1.0, 1.0]
  @State private var flagShakes: [CGFloat] = [0, 0, 0]

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [.blue, .black]),
        startPoint: .top,
        endPoint: .bottom
      )
      .edgesIgnoringSafeArea(.all)

      VStack(spacing: 30) {
        VStack {
          Text("Tap the flag of")
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.4), radius: 2, y: 2)
          Text(countries[correctAnswer])
            .foregroundColor(.white)
            .font(.largeTitle)
            .fontWeight(.black)
            .shadow(color: Color.black.opacity(0.4), radius: 5, y: 5)
        }

        ForEach(0 ..< 3) { number in
          Button(action: {
            self.flagTapped(number)
          }) {
            Image(self.countries[number])
              .renderingMode(.original)
              .clipShape(Capsule())
              .rotation3DEffect(.degrees(self.flagAngles[number]),
                                axis: (x: 0, y: 1, z: 0))
              .opacity(self.flagOpacities[number])
              .modifier(Shake(amount: 20, animatableData: self.flagShakes[number]))
              .animation(.default)
              .shadow(color: Color.black.opacity(0.4), radius: 5, y: 5)
          }
        }

        Text("Score: \(score)")
          .foregroundColor(.white)
          .font(.title)
          .shadow(color: Color.black.opacity(0.4), radius: 5, y: 5)

        Spacer()
      }
    }
    .alert(isPresented: $showingScore) {
      Alert(
        title: Text(scoreTitle),
        message: Text(scoreMessage),
        dismissButton: .default(Text("Continue"), action: {
          self.askQuestion()
        })
      )
    }
  }

  func flagTapped(_ number: Int) {
    if number == correctAnswer {
      score += 1
      scoreTitle = "Correct"
      scoreMessage = "Your score is \(score)"
      flagAngles[number] += 360
      flagOpacities = flagOpacities.enumerated().map { index, _ in
        index == number ? 1 : 0.2
      }
    } else {
      score = 0
      scoreTitle = "Wrong"
      scoreMessage = "That's the flag of \(countries[number])!"
      flagShakes[number] += 1
    }
    showingScore = true
  }

  func askQuestion() {
    countries.shuffle()
    correctAnswer = Int.random(in: 0 ... 2)
    flagOpacities = [1.0, 1.0, 1.0]
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
