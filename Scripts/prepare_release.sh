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

# 2. Update version in SwiftFormat.podspec.json
echo "Updating SwiftFormat.podspec.json..."
sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" SwiftFormat.podspec.json
sed -i '' "s/\"tag\": \"[^\"]*\"/\"tag\": \"$NEW_VERSION\"/" SwiftFormat.podspec.json

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

# 6. Archive and export executable for distribution
echo "Creating archive..."
ARCHIVE_PATH="build/SwiftFormat.xcarchive"
if ! xcodebuild -project SwiftFormat.xcodeproj -scheme "SwiftFormat (Command Line Tool)" -configuration Release -archivePath "$ARCHIVE_PATH" archive; then
    echo "Error: Archive failed. Please fix the issues before proceeding."
    exit 1
fi

echo "Extracting executable from archive..."
# Find the executable directly in the archive
ARCHIVE_EXECUTABLE=$(find "$ARCHIVE_PATH" -name "swiftformat" -type f -perm +111 | head -1)

if [ -z "$ARCHIVE_EXECUTABLE" ]; then
    echo "Error: Could not find executable in archive"
    exit 1
fi

echo "Replacing Command Line Tool executable with archived version..."
cp "$ARCHIVE_EXECUTABLE" CommandLineTool/swiftformat

echo ""
echo "✅ Release preparation completed successfully for version $NEW_VERSION!"
echo ""
echo "Remaining steps to be completed manually:"
echo "   - Fill out CHANGELOG.md"
echo "   - Commit to develop and main branches"
echo "   - Create release at https://github.com/nicklockwood/SwiftFormat/releases"
echo "   - Update Cocoapod with 'pod trunk push --allow-warnings'"
echo ""
