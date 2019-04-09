//
//  ViewController.swift
//  Benchmark
//
//  Created by Nick Lockwood on 13/02/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Expression
import JavaScriptCore
import UIKit

let parseRepetitions = 50
let evalRepetitions = 50

private func time(_ block: () -> Void) -> Double {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    return CFAbsoluteTimeGetCurrent() - start
}

private func time(_ setup: () -> Any, _ block: (Any) -> Void) -> Double {
    let value = setup()
    let start = CFAbsoluteTimeGetCurrent()
    block(value)
    return CFAbsoluteTimeGetCurrent() - start
}

let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.groupingSeparator = ","
    formatter.numberStyle = .decimal
    return formatter
}()

class ViewController: UITableViewController {
    var results: [(String, [[(String, Double)]])] = []

    @objc func update() {
        results = [
            ("End-to-end (x\(parseRepetitions))", [
                [
                    ("Short Expressions", time {
                        _ = evaluateExpressions(shortExpressions)
                    }),
                    ("Short AnyExpressions", time {
                        _ = evaluateAnyExpressions(shortExpressions)
                    }),
                    ("Short NSExpressions", time {
                        _ = evaluateNSExpressions(shortNSExpressions)
                    }),
                    ("Short JS Expressions", time {
                        _ = evaluateJSExpressions(shortExpressions)
                    }),
                ],
                [
                    ("Medium Expressions", time {
                        _ = evaluateExpressions(mediumExpressions)
                    }),
                    ("Medium AnyExpressions", time {
                        _ = evaluateAnyExpressions(mediumExpressions)
                    }),
                    ("Medium NSExpressions", time {
                        _ = evaluateNSExpressions(mediumNSExpressions)
                    }),
                    ("Medium JS Expressions", time {
                        _ = evaluateJSExpressions(mediumExpressions)
                    }),
                ],
                [
                    ("Long Expressions", time {
                        _ = evaluateExpressions(longExpressions)
                    }),
                    ("Long AnyExpressions", time {
                        _ = evaluateAnyExpressions(longExpressions)
                    }),
                    ("Long NSExpressions", time {
                        _ = evaluateNSExpressions(longNSExpressions)
                    }),
                    ("Long JS Expressions", time {
                        _ = evaluateJSExpressions(longExpressions)
                    }),
                ],
            ]),
            ("Setup (x\(parseRepetitions))", [
                [
                    ("Short Expressions", time {
                        _ = buildExpressions(shortExpressions)
                    }),
                    ("Short AnyExpressions", time {
                        _ = buildAnyExpressions(shortExpressions)
                    }),
                    ("Short NSExpressions", time {
                        _ = buildNSExpressions(shortNSExpressions)
                    }),
                    ("Short JS Expressions", time {
                        _ = buildJSExpressions(shortExpressions)
                    }),
                ],
                [
                    ("Medium Expressions", time {
                        _ = buildExpressions(mediumExpressions)
                    }),
                    ("Medium AnyExpressions", time {
                        _ = buildAnyExpressions(mediumExpressions)
                    }),
                    ("Medium NSExpressions", time {
                        _ = buildNSExpressions(mediumNSExpressions)
                    }),
                    ("Medium JS Expressions", time {
                        _ = buildJSExpressions(mediumExpressions)
                    }),
                ],
                [
                    ("Long Expressions", time {
                        _ = buildExpressions(longExpressions)
                    }),
                    ("Long AnyExpressions", time {
                        _ = buildAnyExpressions(longExpressions)
                    }),
                    ("Long NSExpressions", time {
                        _ = buildNSExpressions(longNSExpressions)
                    }),
                    ("Long JS Expressions", time {
                        _ = buildJSExpressions(longExpressions)
                    }),
                ],
            ]),
            ("Evaluation (x\(evalRepetitions))", [
                [
                    ("Short Expressions", time(
                        { buildExpressions(shortExpressions) },
                        { _ = evaluateExpressions($0 as! [Expression]) }
                    )),
                    ("Short AnyExpressions", time(
                        { buildAnyExpressions(shortExpressions) },
                        { _ = evaluateAnyExpressions($0 as! [AnyExpression]) }
                    )),
                    ("Short NSExpressions", time(
                        { buildNSExpressions(shortNSExpressions) },
                        { _ = evaluateNSExpressions($0 as! [NSExpression]) }
                    )),
                    ("Short JS Expressions", time(
                        { buildJSExpressions(shortExpressions) },
                        { _ = evaluateJSExpressions($0 as! [() -> JSValue]) }
                    )),
                ],
                [
                    ("Medium Expressions", time(
                        { buildExpressions(mediumExpressions) },
                        { _ = evaluateExpressions($0 as! [Expression]) }
                    )),
                    ("Medium AnyExpressions", time(
                        { buildAnyExpressions(mediumExpressions) },
                        { _ = evaluateAnyExpressions($0 as! [AnyExpression]) }
                    )),
                    ("Medium NSExpressions", time(
                        { buildNSExpressions(mediumNSExpressions) },
                        { _ = evaluateNSExpressions($0 as! [NSExpression]) }
                    )),
                    ("Medium JS Expressions", time(
                        { buildJSExpressions(mediumExpressions) },
                        { _ = evaluateJSExpressions($0 as! [() -> JSValue]) }
                    )),
                ],
                [
                    ("Long Expressions", time(
                        { buildExpressions(longExpressions) },
                        { _ = evaluateExpressions($0 as! [Expression]) }
                    )),
                    ("Long AnyExpressions", time(
                        { buildAnyExpressions(longExpressions) },
                        { _ = evaluateAnyExpressions($0 as! [AnyExpression]) }
                    )),
                    ("Long NSExpressions", time(
                        { buildNSExpressions(longNSExpressions) },
                        { _ = evaluateNSExpressions($0 as! [NSExpression]) }
                    )),
                    ("Long JS Expressions", time(
                        { buildJSExpressions(longExpressions) },
                        { _ = evaluateJSExpressions($0 as! [() -> JSValue]) }
                    )),
                ],
            ]),
        ]
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(update), for: .valueChanged)
        refreshControl?.beginRefreshing()
        update()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return results.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results[section].1.flatMap { $0 }.count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return results[section].0
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subsections = results[indexPath.section].1
        let row = subsections.flatMap { $0 }[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")

        let subsection = subsections[Int(indexPath.row / subsections[0].count)]
        let useMS = !subsection.contains(where: { $0.1 < 0.001 })

        cell.textLabel?.text = row.0
        cell.detailTextLabel?.text = useMS ?
            "\(formatter.string(from: Int(row.1 * 1000) as NSNumber)!)ms" :
            "\(formatter.string(from: Int(row.1 * 1000000) as NSNumber)!)µs"

        cell.detailTextLabel?.textColor = {
            if !subsection.contains(where: { $0.1 > row.1 }) {
                return .red // worst
            } else if !subsection.contains(where: { $0.1 < row.1 }) {
                return UIColor(red: 0, green: 0.75, blue: 0, alpha: 1) // best
            } else {
                return .gray
            }
        }()
        return cell
    }
}
