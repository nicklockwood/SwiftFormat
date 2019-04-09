//
//  ViewController.swift
//  Layout
//
//  Created by Nick Lockwood on 21/09/2016.
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

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet private var leftField: UITextField!
    @IBOutlet private var topField: UITextField!
    @IBOutlet private var widthField: UITextField!
    @IBOutlet private var heightField: UITextField!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var layoutView: UIView!

    var selectedView: UIView? {
        didSet {
            oldValue?.layer.borderWidth = 0
            selectedView?.layer.borderWidth = 2
            selectedView?.layer.borderColor = UIColor.black.cgColor
            leftField.isEnabled = true
            leftField.text = selectedView?.left
            topField.isEnabled = true
            topField.text = selectedView?.top
            widthField.isEnabled = true
            widthField.text = selectedView?.width
            heightField.isEnabled = true
            heightField.text = selectedView?.height
        }
    }

    @IBAction func didTap(sender: UITapGestureRecognizer) {
        let point = sender.location(in: layoutView)
        if let view = layoutView.hitTest(point, with: nil), view != layoutView {
            selectedView = view
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }

    func updateLayout() {
        do {
            for view in layoutView.subviews {
                try view.updateLayout()
            }
            errorLabel.text = nil
        } catch {
            errorLabel.text = "\(error)"
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_: UITextField) {
        selectedView?.left = leftField.text
        selectedView?.top = topField.text
        selectedView?.width = widthField.text
        selectedView?.height = heightField.text
        updateLayout()
    }
}
