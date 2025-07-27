//
//  StrongOutletsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/24/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class StrongOutletsTests: XCTestCase {
    func testRemoveWeakFromOutlet() {
        let input = """
        @IBOutlet weak var label: UILabel!
        """
        let output = """
        @IBOutlet var label: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    func testRemoveWeakFromPrivateOutlet() {
        let input = """
        @IBOutlet private weak var label: UILabel!
        """
        let output = """
        @IBOutlet private var label: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    func testRemoveWeakFromOutletOnSplitLine() {
        let input = """
        @IBOutlet
        weak var label: UILabel!
        """
        let output = """
        @IBOutlet
        var label: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    func testNoRemoveWeakFromNonOutlet() {
        let input = """
        weak var label: UILabel!
        """
        testFormatting(for: input, rule: .strongOutlets)
    }

    func testNoRemoveWeakFromNonOutletAfterOutlet() {
        let input = """
        @IBOutlet weak var label1: UILabel!
        weak var label2: UILabel!
        """
        let output = """
        @IBOutlet var label1: UILabel!
        weak var label2: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    func testNoRemoveWeakFromDelegateOutlet() {
        let input = """
        @IBOutlet weak var delegate: UITableViewDelegate?
        """
        testFormatting(for: input, rule: .strongOutlets)
    }

    func testNoRemoveWeakFromDataSourceOutlet() {
        let input = """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        """
        testFormatting(for: input, rule: .strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDelegateOutlet() {
        let input = """
        @IBOutlet weak var delegate: UITableViewDelegate?
        @IBOutlet weak var label1: UILabel!
        """
        let output = """
        @IBOutlet weak var delegate: UITableViewDelegate?
        @IBOutlet var label1: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDataSourceOutlet() {
        let input = """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        @IBOutlet weak var label1: UILabel!
        """
        let output = """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        @IBOutlet var label1: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }
}
