#!/bin/bash

set -e

if [[ -n "${TRAVIS}" ]]; then
    exit 0
fi

cd "$(dirname "$0")"

# Keep this pinned to a published release when developing new formatter changes.
FORMAT_VERSION=0.63.1
case "$(uname -s)-$(uname -m)" in
    Darwin-*) ASSET=swiftformat ;;
    Linux-x86_64) ASSET=swiftformat_linux ;;
    Linux-aarch64|Linux-arm64) ASSET=swiftformat_linux_aarch64 ;;
    *) echo "Unsupported platform for the prebuilt formatter" >&2; exit 1 ;;
esac

FORMAT_DIR="$PWD/.build/formatter/$FORMAT_VERSION/$ASSET"
if [[ ! -x "$FORMAT_DIR/$ASSET" ]]; then
    mkdir -p "$FORMAT_DIR"
    DOWNLOAD_DIR=$(mktemp -d "$FORMAT_DIR/download.XXXXXX")
    trap 'rm -rf "$DOWNLOAD_DIR"' EXIT
    curl --fail --location --retry 3 \
        "https://github.com/nicklockwood/SwiftFormat/releases/download/$FORMAT_VERSION/$ASSET.zip" \
        --output "$DOWNLOAD_DIR/swiftformat.zip"
    unzip -q "$DOWNLOAD_DIR/swiftformat.zip" -d "$DOWNLOAD_DIR"
    chmod +x "$DOWNLOAD_DIR/$ASSET"
    mv "$DOWNLOAD_DIR/$ASSET" "$FORMAT_DIR/$ASSET"
fi

"$FORMAT_DIR/$ASSET" . --cache ignore "$@"
