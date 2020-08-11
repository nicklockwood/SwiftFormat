//
//  ContentView.swift
//  WordScramble
//
//  Created by Nick Lockwood on 26/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @State private var usedWords = [String]()
  @State private var rootWord = ""
  @State private var newWord = ""

  @State private var errorTitle = ""
  @State private var errorMessage = ""
  @State private var showError = false

  var body: some View {
    NavigationView {
      VStack {
        TextField(
          "Enter your word",
          text: $newWord,
          onCommit: addNewWord
        )
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
        .autocapitalization(.none)

        List(usedWords, id: \.self) {
          Image(systemName: "\($0.count).circle")
          Text($0)
        }

        Text("Score: \(score)")
          .font(.largeTitle)
          .padding()
      }
      .navigationBarTitle(rootWord)
      .onAppear(perform: startGame)
      .alert(isPresented: $showError) {
        Alert(title: Text(errorTitle), message: Text(errorMessage))
      }
      .navigationBarItems(leading: Button("Restart", action: startGame))
    }
  }

  var score: Int {
    usedWords.reduce(0) { total, word in total + word.count }
  }

  func addNewWord() {
    let answer = newWord
      .lowercased()
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !answer.isEmpty else {
      return
    }

    guard answer.count >= 3 else {
      wordError(title: "Word too short", message: "Must be at least 3 letters")
      return
    }

    guard isOriginal(answer) else {
      wordError(title: "Word used already", message: "Be more original")
      return
    }

    guard isPossible(answer) else {
      wordError(title: "Word not recognized", message: "You can't just make them up you know!")
      return
    }

    guard isReal(answer) else {
      wordError(title: "Word not possible", message: "That isn't a real word")
      return
    }

    usedWords.insert(answer, at: 0)
    newWord = ""
  }

  func startGame() {
    usedWords.removeAll()
    if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
      if let startWords = try? String(contentsOf: startWordsURL) {
        let allWords = startWords.components(separatedBy: "\n")
        rootWord = allWords.randomElement() ?? "silkworm"
        return
      }
    }

    fatalError("Could not load start.txt")
  }

  func isOriginal(_ word: String) -> Bool {
    !usedWords.contains(word) && word != rootWord
  }

  func isPossible(_ word: String) -> Bool {
    var tempWord = rootWord.lowercased()

    for letter in word {
      if let pos = tempWord.firstIndex(of: letter) {
        tempWord.remove(at: pos)
      } else {
        return false
      }
    }

    return true
  }

  func isReal(_ word: String) -> Bool {
    let checker = UITextChecker()
    let range = NSRange(location: 0, length: word.utf16.count)
    let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
    return misspelledRange.location == NSNotFound
  }

  func wordError(title: String, message: String) {
    errorTitle = title
    errorMessage = message
    showError = true
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
