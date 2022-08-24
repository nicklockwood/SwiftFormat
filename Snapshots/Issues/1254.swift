// swiftformat:disable blankLinesBetweenScopes
// swiftformat:disable wrapMultilineStatementBraces
// swiftformat:options --commas false
// swiftformat:options --xcodeindentation enabled
// swiftformat:options --extensionacl on-declarations
// swiftformat:options --modifierorder public,override
// swiftformat:options --patternlet inline
// swiftformat:options --trimwhitespace nonblank-lines

func testing() {
    firstly {
        doSomething()
    }
    // then do something else
    .then {
        doSomethingElse()
    }
    // convert the thing
    .map {
        transform($0)
    }
}
