//
//  ColorLabel.swift
//  Colors
//
//  Created by Nick Lockwood on 30/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import UIKit

class ColorLabel: UILabel {
    private func updateColor() {
        do {
            backgroundColor = .clear
            textColor = try UIColor(expression: text ?? "")
        } catch {
            backgroundColor = .red
            textColor = .black
        }
    }

    override var text: String? {
        get { return super.text }
        set {
            super.text = newValue
            updateColor()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        updateColor()
    }
}
