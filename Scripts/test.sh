#!/bin/bash

echo "Running all SwiftFormat tests"
echo "To test a single rule, use './Scripts/test_rule.sh'"

WORKSPACE_PATH="SwiftFormat.xcodeproj/project.xcworkspace"
XCODE_SCHEME="SwiftFormat (Framework)"

CMD="xcodebuild test -workspace \"${WORKSPACE_PATH}\" -scheme \"${XCODE_SCHEME}\""

eval $CMD
exit $?
