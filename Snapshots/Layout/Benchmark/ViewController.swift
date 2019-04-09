//  Copyright © 2017 Schibsted. All rights reserved.

import Layout
import UIKit

class ViewController: UIViewController, LayoutLoading {
    override func viewDidLoad() {
        super.viewDidLoad()
        loadLayout(
            named: "Benchmark.xml",
            state: getState()
        )
    }

    func getState() -> [String: [String: TimeInterval]] {
        return [
            "layoutResults": getLayoutTimings(),
            "autoLayoutResults": getAutoLayoutTimings(),
        ]
    }

    @objc func refresh() {
        Layout.clearAllCaches()
        layoutNode?.setState(getState())
    }
}

private func getLayoutTimings(nodeCount: Int = 100) -> [String: TimeInterval] {
    var timings = [String: TimeInterval]()

    do {
        // Creation
        let start = CACurrentMediaTime()
        _ = createNodes(nodeCount)
        timings["create"] = CACurrentMediaTime() - start
    }

    do {
        // Mount
        let rootNode = createNodes(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let start = CACurrentMediaTime()
        try! rootNode.mount(in: view)
        timings["mount"] = CACurrentMediaTime() - start
    }

    do {
        // Create and mount
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let start = CACurrentMediaTime()
        let rootNode = createNodes(nodeCount)
        try! rootNode.mount(in: view)
        timings["createAndMount"] = CACurrentMediaTime() - start
    }

    do {
        // Update
        let rootNode = createNodes(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        try! rootNode.mount(in: view)
        let start = CACurrentMediaTime()
        view.frame.size = CGSize(width: 150, height: 400)
        rootNode.update()
        timings["update"] = CACurrentMediaTime() - start
    }

    return timings
}

private func createNodes(_ count: Int) -> LayoutNode {
    var children = [LayoutNode]()
    for i in 0 ..< count {
        children.append(
            LayoutNode(
                view: UILabel(),
                constants: ["i": i],
                expressions: [
                    "backgroundColor": "i % 2 == 0 ? #ff0000 : #00ff00",
                    "top": "previous.bottom + 10",
                    "left": "10",
                    "width": "100% - 20",
                    "height": "auto",
                    "font": "helvetica 17",
                    "numberOfLines": "0",
                    "text": "{i}. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                ]
            )
        )
    }
    return LayoutNode(
        expressions: [
            "width": "100%",
            "height": "auto",
        ],
        children: children
    )
}

private func getAutoLayoutTimings(nodeCount: Int = 100) -> [String: TimeInterval] {
    var timings = [String: TimeInterval]()

    do {
        // Creation
        let start = CACurrentMediaTime()
        _ = createAutoLayout(nodeCount)
        timings["create"] = CACurrentMediaTime() - start
    }

    do {
        // Mount
        let rootView = createAutoLayout(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let start = CACurrentMediaTime()
        view.addSubview(rootView)
        rootView.frame = view.bounds
        rootView.layoutIfNeeded()
        timings["mount"] = CACurrentMediaTime() - start
    }

    do {
        // Create and mount
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let start = CACurrentMediaTime()
        let rootView = createAutoLayout(nodeCount)
        view.addSubview(rootView)
        rootView.frame = view.bounds
        rootView.layoutIfNeeded()
        timings["createAndMount"] = CACurrentMediaTime() - start
    }

    do {
        // Update
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let rootView = createAutoLayout(nodeCount)
        rootView.frame = view.bounds
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(rootView)
        rootView.layoutIfNeeded()
        let start = CACurrentMediaTime()
        view.frame.size = CGSize(width: 150, height: 400)
        rootView.layoutIfNeeded()
        timings["update"] = CACurrentMediaTime() - start
    }

    return timings
}

private func createAutoLayout(_ count: Int) -> UIView {
    let container = UIView()
    var previous: UILabel?
    for i in 0 ..< count {
        let label = UILabel()
        label.backgroundColor = (i % 2 == 0) ?
            UIColor(red: 1, green: 0, blue: 0, alpha: 1) :
            UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        label.numberOfLines = 0
        label.font = UIFont(name: "Helvetica", size: 17)
        label.text = "\(i). Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        if let previous = previous {
            label.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 10).isActive = true
        } else {
            label.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        }
        previous = label
        label.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 10).isActive = true
        label.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -20).isActive = true
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
    }
    return container
}
