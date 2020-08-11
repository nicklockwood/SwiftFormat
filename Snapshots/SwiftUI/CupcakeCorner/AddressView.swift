//
//  AddressView.swift
//  CupcakeCorner
//
//  Created by Nick Lockwood on 28/06/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import SwiftUI

struct AddressView: View {
  @ObservedObject var order = Order()

  var body: some View {
    Form {
      Section {
        TextField("Name", text: $order.data.name)
        TextField("Street Address", text: $order.data.streetAddress)
        TextField("City", text: $order.data.city)
        TextField("Zip", text: $order.data.zip)
      }

      Section {
        NavigationLink(destination: CheckoutView(order: order)) {
          Text("Check out")
        }
      }.disabled(!order.data.hasValidAddress)
    }
    .navigationBarTitle("Delivery details", displayMode: .inline)
  }
}

struct AddressView_Previews: PreviewProvider {
  static var previews: some View {
    AddressView(order: Order())
  }
}
