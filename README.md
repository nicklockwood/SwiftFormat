[![Travis](https://img.shields.io/travis/nicklockwood/SwiftFormat.svg?maxAge=2592000)](https://travis-ci.org/nicklockwood/SwiftFormat)
[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg?maxAge=2592000)](http://twitter.com/nicklockwood)

What is this?
----------------

SwiftFormat is a code library and command line tool for reformatting swift code.

It applies a set of rules to the whitespace around the code, leaving the meaning intact.


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

1. The latest binary version of the `swiftformat` command-line tool is included in the `CommandLineTool` folder. You can either use that, or build it yourself from source. To build it yourself, open `SwiftFormat.xcodeproj` and build the `SwiftFormat (Application)` scheme.

2. Drag the `swiftformat` binary into `/usr/local/bin/` (this is a hidden folder, but you can use the Finder's `Go > Go to Folder...` menu to open it).

3. Open `~/.bash_profile` in your favorite text editor (this is a hidden file, but you can type `open ~/.bash_profile` in the terminal to open it).

4. Add the following line to the file: `alias swiftformat="/usr/local/bin/swiftformat --indent 4"` (you can omit the `--indent 4`, or replace it with something else. Run `swiftformat --help` to see the available options).

5. Save the `.bash_profile` file and run the command `source ~/.bash_profile` for the changes to take effect.

**Usage:**

If you followed the installation instructions above, you can now just type `swiftformat .` (that's a space and then a period after the command) in the terminal to format any swift files in the current directory.

**WARNING:** `swiftformat .` will overwrite any swift files it finds in the current directory, and any subfolders therein. If you run it from your home directory, it will probably reformat every swift file on your hard drive.

To use it safely, do the following:

1. Choose a file or directory that you want to apply the changes to.

2. Make sure that you have committed all your changes to that code safely in git (or whatever source control system you use. If you don't use source control, rethink your life choices).

3. In Terminal, type `swiftformat "/path/to/your/code/"` (the path can either be absolute, or relative to the current directory. The `""` quotes around the path are optional, but if the path contains spaces then you either need to use quotes, or escape each space with `\`).

4. Use your source control system to check the changes, and verify that no undesirable changes have been introduced (if they have, file a bug).

5. (Optional) commit the changes.

This *should* ensure that you avoid catastrophic data loss, but in the unlikely event that it wipes your hard drive, **please note that I accept no responsibility**.

If you prefer, you can also use unix pipes to include swiftformat as part of a command chain. For example, this is an alternative way to format a file:

    cat /path/to/file.swift | swiftformat --output /path/to/file.swift
    
Omitting the `--output /path/to/file.swift` will print the formatted file to `stdout`.


Xcode Source Editor Extension
-----------------------------

**Installation:**

You'll find the latest version of the `SwiftFormat for Xcode` application inside the `EditorExtension` folder included in the SwiftFormat repository. Drag it into your `Applications` folder, then double-click to launch it, and follow the on-screen instructions.

**NOTE:** The Extension requires Xcode 8 and macOS 10.12 Sierra. It *may* work on macOS 10.11 El Capitan if you open Terminal, execute the following command, then restart your Mac.

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

Here are all the rules that SwiftFormat currently applies:

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
	
	foo({})   							  -->   foo({})

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
    
    if x {          	  if x { 		
        print("x") 		      print("x")

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

*knrBraces* - implements K&R style braces, where the opening brace is on the same line as related code:

    if x                 if x {
    {                        //foo
        //foo            } 
    }    	       -->   else {
    else                     //bar
    {                    }
    	//bar
    }

*elseOnSameLine* - ensures the else following an if statement appears on the same line as the closing }

    if x {               if x {
        //foo                //foo
    }              -->   } else {
    else {                   //bar
        //bar            }
    }

*trailingCommas* - adds a trailing , to the last line in a multiline array or dictionary literal:

    let array = [        let array = [
        foo,                 foo,
        bar,       -->       bar,
        baz                  baz,
    ]                    ]

*todos* - ensures that `TODO:`, `MARK:` and `FIXME:` comments include the trailing colon (else they're ignored by Xcode)

    /* TODO fix this properly */    -->   /* TODO: fix this properly */
    
    // MARK - UIScrollViewDelegate  -->   // MARK: - UIScrollViewDelegate

*semicolons* - removes semicolons at the end of lines and (optionally) replaces inline semicolons with a linebreak:

    let foo = 5;              -->  let foo = 5
    
    let foo = 5; let bar = 6  -->  let foo = 5
                                   let bar = 6
                                   
    return; 	              -->  return;
    goto(fail)                     goto(fail)

*linebreaks* - normalizes all linebreaks to use the same character, as specified in options (either CR, LF or CRLF).

*specifiers* - normalizes the order for access specifiers, and other property/function/class/etc. specifiers:

    lazy public weak private(set) var foo: UIView?    -->    private(set) public lazy weak var foo: UIView?
    
    public override final func foo()                  -->    final override public func foo() 
    
    convenience private init()                        -->    private convenience init() 
    

FAQ
-----

There haven't been many questions yet, but here's what I'd like to think people are wondering:


*Q. What versions of Swift are supported?*

> A. The framework requires Swift 3, but it can format programs written in Swift 2.x or 3.x. 


*Q. I don't like how SwiftFormat formatted my code*

> A. That's not a question (but see below).


*Q. How can I modify the formatting rules?*

> A. Most of the rules are hard-coded right now, with a handful of options exposed in the `FormatOptions` struct. If you look in `Rules.swift` you will find a list of all the rules that are applied by default. You can disable any rules you don't want and build a new version of the command line tool.

> With a bit more effort, you can also edit the existing rules or create new ones. If you think your changes might be generally useful, make a pull request.


*Q. Why did you write yet another Swift formatting tool?*

> A. Surprisingly, there really aren't that many other options out there, and none of them currently support all the rules I wanted. The only other comparable ones I'm aware of are Realm's [SwiftLint](https://github.com/realm/SwiftLint) and Jintin's [Swimat](https://github.com/Jintin/Swimat) - you might want to try those if SwiftFormat doesn't meet your requirements.


*Q. Does it use SourceKit?*

> A. No.


*Q. Why would you write a parser from scratch instead of just using SourceKit?*

> A. The fact that there aren't already dozens of full-featured Swift formatters using SourceKit would suggest that the "just" isn't warranted.


*Q. You wrote a Swift parser from scratch!? Are you a wizard?*

> A. Yes. Yes I am.


*Q. How does it work?*

> A. First it loops through the source file character-by-character and breaks it into tokens, such as `number`, `identifier`, `whitespace`, etc. That's handled by the functions in `Tokenizer.swift`.

> Next, it applies a series of formatting rules to the token array, such as "remove whitespace at the end of a line", or "ensure each opening brace appears on the same line as the preceding non-whitespace token". Each rule is designed to be relatively independent of the others, so they can be enabled or disabled individually (the order matters though). The rules are all defined as floating functions in `Rules.swift`.

> Finally, the modified token array is stitched back together to re-generate the source file.


*Q. Why aren't you using regular expressions?*

> A. See https://xkcd.com/1171/ for details.


*Q. Can I use the `SwiftFormat.framework` inside another app?*

> A. I only created the framework to facilitate testing, so to be honest I've no idea if it will work in an app, but you're welcome to try. If you need to make adjustments to the public/private flags or namespaces to get it working, open an issue on Github (or evene better, a pull request).


Known issues
---------------

SwiftFormat currently reformats multiline comment blocks without regard for the original indenting. That means

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
     
To work around that, either use blocks of single-line comments...

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
* @nicklockwood - Everything else

([Full list of contributors](https://github.com/nicklockwood/SwiftFormat/graphs/contributors))
