#!/bin/sh

rules=()

# Find and validate all of the rules defined in the Sources/Rules directory.
for filePathToRule in ${SRCROOT}/Sources/Rules/*.swift; do
    # The file name of the rule is required to match the name of the rule itself.
    ruleFileName=$(basename -- "$filePathToRule")
    ruleName="${ruleFileName%.*}"

    # Verify the rule file only contains a single `FormatRule` with the correct name.
    grep -n 'FormatRule(' ${filePathToRule} | while read -r formatRuleDefinition ; do
        lineNumber=$(echo $formatRuleDefinition | cut -d : -f 1)

        if [[ ! $formatRuleDefinition =~ "let $ruleName =" ]]; then
            echo "let $ruleName ="
            echo "${filePathToRule}:${lineNumber}: error: ${ruleFileName} must contain a single FormatRule named ${ruleName}"
            exit 1
        fi
    done

    rules+=($ruleName)
done

# Ensure the rules are sorted alphabetically so the generated code is deterministic.
rules=($(printf '%s\n' "${rules[@]}"|sort))

# Generate RuleRegistry.swift
fileContents="//
//  RuleRegistry.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/27/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

/// All of the rules defined in the Rules directory.
/// **Generated automatically when building. Do not modify.**
let ruleRegistry: [String: FormatRule] = ["

for ruleName in ${rules[*]}; do
fileContents+="
    \"${ruleName}\": .${ruleName},"
done

fileContents+="
]"

echo "$fileContents" > "${SRCROOT}/Sources/RuleRegistry.swift"