//  Copyright © 2017 Schibsted. All rights reserved.

import Layout
import XCTest

private let xmlURL = Bundle(for: PerformanceTests.self).url(forResource: "Example", withExtension: "xml")!
private let nodeCount: Int = {
    let xmlData = try! Data(contentsOf: xmlURL)
    let rootNode = try! LayoutNode(xmlData: xmlData)
    return rootNode.children.count
}()

class PerformanceTests: XCTestCase {
    // MARK: Create and mount

    private func createNodes(_ count: Int) -> LayoutNode {
        var children = [LayoutNode]()
        for i in 0 ..< count {
            children.append(
                LayoutNode(
                    view: UILabel(),
                    expressions: [
                        "top": "previous.bottom + 10",
                        "left": "10",
                        "width": "100% - 20",
                        "height": "auto",
                        "font": "helvetica 17",
                        "numberOfLines": "0",
                        "text": "\(i). Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
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

    func testCreation() {
        measure {
            Layout.clearAllCaches()
            _ = self.createNodes(nodeCount)
        }
    }

    func testMount() {
        let rootNode = createNodes(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        measure {
            Layout.clearAllCaches()
            try! rootNode.mount(in: view)
            rootNode.unmount()
        }
    }

    func testCreateAndMount() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        measure {
            Layout.clearAllCaches()
            let rootNode = self.createNodes(nodeCount)
            try! rootNode.mount(in: view)
            rootNode.unmount()
        }
    }

    func testUpdate() {
        let rootNode = createNodes(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        try! rootNode.mount(in: view)
        measure {
            view.frame.size.width += 1
            view.frame.size.height -= 1
            rootNode.update()
        }
    }

    // MARK: AutoLayout

    private func createAutoLayout(_ count: Int) -> UIView {
        let container = UIView()
        var previous: UILabel?
        for i in 0 ..< count {
            let label = UILabel()
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

    func testAutoLayoutCreation() {
        measure {
            _ = self.createAutoLayout(nodeCount)
        }
    }

    func testAutoLayoutMount() {
        let rootView = createAutoLayout(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        measure {
            view.addSubview(rootView)
            rootView.frame = view.bounds
            rootView.layoutIfNeeded()
            rootView.removeFromSuperview()
        }
    }

    func testAutoLayoutCreateAndMount() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        measure {
            let rootView = self.createAutoLayout(nodeCount)
            view.addSubview(rootView)
            rootView.frame = view.bounds
            rootView.layoutIfNeeded()
            rootView.removeFromSuperview()
        }
    }

    func testAutoLayoutUpdate() {
        let rootView = createAutoLayout(nodeCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.addSubview(rootView)
        rootView.frame = view.bounds
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        rootView.layoutIfNeeded()
        measure {
            view.frame.size.width += 1
            view.frame.size.height -= 1
            rootView.layoutIfNeeded()
        }
    }

    // MARK: Text processing

    private let textNodesCount = 10

    private func createTextNodes(_ count: Int) -> LayoutNode {
        var children = [LayoutNode]()
        for i in 0 ..< count {
            children.append(
                LayoutNode(
                    view: UILabel(),
                    state: ["i": i],
                    expressions: [
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

    private func createRichTextNodes(_ count: Int) -> LayoutNode {
        var children = [LayoutNode]()
        for i in 0 ..< count {
            children.append(
                LayoutNode(
                    view: UILabel(),
                    state: ["i": i],
                    expressions: [
                        "top": "previous.bottom + 10",
                        "left": "10",
                        "width": "100% - 20",
                        "height": "auto",
                        "font": "helvetica 17",
                        "numberOfLines": "0",
                        "attributedText": "{i}. Lorem ipsum dolor sit amet, consectetur <b>adipiscing</b> elit, sed do eiusmod tempor incididunt ut labore et <i>dolore</i> magna aliqua.",
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

    func testUpdateTextNodes() {
        let rootNode = createTextNodes(textNodesCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        try! rootNode.mount(in: view)
        measure {
            view.frame.size.width += 1
            view.frame.size.height -= 1
            rootNode.update()
        }
    }

    func testUpdateRichTextNodes() {
        let rootNode = createRichTextNodes(textNodesCount)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        try! rootNode.mount(in: view)
        measure {
            view.frame.size.width += 1
            view.frame.size.height -= 1
            rootNode.update()
        }
    }

    // MARK: XML loading and parsing

    func testParseXML() {
        let xmlData = try! Data(contentsOf: xmlURL)
        measure {
            Layout.clearAllCaches()
            _ = try! LayoutNode(xmlData: xmlData)
        }
    }

    func testParseAndLoadXML() {
        measure {
            Layout.clearAllCaches()
            let xmlData = try! Data(contentsOf: xmlURL)
            _ = try! LayoutNode(xmlData: xmlData)
        }
    }

    func testParseAndLoadAndMount() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        measure {
            Layout.clearAllCaches()
            let xmlData = try! Data(contentsOf: xmlURL)
            let rootNode = try! LayoutNode(xmlData: xmlData)
            try! rootNode.mount(in: view)
            rootNode.unmount()
        }
    }
}
