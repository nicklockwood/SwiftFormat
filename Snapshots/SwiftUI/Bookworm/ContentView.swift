//
//  ContentView.swift
//  Bookworm
//
//  Created by Nick Lockwood on 29/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @Environment(\.managedObjectContext) var moc
  @FetchRequest(entity: Book.entity(), sortDescriptors: [
    NSSortDescriptor(keyPath: \Book.title, ascending: true),
    NSSortDescriptor(keyPath: \Book.author, ascending: true),
  ]) var books: FetchedResults<Book>

  @State private var showingAddScreen = false

  var body: some View {
    NavigationView {
      List {
        ForEach(books, id: \.self) { book in
          NavigationLink(destination:
            DetailView(book: book).environment(\.managedObjectContext, self.moc)
          ) {
            EmojiRatingView(rating: book.rating)
              .font(.largeTitle)

            VStack(alignment: .leading) {
              Text(book.title ?? "Unknown title")
                .font(.headline)
                .foregroundColor(book.rating < 2 ? .red : .primary)
              Text(book.author ?? "Unknown author")
                .foregroundColor(.secondary)
            }
          }
        }
        .onDelete(perform: deleteBooks(at:))
      }
      .navigationBarTitle("Bookworm")
      .navigationBarItems(leading: EditButton(), trailing: Button(action: {
        self.showingAddScreen.toggle()
      }) {
        Image(systemName: "plus")
      })
      .sheet(isPresented: $showingAddScreen) {
        AddBookView().environment(\.managedObjectContext, self.moc)
      }
    }
  }

  func deleteBooks(at offsets: IndexSet) {
    for offset in offsets {
      let book = books[offset]
      moc.delete(book)
      try? moc.save()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
