//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

// Common attributes shared by any view with a titleTextAttributes porperty
// The purpose of this protocol is to ensure consistent support between components
@objc protocol TitleTextAttributes {
    var titleColor: UIColor? { get set }
    var titleFont: UIFont? { get set }
}
