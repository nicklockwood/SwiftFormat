[![Travis](https://img.shields.io/travis/nicklockwood/SwiftFormat.svg?maxAge=2592000)](https://travis-ci.org/nicklockwood/SwiftFormat)
[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg?maxAge=2592000)](http://twitter.com/nicklockwood)

What is this?
----------------

SwiftFormat is a code library and command line tool for reformatting swift code.

It applies a set of rules to the formatting and space around the code, leaving the meaning intact.


Why would I want to do that?
-----------------------------

Many programmers have a preferred style for formatting their code, and others seem entirely blind to the existing formatting conventions of a project (to the enragement of their colleagues).

When collaborating on a project, it can be helpful to agree on a common coding style, but enforcing that manually is tedious and error-prone, and can lead to bad feeling if some participants take it more seriously than others.

Having a tool to automatically enforce a common style eliminates those issues, and lets you focus on the *operation* of the code, not its presentation.


How do I install it?
---------------------

That depends. There are four ways you can use SwiftFormat:

1. As a command-line tool that you run manually, or as part of some other toolchain
2. As a Source Editor Extension that you can invoke via the Editor > SwiftFormat menu within Xcode
3. As a build phase in your Xcode project, so that it runs every time you press Cmd-R or Cmd-B, or
4. As a Git pre-commit hook, so that it runs on any files you've changed before you check them in


Command-line tool
-------------------

**Installation:**

The simplest way to install the `swiftformat` command-line tool is via [Homebrew](http://brew.sh/). If you already have Homebrew installed, just type

    > brew update
    > brew install swiftformat
    
Then you're done. Alternatively, to build it yourself from source:

1. open `SwiftFormat.xcodeproj` and build the `SwiftFormat (Application)` scheme.

2. Drag the `swiftformat` binary into `/usr/local/bin/` (this is a hidden folder, but you can use the Finder's `Go > Go to Folder...` menu to open it).

3. Open `~/.bash_profile` in your favorite text editor (this is a hidden file, but you can type `open ~/.bash_profile` in the terminal to open it).

4. Add the following line to the file: `alias swiftformat="/usr/local/bin/swiftformat --indent 4"` (you can omit the `--indent 4`, or replace it with something else. Run `swiftformat --help` to see the available options).

5. Save the `.bash_profile` file and run the command `source ~/.bash_profile` for the changes to take effect.

**Usage:**

If you followed the installation instructions above, you can now just type

    swiftformat .
    
(that's a space and then a period after the command) in the terminal to format any Swift files in the current directory.

**WARNING:** `swiftformat .` will overwrite any Swift files it finds in the current directory, and any subfolders therein. If you run it from your home directory, it will probably reformat every Swift file on your hard drive.

To use it safely, do the following:

1. Choose a file or directory that you want to apply the changes to.

2. Make sure that you have committed all your changes to that code safely in git (or whatever source control system you use. If you don't use source control, rethink your life choices).

3. (Optional) In Terminal, type `swiftformat --inferoptions "/path/to/your/code/"`. This will suggest a set of formatting options to use that match your existing project style (but you are free to ignore these and use the defaults, or your own settings if you prefer).

    The path can point to either a single Swift file, or a directory of files. It can be either be absolute, or relative to the current directory. The `""` quotes around the path are optional, but if the path contains spaces then you either need to use quotes, or escape each space with `\`. 

4. In Terminal, type `swiftformat "/path/to/your/code/"`. The same rules apply as above with respect to path formatting, but you can enter multiple paths if you wish, separated by spaces.

    If you used `--inferoptions` to generate a suggested set of options in step 3, you should copy and paste them into the command, either before or after the path(s) to your source files.

5. Press enter to begin formatting. Once the formatting is complete, use your source control system to check the changes, and verify that no undesirable changes have been introduced. If they have, revert the changes, tweak the options and try again.

6. (Optional) commit the changes.

Following these instructions *should* ensure that you avoid catastrophic data loss, but in the unlikely event that it wipes your hard drive, **please note that I accept no responsibility**.

If you prefer, you can also use unix pipes to include swiftformat as part of a command chain. For example, this is an alternative way to format a file:

    cat /path/to/file.swift | swiftformat --output /path/to/file.swift
    
Omitting the `--output /path/to/file.swift` will print the formatted file to `stdout`.


Xcode Source Editor Extension
-----------------------------

**Installation:**

You'll find the latest version of the `SwiftFormat for Xcode` application inside the `EditorExtension` folder included in the SwiftFormat repository. Drag it into your `Applications` folder, then double-click to launch it, and follow the on-screen instructions.

**NOTE:** The Extension requires Xcode 8 and macOS 10.12 Sierra. It *may* work on macOS 10.11 El Capitan if you open Terminal, execute the following command, then restart your Mac (but it didn't work for me).

    > sudo /usr/libexec/xpccachectl
    
**Usage:**

In Xcode, you'll find a SwiftFormat option under the Editor menu. You can use this to format either the current selection or the whole file. 


Xcode build phase
-------------------

To set up SwiftFormat as an Xcode build phase, do the following:

1. Add the `swiftformat` binary to your project directory (this is better than referencing a locally installed copy because it means that project will still compile on machines that don't have the `swiftformat` command-line tool installed).

2. In the Build Phases section of your project target, add a new Run Script phase before the Compile Sources step. The script should be `"${SRCROOT}/path/to/swiftformat" "${SRCROOT}/path/to/your/swift/code/"` (both paths should be relative to the directory containing your Xcode project).

**NOTE:** This will slightly increase your build time, but shouldn't impact it too much, as SwiftFormat is quite fast compared to compilation. If you find that it has a noticeable impact, file a bug report and I'll try to diagnose why.


Git pre-commit hook
---------------------

1. Follow the instructions for installing the swiftformat command-line tool.

2. Edit or create a `.git/hooks/pre-commit` file in your project folder. The .git folder is hidden but should already exist if you are using Git with your project, so open in with the terminal, or the Finder's `Go > Go to Folder...` menu.

3. Add the following line in the pre-commit file (unlike the Xcode build phase approach, this uses your locally installed version of swiftformat, not a separate copy in your project repository)

        #!/bin/bash
        git status --porcelain | grep -e '^[AM]\(.*\).swift$' | cut -c 3- | while read line; do
          swiftformat ${line};
          git add $line;
        done

4. enable the hook by typing `chmod +x .git/hooks/pre-commit` in the terminal
 
The pre-commit hook will now run whenever you run `git commit`. Running `git commit --no-verify` will skip the pre-commit hook.

**NOTE:** If you are using Git via a GUI client such as [Tower](https://www.git-tower.com), [additional steps](https://www.git-tower.com/help/mac/faq-and-tips/faq#faq-11) may be needed.

**NOTE (2):** Unlike the Xcode build phase approach, git pre-commit hook won't be checked in to source control, and there's no way to guarantee that all users of the project are using the same version of swiftformat. For a collaborative project, you might want to consider a *post*-commit hook instead, which would run on your continuous integration server.


So what does SwiftFormat actually do?
--------------------------------------

SwiftFormat first converts the source file into tokens, then iteratively applies a set of rules to the tokens to adjust the formatting. The tokens are then converted back into text.

The rules used by SwiftFormat can be displayed using the `--rules` command line argument. You can disable them individually using `--disable` followed by a comma-delimited list of rule names.

Here are all the rules that SwiftFormat currently applies, and what they do:

*spaceAroundParens* - contextually adjusts the space around ( ). For example:

    init (foo)    -->   init(foo)

    switch(x){    -->   switch (x) {
   
*spaceInsideParens* - removes the space inside ( ). For example:

    ( a, b )    -->    (a, b)

*spaceAroundBrackets* - contextually adjusts the space around [ ]. For example:

    foo as[String]   -->   foo as [String]
    
    foo = bar [5]    -->   foo = bar[5]

*spaceInsideBrackets* - removes the space inside [ ]. For example:

    [ 1, 2, 3 ]    -->    [1, 2, 3]

*spaceAroundBraces* - contextually adds space around { }. For example:

    foo.filter{ return true }.map{ $0 }   -->   foo.filter { return true }.map { $0 }
    
    foo({})                                 -->   foo({})

*spaceInsideBraces* - adds space inside { }. For example:

    foo.filter {return true}    -->    foo.filter { return true }

*spaceAroundGenerics* - removes the space around < >. For example:

    Foo <Bar> ()    -->    Foo<Bar>()

*spaceInsideGenerics* - removes the space inside < >. For example:

    Foo< Bar, Baz >    -->    Foo<Bar, Baz>

*spaceAroundOperators* - contextually adjusts the space around infix operators:

    foo . bar()   -->    foo.bar()
    
    a+b+c         -->    a + b + c

*spaceAroundComments* - adds space around /* ... */ comments and before // comments:

    let a = 5// assignment     -->   let a = 5 // assignment
    
    func foo() {/* no-op */}   -->   func foo() { /* no-op */ }

*spaceInsideComments* - adds space inside /* ... */ comments and at the start of // comments:

    let a = 5 //assignment     -->   let a = 5 // assignment
    
    func foo() { /*no-op*/ }   -->   func foo() { /* no-op */ }

*consecutiveSpaces* - reduces a sequence of spaces to a single space:

    let  foo =  5    -->    let foo = 5

*trailingWhitespace* - removes the whitespace at the end of a line

*consecutiveBlankLines* - reduces multiple sequential blank lines to a single blank line

*blankLinesAtEndOfScope* - removes trailing bank lines from inside braces, brackets, parens or chevrons:

    func foo() {          func foo() {
        //foo       -->       //foo
                          }
    }
    
    array = [             array = [
        foo,                  foo,
        bar,        -->       bar,
        baz,                  baz,
                          ]
    ]
    
    if x {                if x {         
        print("x")               print("x")

    } else if y {   -->   } else if y {
        print("y")            print("y")
                          }
    }

*blankLinesBetweenScopes* - adds a blank line before each class, struct, enum, extension, protocol or function:

    func foo() {         func foo() {
        //foo                //foo
    }                    }
    func bar() {         
        //bar      -->   func bar() {
    }                        //bar
    var baz: Bool        }
    var quux: Int
                         var baz: Bool
                         var quux: Int
                         
*linebreakAtEndOfFile* - ensures that the last line of the file is empty

*indent* - adjusts leading whitespace based on scope and line wrapping:

    if x {               if x {
     //foo                   //foo
    } else {       -->   } else {
        //bar                //bar
       }                 }
       
    let array = [        let array = [
           foo,              foo,
          bar,     -->       bar,
         baz                 baz
       ]                 ]

*braces* - implements K&R (default) or Allman-style indentation, depending on format options:

    if x                 if x {
    {                        //foo
        //foo            } 
    }               -->   else {
    else                     //bar
    {                    }
        //bar
    }

*elseOnSameLine* - controls whether an `else`, `catch` or `while` after a `}` appears on the same line:

    if x {               if x {
        //foo                //foo
    }              -->   } else {
    else {                   //bar
        //bar            }
    }

    do {                 do {
        try foo              try foo
    }              -->   } catch {
    catch {                  //bar
        //bar            }
    }
    
    repeat {             repeat {
        //foo                //foo
    }              -->   } while x {
    while x {                //bar
        //bar            }
    }

*trailingCommas* - adds a trailing comma to the last line in a multiline array or dictionary literal:

    let array = [        let array = [
        foo,                 foo,
        bar,       -->       bar,
        baz                  baz,
    ]                    ]
    
*void* - standardizes the use of `Void` vs an empty tuple `()` to represent empty argument lists and return values:

    let foo: () -> ()         -->    let foo: () -> Void
    
    let bar: Void -> Void     -->    let bar: () -> Void
    
    let baz: (Void) -> Void   -->    let baz: () -> Void
    
    func quux() -> (Void)     -->    func quux() -> Void

*todos* - ensures that `TODO:`, `MARK:` and `FIXME:` comments include the trailing colon (else they're ignored by Xcode)

    /* TODO fix this properly */    -->   /* TODO: fix this properly */
    
    // MARK - UIScrollViewDelegate  -->   // MARK: - UIScrollViewDelegate

*semicolons* - removes semicolons at the end of lines and (optionally) replaces inline semicolons with a linebreak:

    let foo = 5;              -->  let foo = 5
    
    let foo = 5; let bar = 6  -->  let foo = 5
                                   let bar = 6
                                   
    return;                   -->  return;
    goto(fail)                     goto(fail)

*linebreaks* - normalizes all linebreaks to use the same character, as specified in options (either CR, LF or CRLF).

*specifiers* - normalizes the order for access specifiers, and other property/function/class/etc. specifiers:

    lazy public weak private(set) var foo: UIView?    -->    private(set) public lazy weak var foo: UIView?
    
    public override final func foo()                  -->    final override public func foo() 
    
    convenience private init()                        -->    private convenience init() 

*redundantParens* - removes unnecessary parens from around `if`, `while` or `switch` conditions:

    if (foo == true) {}         -->    if foo == true {}
    
    while (i < bar.count) {}    -->    while i < bar.count {}
    
*redundantGet* - removes unnecessary `get { }`clause from inside read-only computed properties:

    var foo: Int {               var foo: Int {
        get {                        return 5
            return 5     -->     }
        }
    }
    
*redundantNilInit* - removes unnecessary nil initialization of Optional vars (which are nil by default anyway):

	var foo: Int? = nil     -->   var foo: Int?
	
	let foo: Int? = nil     -->   let foo: Int? = nil // doesn't apply to `let` properties
	
	var foo: Int? = 0       -->   var foo: Int? = 0 // doesn't affect non-nil initialzation

*redundantLet* - removes redundant `let` or `var` from ignored variables in bindings (which is a warning in Xcode):

    if case (let foo, let _) = bar {}           -->   if case (let foo, _) = bar {}

    if case .foo(var /* unused */ _) = bar {}   -->   if case .foo(/* unused */ _) = bar {} 

*redundantPattern* - removes redundant pattern matching arguments for ignored variables:

    if case .foo(_, _) = bar {}    -->    if case .foo = bar {}
    
    let (_, _) = bar               -->    let _ = bar

*hexLiterals* - converts all hex literals to upper- or lower-case, depending on settings:

    let color = 0xFF77A5    -->   let color = 0xff77a5
    
*stripHeaders* - removes the comment header blocks that Xcode adds to the top of each file (off by default).

*wrapArguments* - wraps function arguments and array elements depending on the mode specified. E.g. for `beforeFirst`:

    func foo(bar: Int,                func foo(
             baz: String) {               bar: Int,
        ...                    -->        baz: String
    }                                 ) {
                                           ...
                                      }

	let foo = [bar,	                   let foo = [
	           baz,            -->         bar,
	           quux]       		           baz,
                            	           quux
                          	           ]

FAQ
-----

There haven't been many questions yet, but here's what I'd like to think people are wondering:


*Q. What versions of Swift are supported?*

> A. The framework requires Swift 3, but it can format programs written in Swift 2.x or 3.x. 


*Q. I don't like how SwiftFormat formatted my code*

> A. That's not a question (but see below).


*Q. How can I modify the formatting rules?*

> A. Many configuration options are exposed in the command line interface. You can either set these manually, or use the `--inferoptions` argument to automatically generate the configuration from your existing project.

> If there is a rule that you don't like, and which cannot be disabled via the command line options, you can disable the rule by using the `--disable` argument, followed by the name of the rule. You can display a list of all rules using the `--rules` argument, and their behaviors are documented above this section in the README.

> If the options you want aren't exposed, and disabling the rule doesn't solve the problem, the rules are implemented as functions in the file `Rules.swift`, so you can modify them and build a new version of the command line tool. If you think your changes might be generally useful, make a pull request.


*Q. Why did you write yet another Swift formatting tool?*

> A. Surprisingly, there really aren't that many other options out there, and none of them currently support all the rules I wanted. The only other comparable ones I'm aware of are Realm's [SwiftLint](https://github.com/realm/SwiftLint) and Jintin's [Swimat](https://github.com/Jintin/Swimat) - you might want to try those if SwiftFormat doesn't meet your requirements.


*Q. Does it use SourceKit?*

> A. No.


*Q. Why would you write a parser from scratch instead of just using SourceKit?*

> A. The fact that there aren't already dozens of full-featured Swift formatters using SourceKit would suggest that the "just" isn't warranted.


*Q. You wrote a Swift parser from scratch!? Are you a wizard?*

> A. Yes. Yes I am.


*Q. How does it work?*

> A. First it loops through the source file character-by-character and breaks it into tokens, such as `number`, `identifier`, `linebreak`, etc. That's handled by the functions in `Tokenizer.swift`.

> Next, it applies a series of formatting rules to the token array, such as "remove whitespace at the end of a line", or "ensure each opening brace appears on the same line as the preceding non-whitespace token". Each rule is designed to be relatively independent of the others, so they can be enabled or disabled individually. The rules are all defined as methods of the `FormatRules` class in `Rules.swift`. The list of rules is then extracted using some runtime magic.

> Finally, the modified token array is stitched back together to re-generate the source file.


*Q. Why aren't you using regular expressions?*

> A. See https://xkcd.com/1171/ for details.


*Q. Can I use the `SwiftFormat.framework` inside another app?*

> A. I only created the framework to facilitate testing, so to be honest I've no idea if it will work in an app, but you're welcome to try. If you need to make adjustments to the public/private flags or namespaces to get it working, open an issue on Github (or even better, a pull request).

> The SwiftFormat framework is available as a CocoaPod for easier integration.


Cache
------

SwiftFormat uses a cache file to avoid reformatting files that haven't changed. For a large project, this can significantly reduce processing time.

By default, the cache is stored in `~/Library/Caches/com.charcoaldesign.swiftformat`. Use the command line option `--cache ignore` to ignore the cached version and re-apply formatting to all files. Alternatively, you can use `--cache clear` to delete the cache (or you can just manually delete the cache file).

The cache is shared between all projects. The file is fairly small, as it only stores the path and size for each file, not the contents. If you do start experiencing slowdown due to the cache growing too large, you might want to consider using a separate cache file for each project.

You can specify a custom cache file location by passing a path as the `--cache` option value. For example, you might want to store the cache file inside your project directory. It is fine to check in the cache file if you want to share it between different users of your project, as the paths stored in the cache are relative to the location of the formatted files.


Known issues
---------------

* The formatted file cache is based on file length, so it's possible (though unlikely) that an edited file will have the exact same character count as the previously formatted version, causing SwiftFormat to incorrectly identify it as not having changed, and fail to format it.

    To fix this, you can type an extra space in the file (which SwiftFormat will then remove again when it applies the formatting).
    
    Alternatively, use the command line option `--cache ignore` to force SwiftFormat to ignore the cache for this run.

* If a file begins with a comment, the `stripHeaders` rule will remove it if is followed by a blank line. To avoid this, make sure that the first comment is directly followed by a line of code.

* SwiftFormat currently reformats multiline comment blocks without regard for the original indenting. That means

        /* some documentation
        
              func codeExample() {
                  print("Hello World")
              }
     
         */
         
    Will become
    
        /* some documentation
        
         func codeExample() {
         print("Hello World")
         }
         
         */
         
    To work around that, you can disable automatic indenting of comments using the `comments` command line flag.
    
    Alternatively, if you prefer to leave the comment indenting feature enabled, you can rewrite your multiline comment as a block of single-line comments...
    
        // some documentation
        //
        //    func codeExample() {
        //        print("Hello World")
        //    }
        //
        //
        
    Or begin each line with a `*` (or any other non-whitespace character)
    
        /* some documentation
         *
         *    func codeExample() {
         *        print("Hello World")
         *    }
         *  
         */


Credits
------------

* @tonyarnold - Xcode Source Editor Extension
* @bourvill - Git pre-commit hook script
* @palleas - Homebrew formula
* @nicklockwood - Everything else

([Full list of contributors](https://github.com/nicklockwood/SwiftFormat/graphs/contributors))
