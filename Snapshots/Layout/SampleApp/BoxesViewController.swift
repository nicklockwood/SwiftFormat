//  Copyright © 2017 Schibsted. All rights reserved.

import Layout
import UIKit

class BoxesViewController: UIViewController {
    var toggled = false {
        didSet {
            layoutNode?.setState(["isToggled": toggled])
        }
    }

    @IBOutlet var layoutNode: LayoutNode? {
        didSet {
            layoutNode?.setState(["isToggled": toggled])
        }
    }

    @IBAction func setToggled() {
        UIView.animate(withDuration: 0.4) {
            self.toggled = true
        }
    }

    @IBAction func setUntoggled() {
        UIView.animate(withDuration: 0.4) {
            self.toggled = false
        }
    }
}
