//  Copyright © 2017 Schibsted. All rights reserved.

import Layout
import UIKit

class PreviewViewController: UIViewController, LayoutLoading {}

class EditViewController: UIViewController {
    var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play,
                                                            target: self,
                                                            action: #selector(_showPreview))
        navigationItem.title = "Edit"

        textView = UITextView(frame: view.bounds)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.dataDetectorTypes = []
        textView.font = UIFont(name: "Courier", size: 13)!
        textView.text = try! String(contentsOf: Bundle.main.url(forResource: "Default", withExtension: "xml")!)

        if #available(iOS 11.0, *) {
            textView.smartQuotesType = .no
            textView.smartDashesType = .no
            textView.smartInsertDeleteType = .no
        }

        view.addSubview(textView)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        let userInfo = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        textView.contentInset.bottom = keyboardSize.height
        textView.scrollIndicatorInsets.bottom = keyboardSize.height
    }

    @objc private func keyboardWillHide() {
        textView.contentInset.bottom = 0
        textView.scrollIndicatorInsets.bottom = 0
    }

    @objc private func _showPreview() {
        showPreview(animated: true)
    }

    func showPreview(animated: Bool) {
        let previewController = PreviewViewController()
        previewController.title = "Preview"
        previewController.view.backgroundColor = .white
        do {
            _ = view // Load the view
            let xmlData = (textView.text ?? "").data(using: .utf8) ?? Data()
            previewController.layoutNode = try LayoutNode(xmlData: xmlData)
        } catch {
            previewController.layoutError(LayoutError(error))
        }
        navigationController?.pushViewController(previewController, animated: animated)
    }
}
