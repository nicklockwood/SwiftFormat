//
//  Singularize.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 02/01/2024.
//  Copyright 2024 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
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

import Foundation

// Inspired by https://github.com/Cosmo/GrammaticalNumber
private let rules: [(String, replacement: String)] = [
    ("s$", ""),
    ("eaux$", "eau"),
    ("ae$", "a"),
    ("era$", "us"),
    ("(e)ae$", "$1us"),
    ("(ss)$", "$1"),
    ("(tt?)i$", "$1o"),
    ("([tivdl])a$", "$1um"),
    ("(i)ves$", "$1fe"),
    ("([alr]|oo|ie)ves$", "$1f"),
    ("([th]ive)s$", "$1"),
    ("([^aeiouy]|qu)ies$", "$1y"),
    ("(ov|mb)ies$", "$1ie"),
    ("(x|ch|ss|sh)es$", "$1"),
    ("([ml])ice$", "$1ouse"),
    ("(d)ice$", "$1ie"),
    ("(bus|ato)es$", "$1"),
    ("(cris|test)es$", "$1is"),
    ("^(pra|a)xes$", "$1xis"),
    ("([sz])es$", "$1"),
    ("(ace|ase)s$", "$1"),
    ("(ias)es$", "$1"),
    ("(z)zes$", "$1"),
    ("((ba|grou)se)s$", "$1"),
    ("(x)en", "$1"),
    ("(oa|ly|gno|op|the|ip)ses$", "$1sis"),
    ("(rt|ind|ap|cod)ices$", "$1ex"),
    ("(tr|end)ices$", "$1ix"),
    ("(oc|radi|vir|octop|alumn|cill|cact|fung|ul|ab)i$", "$1us"),
    ("(vir)ii$", "$1us"),
    ("(quiz)zes$", "$1"),
    ("(pe)ople$", "$1rson"),
    ("(m)en$", "$1an"),
    ("(child)ren$", "$1"),
    ("(t)eeth$", "$1ooth"),
    ("(g)eese$", "$1oose"),
    ("(iteri|en)a$", "$1on"),
    // Uncountable
    ("(bison|craft|deer|equipment|fish|fruit|grouse|money|news|offspring)$", "$1"),
    ("(info(rmation)?|rice|salmon|series|sheep|shrimp|species|swine|trout|tuna)$", "$1"),
    // It's very rare to actually want "datum" or "medium"
    ("(data|media)$", "$1"),
]

extension String {
    func singularized() -> String? {
        guard let (rule, replacement) = (rules.reversed().first { rule, _ in
            range(of: rule, options: [.regularExpression, .caseInsensitive], range: nil, locale: nil) != nil
        }) else {
            return nil
        }
        return replacingOccurrences(of: rule, with: replacement, options: [.regularExpression, .caseInsensitive])
            .removingPrefix("all")
    }

    func removingPrefix(_ prefix: String) -> String? {
        if hasPrefix(prefix.lowercased()) {
            let string = dropFirst(prefix.count)
            return string.first.map { "\($0.lowercased())\(string.dropFirst())" }
        }
        if hasPrefix(prefix.capitalized) {
            let string = dropFirst(prefix.count)
            return string.first.map { "\($0.uppercased())\(string.dropFirst())" }
        }
        return self
    }
}
