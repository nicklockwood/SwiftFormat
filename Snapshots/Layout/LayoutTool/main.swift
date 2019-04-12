//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

/// The current LayoutTool version
let version = "0.6.36"

extension String {
    var inDefault: String { return "\u{001B}[39m\(self)" }
    var inRed: String { return "\u{001B}[31m\(self)\u{001B}[0m" }
    var inGreen: String { return "\u{001B}[32m\(self)\u{001B}[0m" }
    var inYellow: String { return "\u{001B}[33m\(self)\u{001B}[0m" }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            write(data)
        }
    }
}

private var stderr = FileHandle.standardError

func printHelp() {
    print("")
    print("LayoutTool, version \(version)")
    print("copyright (c) 2017 Schibsted")
    print("")
    print("help")
    print(" - prints this help page")
    print("")
    print("version")
    print(" - prints the currently installed LayoutTool version")
    print("")
    print("format <files>")
    print(" - formats all xml files found at the specified path(s)")
    print("")
    print("list <files>")
    print(" - lists all Layout xml files found at the specified path(s)")
    print("")
    print("rename <files> <old> <new>")
    print(" - renames all classes or symbols named <old> to <new> in <files>")
    print("")
    print("strings <files>")
    print(" - lists all Localizable.strings keys used in <files>")
    print("")
}

enum ExitResult: Int32 {
    case success = 0
    case failure = 1
}

func timeEvent(block: () throws -> Void) rethrows -> String {
    let start = CFAbsoluteTimeGetCurrent()
    try block()
    let time = round((CFAbsoluteTimeGetCurrent() - start) * 100) / 100 // round to nearest 10ms
    return String(format: "%gs", time)
}

func processArguments(_ args: [String]) -> ExitResult {
    var errors = [FormatError]()
    guard args.count > 1 else {
        print("error: missing command argument", to: &stderr)
        print("LayoutTool requires a command argument".inRed, to: &stderr)
        return .failure
    }
    switch args[1] {
    case "help":
        printHelp()
    case "version":
        print(version)
    case "format":
        let paths = Array(args.dropFirst(2))
        if paths.isEmpty {
            errors.append(.options("format command expects one or more file paths as input"))
            break
        }
        var filesChecked = 0, filesUpdated = 0
        let time = timeEvent {
            (filesChecked, filesUpdated, errors) = format(paths)
        }
        if errors.isEmpty {
            print("LayoutTool format completed. \(filesUpdated)/\(filesChecked) files updated in \(time)".inGreen)
        }
    case "list":
        let paths = Array(args.dropFirst(2))
        if paths.isEmpty {
            errors.append(.options("list command expects one or more file paths to search"))
            break
        }
        errors += list(paths)
    case "rename":
        var paths = Array(args.dropFirst(2))
        guard let new = paths.popLast(), let old = paths.popLast(), !new.contains("/"), !old.contains("/") else {
            errors.append(.options("rename command expects a name and replacement"))
            break
        }
        if paths.isEmpty {
            errors.append(.options("rename command expects one or more file paths to search"))
            break
        }
        errors += rename(old, to: new, in: paths)
    case "strings":
        let paths = Array(args.dropFirst(2))
        if paths.isEmpty {
            errors.append(.options("list command expects one or more file paths to search"))
            break
        }
        errors += listStrings(in: paths)
    case let arg:
        print("error: unknown command \(arg)", to: &stderr)
        print("LayoutTool \(arg) is not a valid command".inRed, to: &stderr)
        return .failure
    }
    for error in errors {
        print("error: \(error)", to: &stderr)
    }
    if errors.isEmpty {
        return .success
    } else {
        print("LayoutTool \(args[1]) failed".inRed, to: &stderr)
        return .failure
    }
}

// Pass in arguments and exit
let result = processArguments(CommandLine.arguments)
exit(result.rawValue)
