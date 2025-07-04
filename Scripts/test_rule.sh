#!/bin/bash

# Script for testing individual SwiftFormat rules.
# $ ./Script/test_rule.sh blankLinesAtStartOfScope

# Argument validation
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <RuleName>" >&2
    exit 1
fi

rule_name="$1"

# Capitalize the first letter
first_char_upper=$(echo ${rule_name:0:1} | tr '[:lower:]' '[:upper:]')
rest_of_name="${rule_name:1}"
class_name_stem="${first_char_upper}${rest_of_name}"

# Append "Tests"
TEST_CLASS_NAME="${class_name_stem}Tests"

# Validate test file existence
TEST_FILE_PATH="Tests/Rules/${TEST_CLASS_NAME}.swift"
if [ ! -f "$TEST_FILE_PATH" ]; then
    echo "Error: Test file ${TEST_FILE_PATH} not found." >&2
    exit 2
fi

echo "Testing ${rule_name} rule..."

# Run tests for the specific rule using swift test
SWIFT_TEST_TARGET="SwiftFormatTests"
swift test --filter "${SWIFT_TEST_TARGET}.${TEST_CLASS_NAME}" 2>&1
