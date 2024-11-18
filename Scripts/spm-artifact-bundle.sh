#!/bin/sh

set -e

# By default, parses the current version from `Sources/SwiftFormat.swift`.
# Can be overridden by passing in custom version number as argument, e.g.
# `./Scripts/spm-artifact-bundle.sh VERSION_NUMBER`.
VERSION=${1:-$(./Scripts/get-version.sh)}
MAC_EXECUTABLE=${2:-CommandLineTool/swiftformat}
LINUX_EXECUTABLE=${3:-CommandLineTool/swiftformat_linux}
LINUX_AARCH64_EXECUTABLE=${4:-CommandLineTool/swiftformat_linux_aarch64}

ARTIFACT_BUNDLE=swiftformat.artifactbundle
INFO_TEMPLATE=Scripts/spm-artifact-bundle-info.template
MAC_BINARY_OUTPUT_DIR=$ARTIFACT_BUNDLE/swiftformat-$VERSION-macos/bin
LINUX_BINARY_OUTPUT_DIR=$ARTIFACT_BUNDLE/swiftformat-$VERSION-linux-gnu/bin
LINUX_AARCH64_BINARY_OUTPUT_DIR=$ARTIFACT_BUNDLE/swiftformat-$VERSION-linux-gnu/bin

rm -rf swiftformat.artifactbundle
rm -rf swiftformat.artifactbundle.zip

mkdir $ARTIFACT_BUNDLE

# Copy license into bundle
cp LICENSE.md $ARTIFACT_BUNDLE

# Create bundle info.json from template, replacing version
sed 's/__VERSION__/'"${VERSION}"'/g' $INFO_TEMPLATE > "${ARTIFACT_BUNDLE}/info.json"

# Copy macOS SwiftFormat binary into bundle
chmod +x $MAC_EXECUTABLE
mkdir -p $MAC_BINARY_OUTPUT_DIR
cp $MAC_EXECUTABLE $MAC_BINARY_OUTPUT_DIR

# Copy Linux SwiftFormat binary into bundle
chmod +x $LINUX_EXECUTABLE
mkdir -p $LINUX_BINARY_OUTPUT_DIR
cp $LINUX_EXECUTABLE $LINUX_BINARY_OUTPUT_DIR

# Copy Linux AArch64 SwiftFormat binary into bundle
chmod +x $LINUX_AARCH64_EXECUTABLE
mkdir -p $LINUX_AARCH64_BINARY_OUTPUT_DIR
cp $LINUX_AARCH64_EXECUTABLE $LINUX_AARCH64_BINARY_OUTPUT_DIR

# Create ZIP using 7z
7z a -tzip -mx=9 "${ARTIFACT_BUNDLE}.zip" "$ARTIFACT_BUNDLE"

rm -rf $ARTIFACT_BUNDLE
