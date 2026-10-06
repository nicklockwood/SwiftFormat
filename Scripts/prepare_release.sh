#!/bin/bash

set -e

# Check if version argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 0.58.0"
    exit 1
fi

NEW_VERSION="$1"
CURRENT_DATE=$(date +"%Y-%m-%d")

echo "Preparing release for version $NEW_VERSION..."

# Validate version format (basic check for semantic versioning)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 0.58.0)"
    exit 1
fi

# 1. Update CHANGELOG.md
echo "Updating CHANGELOG.md..."
# Create a temporary file for the new changelog content
TEMP_CHANGELOG=$(mktemp)

# Add new version entry at the top after the header
{
    echo "# Change Log"
    echo ""
    echo "## [$NEW_VERSION](https://github.com/nicklockwood/SwiftFormat/releases/tag/$NEW_VERSION) ($CURRENT_DATE)"
    echo ""
    echo "- TODO"
    echo ""
    # Skip the first two lines (header) and add the rest
    tail -n +3 CHANGELOG.md
} > "$TEMP_CHANGELOG"

# Replace the original file
if ! grep -q "tag/$NEW_VERSION)" CHANGELOG.md; then
    mv "$TEMP_CHANGELOG" CHANGELOG.md
fi

# 2. Update version in README.md
echo "Updating README.md..."
sed -i '' "s/\" ~> [^ \n]*/\" ~> $NEW_VERSION/" README.md
sed -i '' "s/from: \"[^\"]*\"/from: \"$NEW_VERSION\"/" README.md

# 3. Update version in Sources/SwiftFormat.swift
echo "Updating Sources/SwiftFormat.swift..."
sed -i '' "s/let swiftFormatVersion = \"[^\"]*\"/let swiftFormatVersion = \"$NEW_VERSION\"/" Sources/SwiftFormat.swift

# 4. Update version in SwiftFormat.xcodeproj
echo "Updating SwiftFormat.xcodeproj..."
sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $NEW_VERSION/" SwiftFormat.xcodeproj/project.pbxproj

# 5. Run tests
echo "Running tests..."
if ! swift test -c release --parallel --num-workers 10; then
    echo "Error: Tests failed. Please fix the issues before proceeding."
    exit 1
fi

echo "Tests passed successfully."

# 6. Pin formatting to the most recent release before the one being prepared.
# Skip NEW_VERSION so rerunning release preparation keeps the same pin.
FORMAT_VERSION=$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' CHANGELOG.md |
    awk -v new_version="$NEW_VERSION" '$0 != new_version { print; exit }')
if [ -z "$FORMAT_VERSION" ]; then
    echo "Error: No previous release found in CHANGELOG.md for the formatter pin." >&2
    exit 1
fi
echo "Pinning formatter to $FORMAT_VERSION..."
sed -i '' "s/^FORMAT_VERSION=.*/FORMAT_VERSION=$FORMAT_VERSION/" format.sh

echo "Formatting..."
bash format.sh

# 7. Build again after formatting to ensure no issues were introduced
echo "Building after formatting..."
if ! swift build -c release; then
    echo "Error: Build failed after formatting. Please fix the issues before proceeding."
    exit 1
fi

echo ""
echo "✅ Release preparation completed successfully for version $NEW_VERSION!"
echo ""
echo "Remaining steps to be completed manually:"
echo "   - Fill out CHANGELOG.md"
echo "   - Commit to develop and main branches"
echo "   - Create release at https://github.com/nicklockwood/SwiftFormat/releases"
echo ""
