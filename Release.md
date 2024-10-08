Release Process
---------------

[] Update version number in SwiftFormat.swift + 3 targets
[] Update CHANGELOG.md
[] Update SwiftFormat.podspec.json
[] Select SwiftFormat (Command Line Tool) and run Editor > Archive
[] Replace binary in CommandLineTool directory
[] Select SwiftFormat for Xcode and run Editor > Archive
[] Notarize and export built app
[] Tag commit and push to main
[] Run Build for Linux & Build for Windows and download binaries
[] Unzip Linux binary and mark as executable with chmod +x, then rezip
[] Unzip Windows msi zips and rename
[] Create a release
[] Attach all binaries
[] Create and Publish Docker image
[] pod trunk push --allow-warnings
