//
//  DetailView.swift
//  Bookworm
//
//  Created by Nick Lockwood on 30/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import CoreData
import SwiftUI

struct DetailView: View {
  let book: Book

  @Environment(\.managedObjectContext) var moc
  @Environment(\.presentationMode) var presentationMode
  @State private var showingDeleteAlert = false

  var body: some View {
    GeometryReader { geo in
      VStack {
        ZStack(alignment: .bottomTrailing) {
          Image(self.book.genre ?? "Fantasy")
            .frame(maxWidth: geo.size.width)

          Text(self.book.genre?.uppercased() ?? "FANTASY")
            .font(.caption)
            .fontWeight(.black)
            .padding(8)
            .foregroundColor(.white)
            .background(Color.black.opacity(0.75))
            .clipShape(Capsule())
            .offset(x: -5, y: -5)
        }

        Text(self.book.author ?? "Unknown author")
          .font(.title)
          .foregroundColor(.secondary)

        Text(self.book.review ?? "No review")
          .padding()

        Text(self.formattedDate(for: self.book))
          .padding()

        RatingView(rating: .constant(Int(self.book.rating)))
          .font(.largeTitle)

        Spacer()
      }
    }
    .navigationBarTitle(Text(book.title ?? "Unknown book"), displayMode: .inline)
    .alert(isPresented: $showingDeleteAlert) {
      Alert(title: Text("Delete book"), message: Text("Are you sure?"), primaryButton: .destructive(Text("Delete")) {
        self.deleteBook()
      }, secondaryButton: .cancel())
    }
    .navigationBarItems(trailing: Button(action: {
      self.showingDeleteAlert = true
    }) {
      Image(systemName: "trash")
    })
  }

  func formattedDate(for book: Book) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return "Date added: \(formatter.string(from: book.date ?? Date()))"
  }

  func deleteBook() {
    moc.delete(book)

    try? moc.save()
    presentationMode.wrappedValue.dismiss()
  }
}

struct DetailView_Previews: PreviewProvider {
  static let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

  static var previews: some View {
    let book = Book(context: moc)
    book.title = "Test book"
    book.author = "Test author"
    book.genre = "Fantasy"
    book.rating = 4
    book.review = "This was a great book; I really enjoyed it."

    return NavigationView {
      DetailView(book: book)
    }
  }
}
