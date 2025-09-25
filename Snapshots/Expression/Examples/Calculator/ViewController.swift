//
//  ViewController.swift
//  Calculator
//
//  Created by Nick Lockwood on 17/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Expression
import UIKit

final class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet private var inputField: UITextField!
    @IBOutlet private var outputView: UITextView!

    private var output = NSMutableAttributedString()

    private func addOutput(_ string: String, color: UIColor) {
        let text = NSAttributedString(string: string + "\n\n", attributes: [
            NSAttributedStringKey.foregroundColor: color,
            NSAttributedStringKey.font: outputView.font!,
        ])

        output.replaceCharacters(in: NSMakeRange(0, 0), with: text)
        outputView.attributedText = output
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        output.append(outputView.attributedText)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, text != "" {
            do {
                let result = try Expression(text).evaluate()
                addOutput(String(format: "= %g", result), color: .black)
            } catch {
                addOutput("\(error)", color: .red)
            }
        }
        return false
    }
}
