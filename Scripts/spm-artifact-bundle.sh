#!/bin/sh

set -e

ARTIFACT_BUNDLE=swiftformat.artifactbundle
INFO_TEMPLATE=Scripts/spm-artifact-bundle-info.template
VERSION=$(./Scripts/get-version.sh)
MAC_BINARY_OUTPUT_DIR=$ARTIFACT_BUNDLE/swiftformat-$VERSION-macos/bin
LINUX_BINARY_OUTPUT_DIR=$ARTIFACT_BUNDLE/swiftformat-$VERSION-linux-gnu/bin

mkdir $ARTIFACT_BUNDLE

# Copy license into bundle
cp LICENSE.md $ARTIFACT_BUNDLE

# Create bundle info.json from template, replacing version
sed 's/__VERSION__/'"${VERSION}"'/g' $INFO_TEMPLATE > "${ARTIFACT_BUNDLE}/info.json"

# Copy macOS SwiftFormat binary into bundle
mkdir -p $MAC_BINARY_OUTPUT_DIR
cp CommandLineTool/swiftformat $MAC_BINARY_OUTPUT_DIR

# Copy Linux SwiftFormat binary into bundle
mkdir -p $LINUX_BINARY_OUTPUT_DIR
cp CommandLineTool/swiftformat_linux $LINUX_BINARY_OUTPUT_DIR

# Create ZIP
zip -yr - $ARTIFACT_BUNDLE > "${ARTIFACT_BUNDLE}.zip"

rm -rf $ARTIFACT_BUNDLE
