[![Travis](https://img.shields.io/travis/schibsted/layout.svg)](https://travis-ci.org/schibsted/layout)
[![Coveralls](https://coveralls.io/repos/github/schibsted/layout/badge.svg)](https://coveralls.io/github/schibsted/layout)
[![Platform](https://img.shields.io/cocoapods/p/Layout.svg?style=flat)](http://cocoadocs.org/docsets/Layout)
[![Swift](https://img.shields.io/badge/swift-3.4-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Swift](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Layout.svg)](https://img.shields.io/cocoapods/v/Layout.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Layout

Layout is a native Swift framework for implementing iOS user interfaces using XML template files and runtime-evaluated expressions. It is intended as a more-or-less drop-in replacement for Nibs and Storyboards, but offers a number of advantages such as human-readable templates and live editing.

![Screenshot](Layout.gif?raw=true)

- [Introduction](#introduction)
    - [Why?](#why)
    - [How?](#how)
- [Usage](#usage)
    - [Installation](#installation)
    - [Dependencies](#dependencies)
    - [Integration](#integration)
    - [Editor Support](#editor-support)
    - [Live Reloading](#live-reloading)
    - [Debugging](#debugging)
    - [Constants](#constants)
    - [State](#state)
    - [Actions](#actions)
    - [Outlets](#outlets)
    - [Delegates](#delegates)
    - [Animation](#animation)
    - [Safe Area Insets](#safe-area-insets)
    - [Legacy Layout Mode](#legacy-layout-mode)
- [Expressions](#expressions)
    - [Layout Properties](#layout-properties)
    - [Geometry](#geometry)
    - [Strings](#strings)
    - [Attributed Strings](#attributed-strings)
    - [URLs](#urls)
    - [Fonts](#fonts)
    - [Colors](#colors)
    - [Images](#images)
    - [Enums](#enums)
    - [OptionSets](#optionsets)
    - [Arrays](#arrays)
    - [Functions](#functions)
    - [Optionals](#optionals)
    - [Comments](#comments)
- [Standard Components](#standard-components)
    - [UIControl](#uicontrol)
    - [UIButton](#uibutton)
    - [UISegmentedControl](#uisegmentedcontrol)
    - [UIStepper](#uistepper)
    - [UIStackView](#uistackview)
    - [UITableView](#uitableview)
    - [UICollectionView](#uicollectionview)
    - [UIVisualEffectView](#uivisualeffectview)
    - [UIWebView](#uiwebview)
    - [WKWebView](#wkwebview)
    - [UITabBarController](#uitabbarcontroller)
    - [UINavigationController](#uinavigationcontroller)
- [Custom Components](#custom-components)
    - [Namespacing](#namespacing)
    - [Custom Property Types](#custom-property-types)
    - [Custom Constructor Arguments](#custom-constructor-arguments)
    - [Body Text](#body-text)
    - [Default Expressions](#default-expressions)
- [Advanced Topics](#advanced-topics)
    - [Layout-based Components](#layout-based-components)
    - [Manual Integration](#manual-integration)
    - [Composition](#composition)
    - [Templates](#templates)
    - [Parameters](#parameters)
    - [Macros](#macros)
    - [Ignore File](#ignore-file)
- [Example Projects](#example-projects)
    - [SampleApp](#sampleapp)
    - [UIDesigner](#uidesigner)
    - [Sandbox](#sandbox)
- [LayoutTool](#layouttool)
    - [Installation](#installation-1)
    - [Formatting](#formatting)
    - [Renaming](#renaming)
    - [Strings](#strings-1)
- [Xcode Extension](#xcodeextension)
    - [Installation](#installation-2)
    - [Formatting](#formatting-1)
- [FAQ](#faq)


# Introduction

## Why?

Layout seeks to solve a number of issues that make Storyboards unsuitable for large, collaborative projects, including:

* Proprietary, undocumented format
* Poor composability and reusability
* Difficult to apply common style elements and metric values without copy-and-paste
* Hard for humans to read, and consequently hard to resolve merge conflicts
* Limited WYSIWYG capabilities

Layout also includes a replacement for AutoLayout that aims to be:

* Simpler to use for basic layouts
* More intuitive and readable for complex layouts
* More deterministic and simpler to debug
* More performant (at least in theory :-))

To find out more about why we built Layout, and the problems it addresses, check out [this article](http://bytes.schibsted.com/layout-declarative-ui-framework-ios/).

## How?

Layout introduces a new node hierarchy for managing views, similar to the "virtual DOM" used by React Native.

Unlike UIViews (which use NSCoding for serialization), Layout nodes can be deserialized from a lightweight, human-readable XML format, and also offer a concise API for programmatically generating view layouts in code when you don't want to use a separate resource file.

View properties are specified using *expressions*, which are pure functions that are stored as strings and evaluated at runtime. Now, I know what you're thinking - *stringly-typed code is horrible!* - but Layout's expressions are strongly-typed, and designed to fail early, with detailed error messages to help you debug.

Layout is designed to work with ordinary UIKit components, not to replace or reinvent them. Layout-based views can be embedded inside Nibs and Storyboards, and Nib and Storyboard-based views can be embedded inside Layout-based views and view controllers, so there is no need to rewrite your entire app if you want to try using Layout.


# Usage

## Installation

Layout is provided as a standalone Swift framework that you can use in your app. It works with Swift 3.2 and 4.0, and is not tied to any particular package management solution.

To install Layout using CocoaPods, add the following to your Podfile:

```ruby
pod 'Layout', '~> 0.6'
```

To install using Carthage, add this to your Cartfile:

```
github "schibsted/Layout" ~> 0.6
```


## Dependencies

Layout has no external dependencies. It makes use of the [Expression](https://github.com/nicklockwood/Expression) and [Sprinter](https://github.com/nicklockwood/Sprinter) frameworks internally, but these have been included inside the Layout module as part of the source distribution, so there is no need to include them separately.

Because Expression and Sprinter are inside the Layout namespace, you can safely use Layout in a project that is already using another copy of either of these frameworks.


## Integration

The primary API exposed by Layout is the `LayoutNode` class. Create a layout node as follows:

```swift
let node = LayoutNode(
    view: UIView.self,
    expressions: [
        "width": "100%",
        "height": "100%",
        "backgroundColor": "#fff",
    ],
    children: [
        LayoutNode(
            view: UILabel.self,
            expressions: [
                "width": "100%",
                "top": "50% - height / 2",
                "textAlignment": "center",
                "font": "Courier bold 30",
                "text": "Hello World",
            ]
        )
    ]
)
```

This example code creates a centered `UILabel` inside a `UIView` with a white background that will stretch to fill its superview once mounted.

For simple views, creating the layout in code is a convenient solution that avoids the need for an external file. But the real power of the Layout framework comes from the ability to specify layouts using external XML files, because it allows for [live reloading](#live-reloading), which can significantly reduce development time.

The equivalent XML markup for the layout above is:

```xml
<UIView
    width="100%"
    height="100%"
    backgroundColor="#fff">

    <UILabel
        width="100%"
        top="50% - height / 2"
        textAlignment="center"
        font="Courier bold 30"
        text="Hello World"
    />
</UIView>
```

Most built-in iOS views should already work when used as a Layout XML element. For custom views, you may need to make a few minor changes for full Layout-compatibility. See the [Custom Components](#custom-components) section below for details.

To mount a `LayoutNode` inside a view or view controller, the simplest approach is to create a `UIViewController` subclass and add the `LayoutLoading` protocol. You can then use one of the following three options to load your layout:

```swift
class MyViewController: UIViewController, LayoutLoading {

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Option 1 - create a layout programmatically
        self.layoutNode = LayoutNode( ... )

        // Option 2 - load a layout synchronously from a bundled XML file
        self.loadLayout(named: ... )

        // Option 3 - load a layout asynchronously from an XML file URL
        self.loadLayout(withContentsOfURL: ... ) { error in
            ...   
        }
    }
}
```

Use option 1 for layouts generated in code. Use option 2 for XML layout files located inside the application resource bundle.

Option 3 can be used to load a layout from an arbitrary URL, which can be either a local file or remotely-hosted. This is useful if you need to develop directly on a device, because you can host the layout file on your Mac and then connect to it from the device to allow reloading of changes without recompiling the app. It's also potentially useful in production for hosting layouts in some kind of CMS system.

**Note:** The `loadLayout(withContentsOfURL:)` method offers limited control over caching, etc. so if you intend to host your layout files remotely, it may be better to download the XML to a local cache location first and then load it from there.


## Editor Support

You can edit Layout XML files directly in Xcode, but you will probably miss having autocomplete for view properties. There is currently no way to provide autocomplete support in Xcode, however Layout does now include support for the popular [Sublime Text](https://www.sublimetext.com) editor.

To install Layout autocompletion in Sublime Text:

1. Go to `Preferences > Browse Packages…`, which will open the Packages directory in the Finder
2. Copy the `layout.sublime-completions` file from the Layout repository into `Packages/User`

Autocomplete for standard UIKit views, view controllers and properties will now be available for xml files edited in Sublime Text.

There is currently no way to automatically generate autocomplete suggestions for custom views or properties, but you could manually add these to the `layout.sublime-completions` file.

We hope to add support for other editors in future. If you are interested in contributing to this effort, please [create an issue on Github](https://github.com/schibsted/layout/issues) to discuss it.


## Live Reloading

Layout provides a number of helpful features to improve your development productivity, most notably the [Red Box debugger](#debugging) and the *live reloading* feature.

When you load an XML layout file in the iOS Simulator, the Layout framework will attempt to find the original source XML file for the layout and load that instead of the static version bundled into the compiled app.

This means that you can make changes to your XML file and then reload it *without* recompiling the app or restarting the simulator.

**Note:** If multiple source files match the bundled file name, you will be asked to choose which one to load. See the [Ignore File](#ignore-file) section below if you need to exclude certain files from the search process.

You can reload your XML files at any time by pressing Cmd-R in the simulator (not in Xcode itself, as that will recompile the app). Layout will detect that key combination and reload the XML.

**Note:** This only works for changes you make to your layout XML files, or in your `Localizable.strings` file, not for Swift code changes in your view controller, or other resources such as images.

The live reloading feature, combined with the graceful handling of errors, means that it should be possible to do most of your interface development without needing to recompile the app.


## Debugging

If the Layout framework throws an error during XML parsing, mounting, or updating, it will display the *Red Box*, which is a full-screen overlay that displays the error message along with a reload button.

For non-critical errors (e.g. using a deprecated API) Layout will display a yellow warning bar at the bottom of the screen, which can be dismissed with a tap.

Thanks to the [live reloading](#live-reloading) feature, many bugs (e.g. syntax errors or misnamed properties) can be fixed without recompiling the app. Once you have fixed the bug, pressing reload (or Cmd-R) will dismiss any warnings or errors and reload the layout XML file.

The Red Box interface is managed by the `LayoutConsole` singleton. This exposes static methods to show and hide the console, along with an `isEnabled` property to enable or disable the console programmatically. By default, the console is enabled for debug builds and disabled for release, but if you need to override this setting at runtime you can do so.

If the `LayoutConsole` is disabled, errors and warnings will be printed to the Xcode console instead.


## Constants

Static XML is all very well, but most app content is dynamic. Strings, images, and even layouts themselves need to change at runtime based on user-generated content, the current locale, etc.

`LayoutNode` provides two mechanisms for passing dynamic data to the layout, which can then be referenced inside your expressions: *constants* and *state*.

Constants - as the name implies - are values that remain constant for the lifetime of the `LayoutNode`. These values don't need to be constant for the lifetime of the *app*, but changing them means re-creating the `LayoutNode` and its associated view hierarchy from scratch. The constants dictionary is passed into the `LayoutNode` initializer, and can be referenced by any expression in that node or any of its children.

A good use for constants would be localized strings, or something like colors or fonts used by the app UI theme. These are things that never (or rarely) change during the lifecycle of the app, so it's acceptable that the view hierarchy must be torn down in order to reset them.

Here is how you would pass some constants to your XML-based layout:

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "title": NSLocalizedString("homescreen.title", message: ""),
        "titleColor": UIColor.primaryThemeColor,
        "titleFont": UIFont.systemFont(ofSize: 30),
    ]
)
```

And how you might reference them in the XML:

```xml
<UIView ... >
    <UILabel
        width="100%"
        textColor="titleColor"
        font="{titleFont}"
        text="{title}"
    />
</UIView>
```

You may have noticed that the `title` and `titleFont` constants are surrounded by `{...}` braces, but the `titleColor` constant isn't. This is explained in the [Strings](##strings) and [Fonts](##fonts) subsections below.

You will probably find that some constants are common to every layout in your application, for example if you have constants representing standard spacing metrics, fonts or colors. It would be annoying to have to repeat these everywhere, but the lack of a convenient way to merge dictionaries in Swift (as of version 3.0) makes it painful to use a static dictionary of common constants as well.

For this reason, the `constants` argument of `LayoutNode`'s initializer is actually variadic, allowing you to pass multiple dictionaries, which will be merged automatically. This makes it much more pleasant to combine a global constants dictionary with a handful of custom values:

```swift
let extraConstants: [String: Any] = [
    ...
]

loadLayout(
    named: "MyLayout.xml",
    constants: globalConstants, extraConstants, [
        "title": NSLocalizedString("homescreen.title", message: ""),
        "titleColor": UIColor.primaryThemeColor,
        "titleFont": UIFont.systemFont(ofSize: 30),
    ]
)
```

## State

For more dynamic layouts, you may have properties that need to change frequently (perhaps even during an animation), and recreating the entire view hierarchy to change these is not very efficient. For these properties, you can use *state*. State works in much the same way as constants, except you can update the state *after* the `LayoutNode` has been initialized:

```swift
loadLayout(
    named: "MyLayout.xml",
    state: [
        "isSelected": false,
        ...
    ],
    constants: [
        "title": ...
    ]
)

func setSelected() {
    self.layoutNode?.setState([
        "isSelected": true
    ])
}
```

Note that you can use both constants and state in the same Layout. If a state variable has the same name as a constant, the state variable takes precedence. As with constants, state variables can be passed in at the root node of a hierarchy and accessed by any child node. If children in the hierarchy have their own constants or state variables, these will take priority over values set on their parent.

Although state can be updated dynamically, all state variables referenced in the layout must have been given a value before the `LayoutNode` is first mounted/updated. It's generally a good idea to set default values for all state variables when you first initialize the node.

Calling `setState()` on a `LayoutNode` after it has been created will trigger an update. The update causes all expressions in that node and its children to be re-evaluated. In future it may be possible to detect if parent nodes are indirectly affected by the state changes of their children and update them too, but currently that is not implemented.

In the example above, we've used a dictionary to store the state, but `LayoutNode` supports the use of arbitrary objects for state. A really good idea for layouts with complex state requirements is to use a `struct`. When you set the state using a `struct` or `class`, Layout uses Swift's introspection features to compare changes and determine if an update is necessary.

Internally the `LayoutNode` still just treats the struct as a dictionary of key/value pairs, but you get to take advantage of compile-time type validation when manipulating your state programmatically in the rest of your program:

```swift
struct LayoutState {
    let isSelected: Bool
}

loadLayout(
    named: "MyLayout.xml",
    state: LayoutState(isSelected: false),
    constants: [
        "title": ...
    ]
)

func setSelected() {
    self.layoutNode?.setState(LayoutState(isSelected: true))
}
```

When using a state dictionary, you do not have to pass every single property each time you set the state. If you are only updating a subset of properties, it is fine to pass a dictionary with only those key/value pairs. (This is not the case if you are using a struct, but don't worry - this is only a convenience feature, and makes little or no difference to performance.):

```swift
loadLayout(
  named: "MyLayout.xml",
  state: [
    "value1": 5,
    "value2": false,
  ]
)

func setSelected() {
    self.layoutNode?.setState(["value1": 10]) // value2 retains its previous value
}
```

## Actions

For any non-trivial view you will need to bind actions from controls in your view hierarchy to your view controller, and communicate user actions back to the view.

You can define actions on any `UIControl` subclass using `actionName="methodName"` in your XML, for example:

```xml
<UIButton touchUpInside="wasPressed"/>
```

There is no need to specify a target - the action will be automatically bound to the first matching method encountered in the responder chain. If no matching method is found, Layout will display an error.

**Note:** The error will be shown *when the node is mounted*, not deferred until the button is pressed, as it would be for actions bound using Interface Builder.

```swift
func wasPressed() {
    ...
}
```

The action's method name follows the Objective-C selector syntax conventions, so if you wish to pass the button itself as a sender, use a trailing colon in the method name:

```xml
<UIButton touchUpInside="wasPressed:"/>
```

Then the corresponding method can be implemented as:

```swift
func wasPressed(_ button: UIButton) {
    ...
}
```

Action expressions are treated as strings, and like other string expressions they can contain logic to produce a different value depending on the layout constants or state. This is useful if you wish to toggle the action between different methods, e.g.

```xml
<UIButton touchUpInside="{isSelected ? 'deselect:' : 'select:'}"/>
```

In this case, the button will call either the `select(_:)` or `deselect(_:)` methods, depending on the value of the `isSelected` state variable.


## Outlets

When creating views inside a Nib or Storyboard, you typically create references to individual views by using properties in your view controller marked with the `@IBOutlet` attribute, and Layout can utilize the same system to let you reference individual views in your hierarchy from code.

To create an outlet binding for a layout node, declare a property of the correct type on your view controller, and then reference it using the `outlet` constructor argument for the `LayoutNode`:

```swift
class MyViewController: UIViewController, LayoutLoading {

    @objc var labelNode: LayoutNode? // outlet

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.layoutNode = LayoutNode(
            view: UIView.self,
            children: [
                LayoutNode(
                    view: UILabel.self,
                    outlet: #keyPath(self.labelNode),
                    expressions: [ ... ]
                )
            ]
        )
    }
}
```

In this example we've bound the `LayoutNode` containing the `UILabel` to the `labelNode` property. A few things to note:

* There's no need to use the `@IBOutlet` attribute for your `outlet` property, but you can do so if you feel it makes the purpose clearer. If you do not use `@IBOutlet`, you will need to use `@objc` to ensure the property is visible to Layout at runtime.
* The type of the `outlet` property can be either `LayoutNode` or a `UIView` subclass that's compatible with the view managed by the node. The syntax is the same in either case - the type will be checked at runtime, and an error will be thrown if it doesn't match up.
* In the example above we have used Swift's `#keyPath` syntax to specify the `outlet` value, for better static validation. This is recommended, but not required.
* The `labelNode` outlet in the example has been marked as Optional. It is common to use Implicitly Unwrapped Optionals (IUOs) when defining IBOutlets, and that will work with Layout too, but it will result in a hard crash if you make a mistake in your XML and then try to access the outlet. Using regular Optionals means XML errors can be trapped and fixed without restarting the app.

To specify outlet bindings when using XML templates, use the `outlet` attribute:

```xml
<UIView>
    <UILabel
        outlet="labelNode"
        text="Hello World"
    />
</UIView>
```

In this case we lose the static validation provided by `#keyPath`, but Layout still performs a runtime check and will throw a graceful error in the event of a typo or type mismatch, rather than crashing.

Outlets can also be set using an expression instead of a literal value. This is useful if you wish to pass the outlet in to the template via a parameter, for example:

```xml
<UIView>
    <param name="labelOutlet" type="String"/>

    <UILabel
        outlet="{labelOutlet}"
        text="Hello World"
    />
</UIView>
```

The type of the parameter in this case must be `String`, and not `UILabel` as you might expect. The reason for this is that the outlet is a keyPath that references a property of the layout's owner (typically a view controller), not a direct reference to the view itself.

**Note:** Outlet expressions must be set using a constant or literal value, and cannot be changed once set. Attempting to set the outlet using a state variable or other dynamic value will result in an error.


## Delegates

Another commonly-used feature in iOS is the *delegate* pattern. Layout also supports this, but it does so in an implicit way that may be confusing if you aren't expecting it.

When loading a Layout XML file, or a programmatically-created `LayoutNode` hierarchy into a view controller, the views will be scanned for delegate properties and these will be automatically bound to the controller *if* it conforms to the specified protocol.

So for example, if your layout contains a `UIScrollView`, and your view controller conforms to the `UIScrollViewDelegate` protocol, then the view controller will automatically be attached as the delegate for the view controller:

```swift
class MyViewController: UIViewController, LayoutLoading, UITextFieldDelegate {
    var labelNode: LayoutNode!

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.layoutNode = LayoutNode(
            view: UIView.self,
            children: [
                LayoutNode(
                    view: UITextField.self, // delegate is automatically bound to MyViewController
                    expressions: [ ... ]
                )
            ]
        )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
```

There are a few caveats however:

* This mechanism currently only works for properties called "delegate" or "dataSource", or which are suffixed with "Delegate" or "DataSource" (e.g. "dragDelegate"). This is the standard convention used by UIKit components, but if you have custom controls that use a different naming convention for delegates, they won't be bound automatically and you will need to bind them programmatically.

* The binding mechanism relies on Objective-C runtime protocol detection, so it won't work for Swift protocols that aren't `@objc`-compliant.

* If you have multiple views in your layout that all use the same delegate protocol, e.g. several `UIScrollView`s or several `UITextField`s, then they will *all* be bound to the view controller. If you are only interested in receiving events from some views and not others, you can either add logic inside the delegate methods to determine which view is calling them, or explicitly disable the `delegate` properties of those views by setting them to `nil`:

```xml
<UITextField delegate="nil"/>
```

You can also set the delegate to a specific object by passing a reference to it as a state variable or constant and then referencing that in your delegate expression:

```swift
self.layoutNode = LayoutNode(
    view: UIView.self,
    constants: [
        "fieldDelegate": someDelegate
    ],
    children: [
        LayoutNode(
            view: UITextField.self,
            expressions: [
                "delegate": "fieldDelegate"
            ]
        )
    ]
)
```

**Note:** There is currently no safe way to explicitly bind a delegate to the layoutNode's owner class. Attempting to pass `self` as a constant or state variable will result in a retain cycle (which is why owner-binding is done implicitly rather than manually).

## Animation

UIKit has great support for animation, and naturally you'll want to include animations in your Layout-based interfaces, so how do you handle animation in Layout?

There are three basic types of animation in iOS:

1. Block-based animations, using `UIView.animate()`. Normally you would use this in UIKit by setting view properties and/or AutoLayout constraints inside an animation block. In Layout you should call `setState()` inside an animation block to implicitly animate any changes resulting from the state change:

```swift
UIView.animate(withDuration: 0.4) {
    self.layoutNode?.setState([...])
}
```

2. Animated setters. Some properties of UIViews have an animated setter variant that automatically applies an animation when called. For example, calling `UISwitch.setOn(_:animated:)` will animate the state of the switch, whereas setting the `on` property directly will update it immediately. Layout does not expose the `setOn(_:animated:)` method in XML, however if you have an expression for `<UISwitch isOn="onState"/>` then you can cause it to be updated with an animation by calling `setState(_:animated:)`:

```swift
self.layoutNode?.setState(["onState": true], animated: true)
```

Using the `animated` argument of `setState()` will implicitly call the animated variant of the setter for any property that is affected by the update. Properties that don't support animation will be set as normal.

3. User-driven animation. Some animation effects are controlled by the user dragging or scrolling. For example, you might have a parallax effect when scrolling that causes several views to move in various directions or speeds in sync with the scroll. To implement this kind of animation in Layout, call `setState()` inside the scroll or gesture handler, passing any parameters needed for the expressions that position the animated views. You can either implement the animation logic in Swift and pass the results as a state, or compute the animation state using expressions in your Layout XML - whichever works best for your use-case, e.g.

```xml
<UIView alpha="max(0, min(1, (position - 50) / 100))"/>
```

```swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.layoutNode?.setState(["position": scrollView.contentOffset.y])
}
```

## Safe Area Insets

iOS 11 introduced the concept of the *safe area* - a generalization of the top and bottom layout guides that were provided before for insetting content to account for status, navigation and tool/tab bars.

In order to prevent you from needing to include conditional compilation logic in your templates, Layout makes the iOS 11 `safeAreaInsets` property available across all iOS versions (falling back to using layout guides as the underlying implementation on iOS 10 and earlier).

To position a view inside the safe area of its parent, you could write:

```xml
<UIView
    top="parent.safeAreaInsets.top"
    left="parent.safeAreaInsets.left"
    bottom="100% - parent.safeAreaInsets.bottom"
    right="100% - parent.safeAreaInsets.right"
/>
```

**Note:** The value for `safeAreaInsets` exposed by Layout differs slightly from the documented behavior for `UIView.safeAreaInsets`:

Apple states that the `safeAreaInsets` value accounts for the status bar and other UI such as navigation or toolbars, but *only* for the root view of a view controller. For subviews, the insets reflect only the portion of the view that is covered by those bars, so for a small view in the middle of the screen, the insets would always be zero since the toolbars or iPhone X notch would never overlap this view.

For Layout, this approach creates problems, as your view frame may depend on the `safeAreaInsets` value, which would in turn be affected by the frame, creating a cyclic dependency. Rather than try to resolve this recursively, Layout always returns insets relative to the current view controller, so even for subviews that do not overlap the screen edges, the value of `safeAreaInsets` will be the same as for the root view.

`UIScrollView` derives its insets automatically on iOS 11, but this behavior differs from iOS 10. To achieve consistent behavior, you can set the `contentInsetAdjustmentBehavior` property to `never`, and then set the `contentInset` manually:

```xml
<UIScrollView
    contentInsetAdjustmentBehavior="never"
    contentInset="parent.safeAreaInsets"
    scrollIndicatorInsets.top="parent.safeAreaInsets.top"
    scrollIndicatorInsets.bottom="parent.safeAreaInsets.bottom"
/>
```

To simplify backwards compatibility, as with the `safeAreaInsets` property itself, Layout permits you to set `contentInsetAdjustmentBehavior` on any iOS version, however the value is ignored on iOS versions earlier than 11.

## Legacy Layout Mode

You may have seen references in the code or documentation to the `LayoutNode.useLegacyLayoutMode`. In the original design of Layout, the `right` and `bottom` expressions were specified relative to the top-left corner of the view, rather than relative to their respective edges as you might expect.

Version 0.6.22 of Layout introduces a new layout mode where `bottom` and `right` expressions are relative to the `bottom` and `right` edges, which is more intuitive for users familiar with CSS or AutoLayout, and is also more consistent with the way that the `leading` and `trailing` expressions work.

To avoid breaking compatibility with existing Layout projects, you must explicitly opt-in to the new layout mode by setting `LayoutNode.useLegacyLayoutMode = false` in your application code. This is a global property so it only needs to be set once. A good place to do this is in the `application(_:didFinishLaunchingWithOptions:)` method of your `AppDelegate`:

```swift
import UIKit
import Layout

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // enable Layout's new layout mode
        LayoutNode.useLegacyLayoutMode = false
        
        // other setup code
        ...
    }
}
```

In a future version of Layout, the new layout mode will become the default and the legacy layout mode will eventually be removed, so it's a good idea to begin migrating your templates now!


# Expressions

The most important feature of the `LayoutNode` class is its built-in support for parsing and evaluating expressions. The implementation of this feature is built on top of the [Expression](https://github.com/nicklockwood/Expression) framework, but Layout adds a number of extensions in order to support UIKit types and layout-specific logic.

Expressions can be simple, hard-coded values such as "10", or more complex expressions such as "width / 2 + someConstant". The available operators and functions to use in an expression depend on the name and type of the property being expressed, but all expressions support the standard decimal math and boolean operators and functions that you find in most C-family programming languages. You can also extend Layout with custom functions (see the [Functions](#functions) section below).

Expressions in a `LayoutNode` can reference constants and state passed in to the node or any of its parents. They can also reference the values of any other expression defined on the node, or any supported property of the view:

```
5 + width / 3
isSelected ? blue : gray
min(width, height)
a >= b ? a : b
pi / 2
```

Additionally, a node can reference properties of its parent node using `parent.someProperty`, or of its immediate sibling nodes using `previous.someProperty` and `next.someProperty`:

```xml
<UIView>
    <UILabel text="Foo"/>
    
    <!-- this label will be 20pts below its previous sibling -->
    <UILabel
        top="previous.bottom + 20"
        text="Bar"
    />
</UIView>
```

To reference a node that is not an immediate sibling, you can give the node an `id` attribute, and then reference that node using `#` followed by the id:

```xml
<UIView>
    <UILabel id="first" left="20" text="Foo"/>
    <UILabel right="20" text="Bar"/>
    
    <!-- this label will be aligned with the first label -->
    <UILabel
        left="#first.left"
        top="previous.bottom + 20"
        text="Bar"
    />
</UIView>
```

## Layout Properties

The set of expressible properties available to a `LayoutNode` depends on the view type, but every node supports the following properties at a minimum:

```
top
left
bottom
right
leading
trailing
width
height
center.x
center.y
```

**Note:** see the [Legacy Layout Mode](#legacy-layout-mode) section for an important note about the `right` and `bottom` layout properties.

These are numeric values (measured in screen points) that specify the frame for the view. In addition to the standard operators, all of these properties allow values specified in percentages:

```xml
<UIView right="50%"/>
```

Percentage values are relative to the width or height of the parent `LayoutNode` (or the superview, if the node has no parent). The expression above is typically equivalent to writing the following (unless the parent is a `UIScrollView`, in which case the `contentInset` and safe area are also taken into account):

```xml
<UIView right="parent.width / 2">
```

Additionally, the `width` and `height` properties can make use of a virtual variable called `auto`. The `auto` variable equates to the content width or height of the node, which is determined by a combination of three things:

* The `intrinsicContentSize` property of the native view (if specified)
* Any AutoLayout constraints applied to the view by its (non-Layout-managed) subviews
* The enclosing bounds for all the children of the node.

If a node has no children and no intrinsic size, `auto` is usually equivalent to `100%`, depending on the view type.

Though entirely written in Swift, the Layout library makes heavy use of the Objective-C runtime to automatically generate property bindings for any type of view. The available properties therefore depend on the type of view that is passed into the `LayoutNode` constructor (or the name of the XML node, if you are using XML layouts).

Only types that are visible to the Objective-C runtime can be detected automatically. Fortunately, since UIKit is an Objective-C framework, most view properties work just fine. For ones that don't, it is possible to manually expose these using an extension on the view (this is covered below under [Advanced Topics](#advanced-topics)).

Because it is possible to pass in arbitrary values via constants and state, Layout supports referencing almost any type of value inside an expression, even if there is no way to express it as a literal.

Expressions are strongly-typed, so passing the wrong type of value to a function or operator or returning the wrong type from an expression will result in an error. Where possible, these type checks are performed when the node is first mounted, so that the error is surfaced immediately.

The following types of property are given special treatment in order to make it easier to specify them using an expression string:

## Geometry

Because Layout manages the view frame automatically, direct manipulation of the view's `frame` or `bounds` is not permitted - you should use the `top`, `left`, `bottom`, `right`, `leading`, `trailing`, `width`, `height`, `center.x` and `center.y` expressions instead. However, there are other geometric properties that do not directly affect the frame, and many of these *are* available to be set via expressions, for example:

* contentSize
* contentInset
* layer.transform

These properties are not simple numbers, but structs containing several packed values. So how can you manipulate these with Layout expressions?

Firstly, almost any property type can be set using a constant or state variable, even if there is no way to define a literal value for it in an expression. So for example, the following code will set the `layer.transform` even though Layout has no way to specify a literal `CATransform3D` struct in an expression:

```swift
loadLayout(
    named: "MyLayout.xml",
    state: [
        "flipped": true
    ],
    constants: [
        "identityTransform": CATransform3DIdentity,
        "flipTransform": CATransform3DMakeScale(1, 1, -1)
    ]
)
```

```xml
<UIView layer.transform="flipped ? flipTransform : identityTransform"/>
```

Secondly, for many geometric struct types, such as `CGPoint`, `CGSize`, `CGRect`, `CGAffineTransform` and `UIEdgeInsets`, Layout has built-in support for directly referencing the member properties in expressions. To set the top `contentInset` value for a `UIScrollView`, you could use:

```xml
<UIScrollView contentInset.top="safeAreaInsets.top + 10"/>
```

And to explicitly set the `contentSize`, you could use:

```xml
<UIScrollView
    contentSize.width="200%"
    contentSize.height="auto + 20"
/>
```

**Note:** `%` and `auto` are permitted inside `contentSize.width` and `contentSize.height`, just as they are for `width` and `height`, but percentages refer to the view's own frame size, not its parent. Percentage sizes inside a `UIScrollView` also account for the `contentInset`, so 100% should fill the view's content area without scrolling.

Layout also supports virtual keyPath properties for manipulating `CATransform3D` (as documented [here](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreAnimation_guide/Key-ValueCodingExtensions/Key-ValueCodingExtensions.html)), and makes equivalent properties available for `CGAffineTransform` too. That means you can perform operations like rotating or scaling a view directly in your Layout XML without needing to do any matrix math:

```xml
<UIView transform.rotation="pi / 2"/>

<UIView transform.scale="0.5"/>

<UIView layer.transform.translation.z="500"/>
```

## Strings

It is often necessary to use literal strings inside an expression, and since expressions themselves are typically wrapped in quotes, it would be annoying to have to used nested quotes every time. For this reason, string expressions are treated as literal strings by default, so in this example...

```xml
<UILabel text="title"/>
```

...the `text` property of the label has been given the literal value "title", and not the value of a constant named "title", as you might expect.

To use an expression inside a string property, escape the value using `{ ... }` braces. So to use a constant or variable named `title` instead of the literal value "title", you would write this:

```xml
<UILabel text="{title}"/>
```

You can use arbitrary logic inside the braced expression block, including math and boolean comparisons. The value of the expressions need not be a string, as the result will be *stringified*. You can use multiple expression blocks inside a single string expression, and mix and match expression blocks with literal segments:

```xml
<UILabel text="Hello {name}, you have {n + 1} new messages"/>
```

If you need to use a string literal *inside* an expression block, then you can use single quotes to escape it:

```xml
<UILabel text="Hello {hasName ? name : 'World'}"/>
```

If you want to display the literal `{` or `}` brace characters, you can escape them as follows:

```xml
<UILabel text="Open brace: {'{'}. Close brace: {'}'}."/>
```

Layout has support for basic manipulation of string literals and variables inside expressions. To concatenate strings, you can either use multiple expression clauses within a single string property, or you can use the `+` operator within a single expression:

```xml
<UILabel text="{'foo'}{'bar'}"/>

<UILabel text="{'foo' + 'bar'}"/>
```

You can reference individual characters or substrings by using Swift-style subscripting syntax. Ordinarily, Swift requires String subscripts to use values of type `String.Index`, but for convenience, Layout supports integer indexes and ranges as well. These are zero-based and refer to the `Character` index (as opposed to bytes or unicode scalars):

```xml
<!-- Displays 'e' -->
<UILabel text="{'Hello World'[1]}"/>

<!-- Displays 'foo' -->
<UILabel text="{'foobar'[0..<3]}"/>

<!-- Displays 'bar' -->
<UILabel text="{'foobar'[3...]}"/>
```

Attempting to reference a substring outside the original string bounds won't crash, but will display a Red Box error. There is currently no way to check the bounds of a string from inside an expression unless you implement a custom `count()` function, or equivalent (see the [functions](#functions) section below for details).

If your app is localized, you will need to use constants instead of literal strings for virtually all of the strings in your template. Localizing all of these strings and passing them as individual constants would be tedious, so Layout offers some alternatives:

Constants prefixed with `strings.` are assumed to be localized strings, and will be looked up in the application's `Localizable.strings` file. So for example, if your `Localizable.strings` file contains the following entry:

```
"Signup.NameLabel" = "Name";
```

Then you can reference this directly in your XML as follows, without creating an explicit constant in code:

```xml
<UILabel text="{strings.Signup.NameLabel}"/>
```

It's common practice on iOS to use the English text as the key for localized strings, which may often contain spaces or punctuation, making it invalid as an identifier. In these cases, you can use backticks to escape the key, as follows:

```xml
<UILabel text="{`strings.Some text with spaces and punctuation!`}"/>
```

Localized strings may contain placeholder tokens for runtime values. On iOS, the convention for this is to use the printf `%` escape sequences for these placeholders, which are then replaced propgrammatically. Layout supports this mechanism by treating parameterized string constants as functions. For example, for the following localized string:

```
"Messages.Title" = "Hello %s, you have %i new messages";
```

You could display the formatted string directly inside your template as follows (assuming that `name` and `messageCount` are valid state variables):

```xml
<UILabel text="{strings.Messages.Title(name, messageCount)}"/>
```

Layout checks the placeholders in the format string, and will display an error if you pass the wrong number or types of arguments. Layout's format string processing is powered by the [Sprinter](https://github.com/nicklockwood/Sprinter) framework, and has full support for the [IEEE printf spec](http://pubs.opengroup.org/onlinepubs/009695399/functions/printf.html), so you can use flags such as `%1.3f` or `%3$0x` in your localized strings to control parameter order and formatting.

In addition to reducing boilerplate, strings referenced directly from your XML will also take advantage of [live reloading](#live-reloading), so you can make changes to your `Localizable.strings` file, and they will be picked up when you type Cmd-R in the simulator, with no need to recompile the app.


## Attributed Strings

Attributed strings work much the same way as regular string expressions, except that you can use inline attributed string constants to create styled text:

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "styledText": NSAttributedString(string: "styled text", attributes: ...)
    ]
)
```

```xml
<UILabel text="This is some {styledText} embedded in unstyled text" />
```

A neat extra feature built in to attributed string expressions is support for inline (X)HTML markup:

```swift
LayoutNode(
    view: UILabel.self,
    expressions: [
        "text": "I <i>can't believe</i> this <b>actually works!</b>"
    ]
)
```

Using this feature inside an XML attribute is awkward because the tags have to be escaped using `&gt;` and `&lt;`, so Layout lets you use HTML *inside* a view node, and it will be automatically assigned to the appropriate attributed text property of the view (see the [Body Text](#body-text) section for details):

```xml
<UILabel>This is a pretty <b>bold</b> solution</UILabel>
```

HTML support relies on the built-in `NSMutableAttributedString` HTML parser, which does not recognize inline CSS styles or scripts, and only supports a minimal subset of HTML. The following tags have been verified to work, but others may or may not, depending on the iOS version:

```xml
<p>, // paragraph
<h1> ... <h6> // heading
<b>, <strong> // bold
<i>, <em> // italic
<u> // underlined
<strike> // strikethrough
<ol>, <li> // ordered list
<ul>, <li> // unordered list
<br/> // linebreak
<sub> // subscript
<sup> // superscript
<center> // centered text
```

As with regular text attributes, inline HTML can contain embedded expressions, which can themselves contain either attributed or non-attributed string variables or constants:

```xml
<UILabel>Hello <b>{name}</b></UILabel>
```

## URLs

URL expressions are treated as a literal string, so dynamic logic (such as references to constants or variables) must be escaped with `{ ... }`:

```xml
<!-- literal url -->
<MyView url="index.html"/>

<!-- url constant or variable -->
<MyView url="{someURL}"/>
```

URLs that do not contain a scheme are assumed to be local file path references. Paths without a leading `/` are assumed to be relative to the app resources bundle, and ones beginning with `~/` are relative to the user directory.

```xml
<!-- remote url -->
<MyView url="http://example.com"/>

<!-- app resource bundle url -->
<MyView url="images/foo.jpg"/>

<!-- user document url -->
<MyView url="~/Documents/report.pdf"/>
```

## Fonts

Like String and URL expressions, font expressions are treated as literal strings, so references to constants or variables must be escaped with `{ ... }`. A font expression can encode several distinct pieces of data, delimited by spaces.

The `UIFont` class encapsulates the font family, size, weight and style, so a font expression can contain any or all of the following space-delimited attributes, in any order:

```
<font-name>
<font-traits>
<font-weight>
<font-style>
<font-size>
```

Any font attribute that isn't specified will be set to the system default - currently San Francisco 17 point as of iOS 11.

The `<font-name>` is a string. It is case-insensitive and can represent either an exact font name, or a font family name. The font name is permitted to contain spaces, and can optionally be enclosed in single quotes. Use "System" as the font name if you want to use the system font (although this is the default anyway if no name is specified). You can also use "SystemBold" and "SystemItalic". Here are some examples:

```xml
<UILabel font="Courier"/>

<UILabel font="helvetica neue"/>

<UILabel font="'times new roman'"/>

<UILabel font="SystemBold"/>
```

The `<font-traits>` are values of type `UIFontDescriptorSymbolicTraits`. The following traits are supported:

```swift
italic
condensed
expanded
monospace
```

A given font expression may include multiple traits. Note that the `bold` trait is not supported, because `bold` is treated as a `<font-weight>` value instead. If, for some reason, you wish to specify the bold trait instead of the bold weight, you can do so by using the fully-qualified trait name inside braces:

```xml
<UILabel text="Font with bold trait" font="{UIFontDescriptorSymbolicTraits.traitBold}"/>

<UILabel text="Font with bold weight" font="bold"/>
```

The `<font-weight>` is a `UIFont.Weight` constant, from the following list:

```swift
ultraLight
thin
light
regular
medium
semibold
bold
heavy
black
```

Examples:

```xml
<UILabel font="Courier bold"/>

<UILabel font="System black"/>

<UILabel font="helvetica neue ultraLight"/>
```

**Note:** Writing "SystemBold" is not the same as "System bold". The former is equivalent to `UIFont.boldSystemFont(ofSize: 17)` in Swift, and uses the bold *trait* (see above), the latter is equivalent to `UIFont.systemFont(ofSize: 17, weight: .bold)` and uses the bold *weight* which produces a different result.

The `<font-style>` is a `UIFontTextStyle` constant, from the following list:

```swift
title1
title2
title3
headline
subheadline
body
callout
footnote
caption1
caption2
```

Specifying one of these values sets the font size to match the user's font size setting for that style, and enables dynamic text sizing, so that changing the font size setting will automatically update the font.

The `<font-size>` can be either a number or a percentage. If you use a percentage value it will either be relative to the default font size (17 points) or whatever size has already been specified in the font expression. For example, if the expression includes a font-style constant, the size will be relative to that. Here are some more examples:

```xml
<UILabel font="Courier 150%"/>

<UILabel font="Helvetica 30 italic"/>

<UILabel font="helvetica body bold 120%"/>
```

`UIFont` constants or variables can also be used via inline expressions. To use a `UIFont` constant called `themeFont`, but override its size and weight, you could write:

```xml
<UILabel font="{themeFont} 25 bold"/>
```

You can also define custom named fonts using an extension on `UIFont`, and Layout will detect them automatically:

```swift
extension UIFont {
    @objc static let customFont = UIFont.systemFont(ofSize: 42)
}
```

Fonts defined in this way can be referenced by name from inside any font expression, either with or without the "Font" suffix, but are not available inside braced sub-expressions `{...}` unless prefixed with `UIFont.`:

```xml
<UILabel font="customFont bold"/>

<UILabel font="custom italic"/>

<UILabel font="{UIFont.customFont} 120%"/>
```

## Colors

Colors can be specified using CSS-style rgb(a) hex literals. These can be 3, 4, 6 or 8 digits long, and are prefixed with a `#`:

```
#fff // opaque white
#fff7 // 50% transparent white
#ff0000 // opaque red
#ff00007f // 50% transparent red
```

Built-in static UIColor constants are supported as well:

```
white
red
darkGray
etc.
```

You can also use CSS-style `rgb()` and `rgba()` functions. For consistency with CSS conventions, the red, green and blue values are specified in the range 0-255, and alpha in the range 0-1:

```
rgb(255,0,0) // red
rgba(255,0,0,0.5) // 50% transparent red
```

You can use these literals and functions as part of a more complex expression, for example:

```xml
<UILabel textColor="isSelected ? #00f : #ccc"/>

<UIView backgroundColor="rgba(255, 255, 255, 1 - transparency)"/>
```

Note that there is no need to enclose these expressions in braces. Unless the expression clashes with a named color asset (see below), Layout will understand what you meant.

The use of color literals is convenient for development purposes, but you are encouraged to define constants (or XCAssets, if you are targeting iOS 11 and above) for any commonly used colors in your app, as these will be easier to refactor later.

To supply custom named color constants, you can pass colors in the constants dictionary when loading a layout:

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "headerColor": UIColor(0.6, 0.5, 0.5, 1),
    ]
)
```

Color constants are available to use in any expression (although they probably aren't much use outside of a color expression).

You can also define a custom colors using an extension on `UIColor`, and Layout will detect it automatically:

```swift
extension UIColor {
    @objc static let headerColor = UIColor(0.6, 0.5, 0.5, 1)
}
```

Colors defined in this way can be referenced by name from inside any color expression, either with or without the "Color" suffix, but are not available inside other expression types unless prefixed with `UIColor.`:

```xml
<UIView backgroundColor="headerColor"/>

<UIView backgroundColor="header"/>

<UIView isHidden="backgroundColor == UIColor.header"/>
```

Finally, in iOS 11 and above, you can define named colors as XCAssets and then reference the color by name in your expressions:

```xml
<UIView backgroundColor="MyColor"/>

<UIView backgroundColor="my color"/>

<UIView backgroundColor="color-number-{level}"/>
```

For color assets defined in a framework or standalone bundle, you can prefix the color name with the bundle name (or fully-qualified bundle identifier) followed by a colon. For example:

```xml
<UIView backgroundColor="com.example.MyBundle:MyColor"/>

<UIView backgroundColor="MyBundle:MyColor"/>
```

You can also reference a `Bundle`/`NSBundle` instance stored in a constant or variable:

```xml
<UIImageView image="{bundle}:MyColor"/>
```

**Note:** There is no need to use quotes around the color asset name, even if it contains spaces or other punctuation. Layout will interpret invalid color asset names as expressions. You can use `{ ... }` braces to disambiguate between asset names and constant or variable names if necessary.

## Images

Static images can be specified by name or via a constant or state variable. As with colors, there is no need to use quotes around the name, however you can use `{ ... }` braces to disambiguate if needed:

```xml
<UIImageView image="default-avatar"/>

<UIImageView image="{imageConstant}"/>

<UIImageView image="image_{index}.png"/>
``` 

As with color assets, image assets defined in a framework or standalone bundle can be referenced by prefixing with a bundle name/identifier or constant followed by a colon:

```xml
<UIImageView image="com.example.MyBundle:MyImage"/>

<UIImageView image="MyBundle:MyImage"/>

<UIImageView image="{bundle}:MyImage"/>
```

## Enums

To set a value for an enum-type expression, just use the name of the value. For example:

```xml
<UIImageView contentMode="scaleAspectFit"/>
```

You can use logic directly inside enum expressions - there is no need to escape the logic or use quotes around the names:

```xml
<UIImageView contentMode="isSmallImage ? center : scaleAspectFit"/>
```

Standard UIKit enum values are exposed as constants that may be used only in expressions of that type. There is no need to prefix the enum value name with a `.` as you would in Swift, but you *must* prefix with the type to use the enum value inside other expression types:

```xml
<!-- will work -->
<UIImageView height="contentMode == UIViewContentMode.scaleAspectFit ? 200 : 300"/>

<!-- won't work -->
<UIImageView height="contentMode == scaleAspectFit ? 200 : 300"/>
<UIImageView height="contentMode == .scaleAspectFit ? 200 : 300"/>
```

## OptionSets

OptionSet expressions work the same way as enums. If you want to set multiple values for an OptionSet, separate them with commas:

```xml
<UITextView dataDetectorTypes="phoneNumber, link"/>
```

There is no need to wrap multiple OptionSet values in square brackets, as you would in Swift. As with enums, OptionSet value names cannot be used outside of the expression that sets them unless they are prefixed with the type name.

## Arrays

You can use Swift-style square-bracketed array literals inside any type of expression:

```xml
<UISegmentedControl items="['Hello', 'World']"/>
```

You can use the `+` operator to concatenate array literals:

```xml
<UISegmentedControl items="['Hello'] + ['And', 'Goodbye']"/>
```

For array-type expressions, the square brackets are optional; you can just pass comma, delimited values and they will be treated as an array:

```xml
<UISegmentedControl items="'Hello', 'World'"/>
```

If you return a single non-array value from an array expression, it will be "boxed" inside an array automatically:

```xml
<!-- 'Hello' becomes ["Hello"] -->
<UISegmentedControl items="'Hello'"/>
```

The `,` operator automatically flattens nested array constants, so the following code will produce a single, flat array instead of an outer array with another array inside it:

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "firstTwoItems": ["First", "Second"],
    ]
)
```

```xml
<UISegmentedControl items="firstTwoItems, 'Third'"/>
```

You can use the same array literal syntax inside [macros](#macros), if you need to re-use the values:

```xml
<UIView>
    <macro name="ITEMS" items="'First', 'Second'"/>
    <UISegmentedControl items="ITEMS"/>
</UIView>
```

If you need to access individual elements of an array, you can use the `[]` subscript operators in an expression:

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "colors": [UIColor.green, UIColor.black],
    ],
)
```

```xml
<!-- green label -->
<UILabel textColor="colors[0]"/>
```

You can also subscript arrays using ranges. All of the standard Swift range operators are supported, including open-ended ranges:

```xml
<!-- Only the second and third item -->
<UISegmentedControl items="items[1...2]"/>

<!-- Only the first and second item -->
<UISegmentedControl items="items[..<2]"/>

<!-- All but the first item -->
<UISegmentedControl items="items[1...]"/>
```

Attempting to access an array with an out-of-bounds index or range won't crash, but will display a Red Box error. There is currently no way to check the bounds of an array from inside an expression unless you implement a custom `count()` function, or equivalent (see the [functions](#functions) section below for details).

## Functions

Layout expressions support a number of built-in math functions such as `min()`, `max()`, `pow()`, etc. But you can also extend Layout with additional custom functions that can be called inside your template.

Custom functions are Swift closures that conform to the signature `([Any]) throws -> Any`. Any closure constant conforming to this type that is passed into your `LayoutNode` can be called inside an expression.

Currently there is no way to specify the number or type of arguments expected by a custom function, so you must be careful to implement type checking within your custom function to prevent crashes. Here are some examples:

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "count": { (args: [Any]) throws -> Any in
            guard args.count == 1 else {
                throw LayoutError.message("count() function expects a single argument")  
            }
            switch args[0] {
            case let array as [Any]:
                return array.count
            case let string as String:
                return string.count
            default:
                throw LayoutError.message("count() function expects an Array or String")   
            }
            return array.count
        },
        "uppercased": { (args: [Any]) throws -> Any in
            guard let string = args.first as? String else {
                throw LayoutError.message("uppercased() function expects a String argument")  
            }
            return string.uppercased()
        },
    ],
)
```

```xml
<UILabel text="{uppercased('uppercased text'}"/>

<UILabel text="'foo' contains {count('foo')} characters"/>
```

## Optionals

Layout currently has fairly limited support for optionals in expressions. There is no way to specify that an expression's return value is optional, and so returning `nil` from an expression is usually an error. There are a few exceptions to this:

1. Returning nil from a String expression will return an empty string
2. Returning nil from a UIImage expression will return a blank image with zero width/height
3. Returning nil for a delegate or other protocol property is permitted to override the default binding behavior

The reason for these specific exceptions is that passing a nil image or text to a component is a common approach in UIKit for indicating that a given element is not needed, and by allowing nil values for these types, we avoid the need to pass additional flags into the component to mark these as unused.

There is slightly more flexibility when handing optional values *inside* an expression. It is possible to refer to `nil` in an expression, and to compare values against it. For example:

```xml
<UIView backgroundColor="col == nil ? #fff : col"/>
```

In this example, if the `col` constant is `nil`, we return a default color of white instead. This can also be written more simply using the `??` null-coalescing operator:

```xml
<UIView backgroundColor="col ?? #fff"/>
```

## Comments

Complicated or obscure code often benefits from documentation in the form of inline comments. You can insert comments into your XML layout files as follows:

```xml
<!-- `name` is the user's full name -->
<UILabel text="{name}"/>
```

Unfortunately, while XML supports comment tags *between* nodes, there is no way to place comments between attributes within a node, so if a node has multiple attributes this approach is not very satisfactory.

To work around this, Layout allows you to use C-style "//" comments *inside* the expression attributes themselves:

```xml
<UILabel
    text="{name // the user's full name}"
    backgroundColor="colors.primary // the primary color"
/>
```

This feature is also very convenient during development if you want to temporarily comment-out an expression:

```xml
<UIView temporarilyDisabledProperty="// someValue"/>
```

Comments can be used in any expression, but for string-type expressions there are a few caveats: In a string expression, anything outside of `{...}` braces is considered to be part of the literal string value, and that includes `/` characters. For that reason, this won't work as intended:

```xml
<UIImage image="MyImage.png // comment"/>
```

Because the image attribute in the above expression is interpreted as a string, the "// comment" is treated as part of the name. The workaround for this is to put the comment inside `{...}`. Either of the following will work:

```xml
<UIImage image="MyImage.png{// comment}"/>

<UIImage image="{'MyImage.png' // comment}"/>
```

The exception to this is for when the entire expression is commented out. If you wish to temporarily comment-out an expression, placing "//" at the start of the comment will work regardless of the expression type:

```xml
<UIImage image="// MyImage.png"/>
```

In the unlikely event that you need the literal value of a string expression to begin with "//", you can escape the slashes using `{...}`:

```xml
<UILabel text="// this is a comment"/>

<UILabel text="{// this is also a comment}"/>

<UILabel text="{'// this is not a comment'}"/>

<UILabel text="{'//'} this is also not a comment"/>
```

# Standard Components

Layout has good support for most built-in UIKit views and view controllers. It can automatically create almost any `UIView` subclass using `init(frame:)`, and can set any property that is compatible with Key Value Coding (KVC), but some views expect extra initializer arguments, or have properties that cannot be set by name at runtime, or which require special treatment for other reasons.

The following views and view controllers have all been tested and are known to work correctly:

* UIButton
* UICollectionView
* UICollectionViewCell
* UICollectionViewController
* UIControl
* UIImageView
* UILabel
* UINavigationController
* UIProgressView
* UIScrollView
* UISearchBar
* UISegmentedControl
* UISlider
* UIStackView
* UIStepper
* UISwitch
* UITabBarController
* UITableView
* UITableViewCell
* UITableViewController
* UITableViewHeaderFooterView
* UITextField
* UITextView
* UIView
* UIViewController
* UIVisualEffectView
* UIWebView
* WKWebView

If a view is not listed here, it will probably work to some extent, but may need to be partially configured using native Swift code. If you encounter such cases, please report them on [Github](https://github.com/schibsted/layout/) so we can add better support for them in future.

To configure a view programmatically, create an outlet for it in your XML file:

```xml
<SomeView outlet="someView"/>
```

Then you can perform the configuration in your view controller:

```swift
@IBOutlet weak var someView: SomeView? {
    didSet {
        someView?.someProperty = foo
    }
}
```

In some cases, standard UIKit views and controllers have been extended with additional properties or behaviors to help them interface better with Layout. These cases are listed below:


## UIControl

`UIControl` requires some special treatment because of the way that action binding is performed. Every `UIControl` has an `addTarget(_:action:for:)` method used for binding methods to specific events. Since Layout is limited to setting properties, there's no direct way to call this method, so actions are exposed to Layout using the following pseudo-properties:

* touchDown
* touchDownRepeat
* touchDragInside
* touchDragOutside
* touchDragEnter
* touchDragExit
* touchUpInside
* touchUpOutside
* touchCancel
* valueChanged
* primaryActionTriggered
* editingDidBegin
* editingChanged
* editingDidEnd
* editingDidEndOnExit
* allTouchEvents
* allEditingEvents
* allEvents

These properties are of type `Selector`, and can be set to the name of a method on your view controller. For more details, see the [Actions](#actions) section above.


## UIButton

`UIButton` has the ability to change various appearance properties based on its current `UIControlState`, but the API for specifying these properties is method-based rather than property-based, so cannot be exposed directly to Layout. Instead, Layout provides pseudo-properties for each state:

To set for all states:

* title
* attributedTitle
* titleColor
* titleShadowColor
* image
* backgroundImage

To set for specific states, where `[state]` can be one of `normal`, `highlighted`, `disabled`, `selected` or `focused`:

* [state]Title
* [state]AttributedTitle
* [state]TitleColor
* [state]TitleShadowColor
* [state]Image
* [state]BackgroundImage


## UISegmentedControl

`UISegmentedControl` contains a number of segments, each of which can display either an image or title. This is set up using the `init(items:)` constructor, which accepts an array of String or UIImage elements.

Layout exposes this using the `items` expression. You can set this to an array of titles as follows:

```xml
<UISegmentedControl items="'First', 'Second', 'Third'"/>
```

This works for strings, however there is no way to specify image literals inside an array in a Layout expression currently, so to use images for your segement items you will need to create them programmatically in Swift and pass them to the layout as constants or state variables:

```xml
<UISegmentedControl items="hello, world"/>
```

```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "hello": UIImage(named: "HelloIcon"),
        "world": UIImage(named: "WorldIcon"),
    ]
)
```

`UISegmentedControl` also has methods for inserting, removing or updating the segment titles and images, but this API is not suitable for use with Layout, so instead the `items` array is exposed as a pseudo property that can be updated at any time. In the example below, changing the `segmentItems` state in Swift updates the displayed segments: 

```xml
<UISegmentedControl items="segmentItems"/>
```

```swift
loadLayout(
    named: "MyLayout.xml",
    state: [
        "segmentItems": ["Hello", UIImage(named: "HelloIcon")],
    ]
)

...

layoutNode?.setState(["segmentItems": ["Goodbye", UIImage(named: "GoodbyeIcon")]], animated: true)
```

Like `UIButton`, `UISegmentedControl` has style properties that can vary based on the `UIControlState`, and these are supported in the same way, using pseudo-properties.

To set for all states:

* backgroundImage
* dividerImage
* titleColor
* titleFont

To set for specific states, where `[state]` can be one of `normal`, `highlighted`, `disabled`, `selected` or `focused`:

* [state]BackgroundImage
* [state]TitleColor
* [state]TitleFont

**Note:** Setting `dividerImage` for different states is not currently supported due to limitations of the naming convention. It is also not currently possible to set different images for different `UIBarMetrics` values.

You can set the content offset for all segments using:

* contentPositionAdjustment
* contentPositionAdjustment.horizontal
* contentPositionAdjustment.vertical

Or for specific segments, where `[segment]` can be one of `any`, `left`, `center`, `right`, `alone`:

* [segment]ContentPositionAdjustment
* [segment]ContentPositionAdjustment.horizontal
* [segment]ContentPositionAdjustment.vertical


## UIStepper

Like `UIButton` and `UISegmentedControl`, `UIStepper` also has state-based pseudo-properties:

To set for all states:

* backgroundImage
* dividerImage
* incrementImage
* decrementImage

To set for specific states, where `[state]` can be one of `normal`, `highlighted`, `disabled`, `selected` or `focused`:

* [state]BackgroundImage
* [state]IncrementImage
* [state]DecrementImage


## UIStackView

You can use Layout's expressions to create arbitrarily complex view arrangements, but sometimes the expressions required to describe relationships between siblings can be quite verbose, and it would be nice to be able to use something more like [flexbox](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Using_CSS_flexible_boxes) to describe the overall arrangement for a collection of views.

Layout supports UIKit's `UIStackView` class, which you can use for flexbox-like collections in situations where `UITableView` or `UICollectionView` would be overkill. Here is an example of a simple vertical stack:

```xml
<UIStackView
    alignment="center"
    axis="vertical"
    spacing="10">
    
    <UILabel text="First row"/>
    <UILabel text="Second row"/>
</UIStackView>
```

Subview nodes nested inside a `UIStackView` are automatically added to the `arrangedSubviews` array. The `width` and `height` properties are respected for children of a `UIStackView`, but the `top`, `left`, `bottom`, `right`, `center.x` and `center.y` expressions are ignored.

Since `UIStackView` is a non-drawing view, only its position and layout attributes can be configured. Inherited `UIView` properties such as `backgroundColor` or `borderWidth` are unavailable.


## UITableView

You can use a `UITableView` inside a Layout template in much the same way as you would use any other view:

```xml
<UITableView
    backgroundColor="#fff"
    outlet="tableView"
    style="plain"
/>
```

The tableView's `delegate` and `dataSource` will automatically be bound to the file's owner, which is typically either your `UIViewController` subclass, or the first nested view controller that conforms to one or both of the `UITableViewDelegate`/`DataSource` protocols. If you don't want that behavior, you can explicitly set them (see the [Delegates](#delegates) section above).

You would define the view controller logic for a Layout-managed table in pretty much the same way as you would if not using Layout:

```swift
class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView? {
        didSet {

            // Register your cells after the tableView has been created
            // the `didSet` handler for the tableView property is a good place
            tableView?.register(MyCellClass.self, forCellReuseIdentifier: "cell")
        }
    }

    var rowData: [MyModel]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MyCellClass
        cell.textLabel.text = rowData.title
        return cell
    }
}
```

Using a Layout-based `UITableViewCell` is also possible. There are two ways to define a `UITableViewCell` in XML - either directly inside your table XML, or in a standalone file. A cell template defined inside the table XML might look something like this:

```xml
<UITableView
    backgroundColor="#fff"
    outlet="tableView"
    style="plain">

    <UITableViewCell
        reuseIdentifier="cell"
        textLabel.text="{title}">

        <UIImageView
            top="50% - height / 2"
            right="100% - 20"
            width="auto"
            height="auto"
            image="{image}"
            tintColor="#999"
        />
    </UITableViewCell>

</UITableView>
```

Then the logic in your table view controller would be:

```swift
class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var rowData: [MyModel]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Use special Layout extension method to dequeue the node rather than the view itself
        let node = tableView.dequeueReusableCellNode(withIdentifier: "cell", for: indexPath)

        // Set the node state to update the cell
        node.setState(rowData[indexPath.row])

        // Cast the node view to a table cell and return it
        return node.view as! UITableViewCell
    }
}
```

Alternatively, you can define the cell in its own XML file. If you do that, the dequeuing process is the same, but you will need to register it manually:

```swift
class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView? {
        didSet {
            // Use special Layout extension method to register the layout xml file for the cell
            tableView?.registerLayout(named: "MyCell.xml", forCellReuseIdentifier: "cell")
        }
    }

    ...
}
```

Layout supports dynamic table cell height calculation. To enable this, just set a height expression for your cell. Dynamic table cell sizing also requires that the table view's `rowHeight` is set to `UITableViewAutomaticDimension` and a nonzero value is provided for `estimatedRowHeight`, but Layout sets these for you by default.

**Note:** If your cells all have the same height, it is significantly more efficient to set an explicit `rowHeight` property on the `UITableView` instead of setting the height for each cell.

Layout also supports using XML layouts for `UITableViewHeaderFooterView`, and there are equivalent methods for registering and dequeuing `UITableViewHeaderFooterView` layout nodes.

**Note:** To use a custom section header or footer you will need to set the `estimatedSectionHeaderHeight` or `estimatedSectionFooterHeight` to a nonzero value in your XML:

```xml
<UITableView estimatedSectionHeaderHeight="20">

    <UITableViewHeaderFooterView
        backgroundView.backgroundColor="#fff"
        height="auto + 10"
        reuseIdentifier="templateHeader"
        textLabel.text="Section Header"
    />
    
    ...

</UITableView>
```

If you prefer, you can create a `<UITableViewController/>` in your XML instead of subclassing `UIViewController` and implementing the table data source and delegate. Note that if you do this, there is no need to explicitly create the `UITableView` yourself, as the `UITableViewController` already includes one. To configure the table, you can set properties of the table view directly on the controller using a `tableView.` prefix, e.g.

```xml
<UITableViewController
    backgroundColor="#fff"
    tableView.separatorStyle="none"
    tableView.contentInset.top="20"
    style="plain">

    <UITableViewCell
        reuseIdentifier="cell"
        textLabel.text="{title}"
    />
</UITableViewController>
```


## UICollectionView

Layout supports `UICollectionView` in a similar way to `UITableView`. If you do not specify a custom `UICollectionViewLayout`, Layout assumes that you want to use a `UICollectionViewFlowLayout`, and creates one for you automatically. When using a `UICollectionViewFlowLayout`, you can configure its properties using expressions on the collection view, prefixed with `collectionViewLayout.`:

```xml
<UICollectionView
    backgroundColor="#fff"
    collectionViewLayout.itemSize.height="100"
    collectionViewLayout.itemSize.width="100"
    collectionViewLayout.minimumInteritemSpacing="10"
    collectionViewLayout.scrollDirection="horizontal"
/>
```

As with `UITableView` the collection view's `delegate` and `dataSource` will automatically be bound to the file's owner. Using a Layout-based `UICollectionViewCell`, either directly inside your collection view XML or in a standalone file, also works the same. A cell template defined inside the collection view XML might look something like this:

```xml
<UICollectionView
    backgroundColor="#fff"
    collectionViewLayout.itemSize.height="100"
    collectionViewLayout.itemSize.width="100">

    <UICollectionViewCell
        clipsToBounds="true"
        reuseIdentifier="cell">

        <UIImageView
            contentMode="scaleAspectFit"
            height="100%"
            width="100%"
            image="{image}"
            tintColor="#999"
        />
    </UICollectionViewCell>

</UICollectionView>
```

Then the logic in your collection view controller would be:

```swift
class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var itemData: [MyModel]

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // Use special Layout extension method to dequeue the node rather than the view itself
        let node = collectionView.dequeueReusableCellNode(withIdentifier: "cell", for: indexPath)

        // Set the node state to update the cell
        node.setState(itemData[indexPath.row])

        // Cast the node view to a table cell and return it
        return node.view as! UICollectionViewCell
    }
}
```

Alternatively, you can define the cell in its own XML file. If you do that, the dequeuing process is the same, but you will need to register it manually:

```swift
class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var itemData: [MyModel]

    @IBOutlet var collectionView: UICollectionView? {
        didSet {
            // Use special Layout extension method to register the layout xml file for the cell
            collectionView?.registerLayout(named: "MyCell.xml", forCellReuseIdentifier: "cell")
        }
    }

    ...
}
```

Dynamic collection cell size calculation is also supported. To enable this, just set a width and height expression for your cell. If your cells all have the same size, it is more efficient to set an explicit `collectionViewLayout.itemSize` on the `UICollectionView` instead.

Layout does not currently support using XML to define supplementary `UICollectionReusableView` instances, but this will be added in future.

Layout supports the use of `UICollectionViewController`, with the same caveats as for `UITableViewController`.


## UIVisualEffectView

`UIVisualEffectView` has an `effect` property of type `UIVisualEffect`. `UIVisualEffect` is an abstract base class that is not used directly - instead you would typically set the effect to be either a `UIBlurEffect` or a `UIVibrancyEffect` (which itself contains a `UIBlurEffect`).

The `effect` property can be set programmatically, or by passing a `UIVisualEffect` instance into your `LayoutNode` as a constant or state variable:


```swift
loadLayout(
    named: "MyLayout.xml",
    constants: [
        "blurEffect": UIBlurEffect(style: .regular),
    ]
)
```

```xml
<UICollectionView
    effect="blurEffect"
>
```

For convenience, Layout also allows you to configure the effect directly using expressions. To configure the effect use the `UIBlurEffect(style)` or `UIVibrancyEffect(style)` constructor functions inside the `effect` expression as follows:

```xml
<UICollectionView
    effect="UIVibrancyEffect(light)"
>
```

The `style` argument is of type `UIBlurEffectStyle`, and  is supported for both `UIBlurEffect` and `UIVibrancyEffect`. You can set the style using a constant or state variable, or it can be set to one of the following built-in values:

* extraLight
* light
* dark
* extraDark
* regular
* prominent

**Note:** You can also use this solution for setting the `UITableView.separatorEffect` property, or any other property of type `UIVisualEffect` that is exposed in a custom view or controller. 


## UIWebView

The API for `UIWebView` uses methods for loading content, which isn't directly usable from XML, so Layout exposes these methods as properties instead. To load a URL, you can use the `request` property, as follows:

```xml
<UIWebView request="http://apple.com"/>

<UIWebView request="{urlRequestConstant}"/>
```

You can use a literal URL string or a constant or state variable containing a `URL` or `URLRequest` value. The `request` parameter can also be used for local file content. Paths without a scheme or leading `/` are assumed to be relative to the app resources bundle, and ones beginning with `~/` are relative to the user directory:

```xml
<!-- bundled resource -->
<UIWebView request="pages/index.html"/>

<!-- user document -->
<UIWebView request="~/Documents/homepage.html"/>
```

To load a literal HTML string you can use the `htmlString` property:

```xml
<UIWebView htmlString="&lt;p&gt;Hello World&lt;/p&gt;"/>

<UIWebView htmlString="{htmlConstant}"/>
```

**Note:** If you specify a literal `htmlString` attribute in your Layout XML then you will have to encode the tags using `&lt;`, `&gt;` and `&quot;`. A better alternative is to use Layout's inline HTML feature (as described in the [Attributed Strings](#attributed-strings) section):

```xml
<UIWebView>
    <p>Hello World</p>
</UIWebView>
```

Unlike labels, webviews can display arbitrary HTML including CSS styles and JavaScript. Defining CSS or JavaScript blocks inline in your XML is likely to be awkward however due to the need to escape `<`, `&` and `{` characters. It is probably easier to put complex scripts or stylesheets in a separate local file (although currently Layout does not support live reloading for such files).

The `UIWebView.loadHTMLString()` method also accepts a `baseURL` parameter for relative URLs inside the HTML. Layout exposes this as a separate `baseURL` property:

```xml
<UIWebView
    baseURL="http://example.com"
    htmlString="&lt;img href=&quot;/someImage.jpg&quot;&gt;"
/>
```

If you need to adjust the content insets for the web view, you can do this via the `scrollView` property:

```xml
<UIWebView
    scrollView.contentInsetAdjustmentBehavior="never"
    scrollView.contentInset.bottom="safeAreaInsets.bottom"
    scrollView.scrollIndicatorInsets="scrollView.contentInset"
    request="..."
/>
```

## WKWebView

Layout supports `WKWebView` in the same way as `UIWebView`, by converting the various load methods into properties. In addition to the aforementioned `scrollView`, `request`, `htmlString` and `baseURL` properties, for `WKWebView` Layout also adds `fileURL` and `readAccessURL` properties, which are used for secure access to local web content:

```xml
<WKWebView
    readAccessURL="~/Documents"
    fileURL="~/Documents/homepage.html"
/>
```

Layout also exposes the `configuration` property of `WKWebView`. This is a read-only property, but you can set it with a constant value when constructing your view, or configure the properties individually using expressions:

```xml
<WKWebView
    configuration="baseConfiguration"
    request="..."
/>

<WKWebView
    configuration.allowsAirPlayForMediaPlayback="true"
    configuration.allowsInlineMediaPlayback="false"
    request="..."
/>
```


## UITabBarController

For the most part, Layout works best when implemented on a per-screen basis, with one `LayoutLoading` view controller for each screen. There is basic support for defining collection view controllers such as `UITabBarController` however, as demonstrated in the SampleApp.

To define a `UITabBarController`-based layout in XML, nest one or more `UIViewController` nodes inside a `UITabBarController` node, as follows:

```xml
<UITabBarController>
    <UIViewController ... />
    <UIViewController ... />
    ... etc
</UITabBarController>

```

Every `UIViewController` has a `tabBarItem` property that can be used to configure the tab appearance when that view controller is nested inside a `UITabBarController`, and Layout exposes this object and its properties for configuration via expressions:

```xml
<UITabBarController>
    <UIViewController
        tabBarItem.title="Foo"
        tabBarItem.image="Bar.png"
    />
    ...
</UITabBarController>

```

The `tabBarItem` has the following sub-properties that may be set:

* title
* image
* selectedImage
* systemItem
* badgeValue
* badgeColor (iOS 10+ only)
* titlePositionAdjustment

The `systemItem` property overrides the title and image. It can be set to any of the following constant values:

* more
* favorites
* featured
* topRated
* recents
* contacts
* history
* bookmarks
* search
* downloads
* mostRecent
* mostViewed

It is not possible to replace the `UITabBar` of a `UITabBarController` without subclassing it and overriding the `tabBar` property, however, you can customize the tab bar in Layout by adding a `<UITabBar/>` node to your `<UITabBarController/>`:

```xml
<UITabBarController>
    <UITabBar
        backgroundImage="Background.png"
        barStyle="default"
        isTranslucent="false"
    />
    ...
</UITabBarController>
```

The following property and pseudo-property expressions are available for `<UITabBar/>`:

* barStyle
* barPosition
* barTintColor
* isTranslucent
* tintColor
* unselectedItemTintColor (iOS 10+ only)
* backgroundImage
* selectionIndicatorImage
* shadowImage
* itemPositioning
* itemWidth
* itemSpacing


## UINavigationController

`UINavigationController` is not a particularly good fit for the Layout paradigm because it represents a mutable stack of view controllers, and Layout's XML files can only describe a static hierarchy.

You *can* use Layout to specify the *initial* stack of view controllers in a navigation controller, however, which can then be updated programmatically:

```xml
<UINavigationController>
    <UIViewController
        title="Root View"
    />
    <UIViewController
        title="Middle View"
    />
    <UIViewController
        title="Topmost View"
    />
</UINavigationController>
```

As with the tab bar, the navigation bar is not configured directly, but indirectly via the `navigationItem` property of each `UIViewController`. Layout exposes this object and its properties as follows:

```xml
<UINavigationController>
    <UIViewController
        navigationItem.title="Form"
        navigationItem.leftBarButtonItem.title="Submit"
        navigationItem.leftBarButtonItem.action="submit:"
    />
    ...
</UINavigationController>
```

The `navigationItem` has the following sub-properties that may be set:

* title
* prompt
* titleView
* hidesBackButton
* leftBarButtonItem
* leftBarButtonItems
* rightBarButtonItem
* rightBarButtonItems
* leftItemsSupplementBackButton

Many of these properties can only be usefully configured via constants or state variables, since there is no way to create literal values for them in an expression, however the `leftBarButtonItem` and `rightBarButtonItem` can also be manipulated directly using the following sub-properties:

* title
* image
* systemItem
* style
* action
* width
* tintColor

The `action` property is a selector that should match a method on the owning view controller. As with `UIControl`, there is no way to set the target explicitly at present.

The `style` property is an enum that accepts either `plain` (the default), or `done` as its value. The `systemItem` property overrides the title and image, and can be set to any of the following constant values:

* done
* cancel
* edit
* save
* add
* flexibleSpace
* fixedSpace
* compose
* reply
* action
* organize
* bookmarks
* search
* refresh
* stop
* camera
* trash
* play
* pause
* rewind
* fastForward
* undo
* redo
* pageCurl

It is also possible to customize the navigation bar and toolbar of a `UINavigationController` at construction time by supplying custom subclasses. This feature is exposed in Layout using constructor expressions:

```xml
<UINavigationController
    navigationBarClass="MyNavigationBar"
    toolbarClass="MyToolbar">
    ...
</UINavigationController>
```

Alternatively, to customize properties of the navigation bar or toolbar, you can include a `<UINavigationBar/>` or `<UIToolbar/>` node directly inside the `UINavigationController`, as follows:

```xml
<UINavigationController>
    <UINavigationBar
        backgroundImage="Background.png"
        barStyle="default"
        isTranslucent="false"
    />
    ...
</UINavigationController>
```

The following property and pseudo-property expressions are available for `<UINavigationBar/>` and `<UIToolbar/>`:

* barStyle
* barPosition
* barTintColor
* isTranslucent
* tintColor
* backgroundImage
* shadowImage

And the following for `<UINavigationBar/>` only:

* titleColor
* titleFont
* titleVerticalPositionAdjustment
* backIndicatorImage
* backIndicatorTransitionMaskImage


# Custom Components

As covered in the [Standard Components](#standard-components) section above, Layout can create and configure most built-in UIKit views and view controllers automatically without needing any special support, but some require special treatment to conform to the Layout paradigm.

The same applies to custom UI components that you create yourself. If you follow standard conventions for your view interfaces, then for the most part these should *just work*, however you may need to take some extra steps for full compatibility:


## Namespacing

As you are probably aware, Swift classes are scoped to a particular module. If you have an app called "MyApp" and it declares a custom `UIView` subclass called `FooView`, then the fully-qualified class name of the view would be `MyApp.FooView`, not just `FooView`, as it would have been in Objective-C.

Layout deals with the common case for you by using the main module's namespace automatically if you don't include it yourself. Either of these will work for referencing a custom view in your XML:

```xml
<MyApp.FooView/>

<FooView/>
```

In the interests of avoiding boilerplate, you should generally use the latter form. However, if you package custom components into a separate module then you will need to refer to them using their fully-qualified name in your XML.


## Custom Property Types

As mentioned above, Layout uses the Objective-C runtime to automatically detect property names and types for use with expressions. If you are using Swift 4.0 or above, you will need to explicitly annotate your properties with `@objc` for them to work in Layout, as the default behavior is now for properties to not be exposed to the Objective-C runtime.

Even if you mark your properties with `@objc`, the Objective-C runtime only supports a subset of possible Swift types, and even for Objective-C types, some runtime information is lost. For example, it's currently impossible to automatically detect the valid set of raw values and case names for enum types at runtime.

There are also some situations where otherwise compatible property types may be implemented in a way that doesn't show up as an Objective-C property at runtime, or the property setter may not be compatible with KVC (Key-Value Coding), resulting in a crash when it is accessed using `setValue(forKey:)`.

To solve this, it is possible to manually expose additional properties and custom setters/getters for views by using an extension. The Layout framework already uses this feature to expose constants for many standard UIKit properties, but if you are using a 3rd party component, or creating your own, you may need to write an extension to properly support configuration via Layout expressions.

To generate a Layout-compatible property type definition and setter/getter for a custom view, create an extension as follows:

```swift
extension MyView {

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["myProperty"] = RuntimeType(...)
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "myProperty":
            self.myProperty = values as! ...
        default:
            try super.setValue(value, forExpression: name)
        }
    }
    
    open override func value(_ value: Any, forSymbol name: String) throws -> Any {
        switch name {
        case "myProperty":
            return self.myProperty
        default:
            return try super.value(value, forSymbol: name)
        }
    }
}
```

These overrides add "myProperty" to the list of known expressions for that view, and provide static setter and getter methods for the property.

**Note:** The setter uses `setValue(_:forExpression:)` but the getter uses `value(_:forSymbol:)`. That's because not every symbol that can be read inside an expression can be set using an expression - for example, you might have read-only properties such as `safeAreaInsets` that are read-only, and therefore do not require a setter. Read-only properties should not be included in the `expressionTypes` dictionary.

The `RuntimeType` class shown in the example is a type wrapper used by Layout to work around the limitations of the Swift type system. It can encapsulate information such as the list of possible values for a given enum, which it is not possible to determine automatically at runtime.

`RuntimeType` can be used to wrap any Swift type, for example:

```swift
RuntimeType(MyStructType.self)
```

The preferred way to define custom runtime types is as static vars on the `RuntimeType` class, added via an extension:

```swift
extension RuntimeType {
    
    @objc static let myStructType = RuntimeType(MyStructType.self)
}

extension MyView {

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["myProperty"] = .myStructType
        return types
    }
    
    ...
}
```

Exposing your runtime type in this way makes it available for use in parameters, and for enum types it makes the cases available for use in any expression via the type's namespace. Note the name of the `myStructType` property matches the type name, but with a lowercase prefix - this is required, as is the `@objc` attribute.

Layout's `RuntimeType` wrapper can also be used to specify a set of enum values:

```swift
extension RuntimeType {

    @objc static let nsTextAlignment = RuntimeType([
        "left": .left,
        "right": .right,
        "center": .center,
        "justified": .justified,
        "natural": .natural,
    ] as [String: NSTextAlignment])
}
```

Swift enum values cannot be set automatically using the Objective-C runtime, but if the underlying type of the property matches the `rawValue` (as is the case for most Objective-C APIs) then it's typically not necessary to also provide a custom `setValue(forExpression:)` implementation. You'll have to determine this by testing it on a case-by-case basis.

OptionSets can be specified in the same way as enums:

```swift
extension RuntimeType {

    @objc static let uiDataDetectorTypes = RuntimeType([
        "phoneNumber": .phoneNumber,
        "link": .link,
        "address": .address,
        "calendarEvent": .calendarEvent,
        "all": .all,
    ] as [String: UIDataDetectorTypes])
}
```

Again, for Objective-C APIs it is typically not necessary to provide a custom `setValue(forExpression:)` implementation for an OptionSet value, but if the type of the property is defined in Swift as the OptionSet type itself rather than the `rawValue` type, then you may need to do so.


## Custom Constructor Arguments

By default, Layout automatically instantiates views using the `init(frame:)` designated initializer, with a size of zero. But sometimes views have an alternative constructor that accepts one or more arguments that can't be changed later. In these cases it is necessary to manually expose this constructor to Layout.

To expose a custom view constructor, create an extension as follows:

```swift
extension MyView {

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "myArgument": RuntimeType(SomeType.self)
        ]
    }
    
    open override class func create(with node: LayoutNode) throws -> MyView {
        if let myArgument = try node.value(forExpression: "myArgument") as? SomeType {
            self.init(myArgument: myArgument)
            return
        }
        self.init(frame: .zero)
    }
}
```

**Note:** We are overriding the `parameterTypes` variable here instead of the `expressionTypes` variable we used earlier for implementing custom properties. The difference is that `parameterTypes` are for expressions that are only used for constructing the view, and can't be changed later. Parameter expressions will not be re-evaluated when `state` is updated.

The `create(with:)` method calls `value(forExpression:)` to get the value for the expression. This will return nil if the expression has not been set, so there is no need to check that separately.

In the example above we fall back to the default constructor if the argument isn't set, but if we want to make the argument mandatory, we could throw an error instead:

```swift
open override class func create(with node: LayoutNode) throws -> MyView {
    guard let myArgument = try node.value(forExpression: "myArgument") as? SomeType else {
        throw LayoutError("myArgument is required")
    }
    self.init(myArgument: myArgument)
}
```


## Body Text

Layout supports the use of inline (X)HTML within an XML file as a convenient way to specify attributed string values (see the [Attributed Strings](#attributed-strings) section for details). In order to enable this feature for a custom view, you will need to tell Layout which property the HTML should be used to set.

This is done using the `bodyExpression` class property:

```swift
extension MyView {

    open override class var bodyExpression: String? {
        return "heading"
    }
}
```

The value of this property must be the name of an existing property defined in the `expressionTypes` or `parameterTypes` dictionaries. The type of the property must be either `String` or `NSAttributedString`.

For convenience, Layout will detect if the view has a property called "text", "attributedText", "title" or "attributedTitle", and automatically map the body text to that. If your view has a text property matching one of those names, there is no need to override `bodyExpression`.

Returning `nil` from the `bodyExpression` property will disable the inline HTML feature for that view.


## Default Expressions

Layout tries to determine sensible defaults for the width and height expressions if unspecified. To do this, it looks at a variety of properties, such as the `intrinsicContentSize` and whether the view uses AutoLayout constraints. This mechanism doesn't work 100% of the time, however.

For custom components, you can provide explicit default expressions to be used instead. These are not limited to "width" and "height" expressions - you can provide defaults for any expression type.

To set the default expressions for your view, create an extension as follows:

```swift
extension MyView {

    open override class var defaultExpressions: [String: String] {
        return [
            "width": "100%",
            "height": "auto",
            "backgroundColor": "white",
        ]
    }
}
```

**Note:** The defaults for "width" and "height" should almost always be set to either "100%" or "auto". For views that have a fixed size, you might be tempted to set a specific numerical default width or height, but it's generally better to do that by overriding the `intrinsicContentSize` property instead, so that the view also works when used with regular AutoLayout instead of Layout:

```swift
extension MyView {

    open override class var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIViewNoIntrinsicMetric,
            height: 40
        )
    }
}
```


# Advanced Topics

## Layout-based Components

If you are creating a library of views that use Layout internally, it's probably overkill wrap each one in its own `UIViewController` subclass.

If the consumers of your component library are using Layout, then you could expose all your components as xml files and allow them to be composed directly using Layout templates or code, but if you want the library to work well with an ordinary UIKit app then it's better if each component is exposed as a regular `UIView` subclass.

To implement this, subclass `UIView` (or `UIControl`, `UIButton`, etc) and add the `LayoutLoading` protocol. You can then use the `loadLayout(...)` methods just as you would with a view controller:

```swift
class MyView: UIView, LayoutLoading {

    override init(frame: CGRect) {
        super.init(frame: frame)

        loadLayout(
            named: "MyView.xml",
            state: ...,
            constants: ...,
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure layout is updated after screen rotation, etc
        self.layoutNode?.view.frame = self.bounds
    }
}
```

**Note:** In the above example, the root view defined in the xml will be loaded as a *subview* of MyView, and will be automatically set to the same size. It would therefore not make sense for the root view in the xml to also be an instance of `MyView`, unless you want your view structure to be:

```xml
<MyView>
    <MyView>
        ...
    </MyView>
</MyView>
``` 

Attempting to load a view inside itself like this will throw a runtime error, because otherwise there's a danger of creating an infinite loading loop.

If the layout has a dynamic size, you may wish to update the container view's frame whenever the layout frame changes. To implement that, add the following code:

```swift
class MyView: UIView, LayoutLoading {

    ...
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure layout is updated after screen rotation, etc
        self.layoutNode?.view.frame = self.bounds
        
        // Update frame to match layout
        self.frame.size = self.intrinsicContentSize
    }
    
    public override var intrinsicContentSize: CGSize {
        return layoutNode?.frame.size ?? .zero
    }
}
```

The default implementation of `LayoutLoading` will bubble errors up the responder chain to the first view or view controller that handles them. If no responder in the chain intercepts the error, it will be displayed in the [Red Box console](#debugging).


## Manual Integration

If you would prefer not to use the `LayoutLoading` protocol, you can mount a `LayoutNode` into a view or view controller manually by using the `mount(in:)` method:

```swift
class MyViewController: UIViewController {
    var layoutNode: LayoutNode?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a layout node from and XML file or data object
        self.layoutNode = try? LayoutNode.with(xmlData: ...)

        // Mount it
        try? self.layoutNode?.mount(in: self)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Ensure layout is updated after screen rotation, etc
        self.layoutNode?.view.frame = self.bounds
    }
}
```

If you are using some fancy architecture like [Viper](https://github.com/MindorksOpenSource/iOS-Viper-Architecture) that splits up view controllers into sub-components, you may find that you need to bind a `LayoutNode` to something other than a `UIView` or `UIViewController` subclass. In that case you can use the `bind(to:)` method, which will connect the node's outlets, actions and delegates to the specified owner object, but won't attempt to mount the view or view controllers.

The `mount(in:)` and `bind(to:)` methods may each throw an error if there is a problem with your XML markup, or in an expression's syntax or symbols.

These errors are not expected to occur in a correctly implemented layout - they typically only happen if you have made a mistake in your code - so for release builds it should be OK to suppress them with `try!` or `try?` (assuming you've tested your app properly before releasing it).

If you are loading XML templates from an external source, you might prefer to catch and log these errors instead of allowing them to crash or fail silently, as there is a greater likelihood of an error making it into production if templates and native code are updated independently.


## Composition

For large or complex layouts, you may wish to split your layout into multiple files. This can be done easily when creating a `LayoutNode` programmatically, by assigning subtrees of `LayoutNode`s to temporary variables, but what about layouts defined in XML?

Fortunately, Layout has a nice solution for this: any layout node in your XML file can contain an `xml` attribute that references an external XML file. This reference can point to a local file, or even a remote URL:

```xml
<UIView xml="MyView.xml"/>
```

The referenced XML is just an ordinary layout file, and can be loaded and used normally, but when loaded using the composition feature it replaces the node that loads it. The attributes of the original node will be merged with the external node once it has loaded.

Loading is synchronous for local xml files, but for remote URLs loading is performed asynchronously, so the original node will be displayed first and will be updated once the XML for the external node has loaded.

Any children of the original node will be replaced by the contents of the loaded node, so you can insert a placeholder view to be displayed while the real content is loading:

```xml
<UIView backgroundColor="#fff" xml="MyView.xml">
    <UILabel text="Loading..."/>
</UIView>
```

The root node of the referenced XML file must be the same class as (or a subclass of) the node that loads it. You can replace a `<UIView/>` node with a `<UIImageView/>` for example, or a `<UIViewController/>` with a `<UITableViewController/>`, but you cannot replace a `<UILabel/>` with a `<UIButton/>`, or a `<UIView/>` with a `<UIViewController/>`.


## Templates

Templates are sort of the opposite of composition, and work more like class inheritance in OOP. As with the composition feature, a template is a standalone XML file that you import into your node. But when a layout node imports a template, the node's children are *appended* to those of the inherited layout, instead of the template node replacing them. This is useful if you have a bunch of nodes with common attributes or elements:

```xml
<UIView template="MyTemplate.xml">
    <UILabel>Some unique content</UILabel>
</UIView>
```

As with composition, the template itself is just an ordinary layout file, and can be loaded and used normally:

```xml
<!-- MyTemplate.xml -->
<UIView backgroundColor="#fff">
    <UILabel>Shared Heading</UILabel>

    <!-- children of the importing node will be inserted here -->
</UIView>
```

The imported template's root node class must be either the same class or a *superclass* of the importing node (unlike with composition, where it must be the same class or a *subclass*).

If your template has a complex internal structure, you may wish to specify where children will be inserted, instead of just having them appended to the existing top-level sub-nodes. To do that, you can use the `<children/>` tag.

The `<children/>` tag can be placed anywhere inside the template (including inside sub-nodes of the template node) and it will be replaced by the children of the importing node:

```xml
<!-- MyTemplate.xml -->
<UIView backgroundColor="#fff">
    <UILabel>Shared Heading</UILabel>
    <UIView>
        <children/> <!-- children of the importing node will be inserted here -->
    </UIView>
    <UILabel>Shared Footer</UILabel>
</UIView>
```

## Parameters

When using templates, you can configure the root node of the template by setting expressions on the importing node, but this offers rather limited control over customization. Ideally, you want to be able to configure properties of nodes *inside* the template as well, and that's where *parameters* come in.

You define parameters by adding `<param/>` nodes inside an ordinary Layout node:

```xml
<!-- MyTemplate.xml -->
<UIView>
    <param name="text" type="String"/>
    <param name="image" type="UIImage"/>

    <UIImageView image="{image}"/>
    <UILabel text="{text}"/>
</UIView>
```

Each parameter has a `name` and `type` attribute. The parameter defines a symbol that can be referenced by any expression defined on the containing node or any of its children.

Parameters can be set using expressions on the importing node:

```xml
<UIView
    template="MyTemplate.xml"
    text="Lorem ipsum sit dolor "
    image="Rocket.png"
/>
```

You can set default values for parameters by defining a matching expression on the containing node. It will be overridden if the same expression is defined on the importing node:

```xml
<!-- MyTemplate.xml -->
<UIView title="Default text">
    <param name="title" type="String"/>
    ...
</UIView>
```


## Macros

Sometimes you will find yourself repeating the same expression multiple times in a given layout. For example, all the views may have the same width or height, or the same spacing relative to their siblings. For example:

```xml
<UIView>
    <UILabel left="20" right="100% - 20" top="20" text="Foo"/>
    <UILabel left="20" right="100% - 20" top="previous.bottom + 20" text="Bar"/>
    <UILabel left="20" right="100% - 20" top="previous.bottom + 20" text="Baz"/>
</UIView>
```

Although you can pass numeric values into your layout as constants, this doesn't work for expressions like "100%" or "previous.bottom", where the symbols being referenced are relative to the position of the node in the hierarchy, so the actual value will vary in each instance.

Layout has a solution for this, in the form of *macros*. A macro is a reusable expression that you define inside your Layout template. Macros can be referenced by expressions on the node containing them, or any child of that node, but unlike parameters they cannot be set or overridden externally, and their value is determined at the point of use, rather than relative to the node where they are defined.

Using macros, we can change the example above to:

 ```xml
<UIView>
    <macro name="SPACING" value="20"/>
    <macro name="LEFT" value="SPACING"/>
    <macro name="RIGHT" value="100% - SPACING"/>
    <macro name="TOP" value="previous.bottom + SPACING"/>
    
    <UILabel left="LEFT" right="RIGHT" top="TOP" text="Foo"/>
    <UILabel left="LEFT" right="RIGHT" top="TOP" text="Bar"/>
    <UILabel left="LEFT" right="RIGHT" top="TOP" text="Baz"/>
</UIView>
```

This eliminates the repetition, making the layout more DRY, and easier to refactor.

Note the use of UPPERCASE names for the macros - this isn't required, but it's a good way to visually distinguish between macros and ordinary constants, parameters or state variables. It also avoids namespace collisions with existing view properties.


## Ignore File

Every time you load a layout XML file when running in the iOS Simulator, Layout scans your project directory to locate the file. This is usually pretty fast, but if your project has a lot of subfolders then it can take a noticeable time to locate an XML file the first time.

To speed up this scan, you can add a `.layout-ignore` file to your project directory that tells Layout to ignore certain subdirectories. The format of the `.layout-ignore` file is a simple list of file paths (one per line) that should be ignored. You can use `#` to denote a comment, e.g. for grouping purposes:

```
# Ignore these
Tests
Pods
```

File paths are relative to the folder in which the `.layout-ignore` file is placed. Wildcards like `*.xml` are not supported, and the use of relative paths like `../` is not recommended.

Searching begins from the directory containing your `.xcodeproj`, but you can place the `.layout-ignore` file in any subdirectory of your project, and you can include multiple ignore files in different directories.

Layout already ignores invisible files/folders, along with the following directories, so there is no need to include these:

```
build
*.build
*.app
*.framework
*.xcodeproj
*.xcassets
```

The paths listed in `.layout-ignore` will also be ignored by [LayoutTool](#layouttool).


# Example Projects

There are several example projects included with the Layout library:

## SampleApp

The SampleApp project demonstrates a range of Layout features. It is split into four tabs, and the entire project, including the `UITabBarController`, is specified using Layout XML files. The tabs are as follows:

* Boxes - demonstrates use of state to manage an animated layout
* Pages - demonstrates using a `UIScrollView` to create paged content
* Text - demonstrates Layout's text features, include the use of HTML and attributed string constants
* Table - demonstrates Layout's support for `UITableView` and `UITableViewCell`

## UIDesigner

The UIDesigner project is an experimental WYSIWYG tool for constructing layouts. It's written as an iPad app which you can run in the simulator or on a device.

UIDesigner is currently in a very early stage of development. It supports most of the features exposed by the Layout XML format, but lacks import/export, and the ability to specify constants, parameters or outlet bindings.

## Sandbox

The Sandbox app is a simple playground for experimenting with XML layouts. It runs on iPhone or iPad.

Like UIDesigner, the Sandbox app currently lacks any load/save or import/export capability, but you can copy and paste XML to and from the edit screen.


# LayoutTool

The Layout project includes the source code for a command-line app called LayoutTool, which provides some useful functions to help with development using Layout. You do not need to install LayoutTool to use Layout, but you may find it helpful.

## Installation

The latest built binary of LayoutTool is included in the project inside the `LayoutTool` directory, and you can just drag-and-drop it to install.

To ensure compatibility, always update LayoutTool at the same time as updating the Layout framework, because using an old version of LayoutTool to process XML files containing newer features may result in data loss or corruption.

**Note:** The LayoutTool binary is only updated when there are changes that affect its behavior, so don't worry if the version doesn't match exactly.

To automatically install LayoutTool into your project using CocoaPods, add the following to your Podfile:

```ruby
pod 'Layout/CLI'
```

This will install the LayoutTool binary inside the `Pods/Layout/LayoutTool` directory inside your project folder. You can then reference this using other scripts in your project.

## Formatting

The main function provided by LayoutTool is automatic formatting of Layout XML files. The `LayoutTool format` command will find any Layout XML files at the specified path(s) and apply standard formatting. You can use the tool as follows:

```
> LayoutTool format /path/to/xml/file(s) [/another/path]
```

For more information, use `LayoutTool help`.

To automatically apply `LayoutTool format` to your project every time it is built, you can add a Run Script build phase that applies the tool. Assuming you've installed the LayoutTool CLI using CocoaPods, that script will look something like:

```bash
"${PODS_ROOT}/Layout/LayoutTool/LayoutTool" format "${SRCROOT}/path/to/your/layout/xml/"
```

The formatting applied by LayoutTool is specifically designed for Layout files. It is better to use LayoutTool for formatting these files rather than a generic XML-formatting tool.

Conversely, LayoutTool is *only* appropriate for formatting *Layout* XML files. It is not a general-purpose XML formatting tool, and may not behave as expected when applied to arbitrary XML.

LayoutTool ignores XML files that do not appear to belong to Layout, but if your project contains non-Layout XML files then it is a good idea to exclude these paths from the `LayoutTool format` command, to improve formatting performance and avoid accidental false positives.

To safely determine which files the formatting will be applied to, without overwriting anything, you can use `LayoutTool list` to display all the Layout XML files that LayoutTool can find in your project.

## Renaming

LayoutTool also provides a function for renaming classes or expression variables inside one or more Layout XML templates. Use it as follows:

```bash
"${PODS_ROOT}/Layout/LayoutTool/LayoutTool" rename "${SRCROOT}/path/to/your/layout/xml/" oldName newName
```

Only class names and values inside expressions will be affected. Attributes (i.e. expression names) are ignored, along with HTML elements and literal string fragments.

**Note:** Performing a rename also applies standard formatting to the file. There is currently no way to disable this.

## Strings

LayoutTool's `strings` command prints a list of all Localizable.strings constants referenced in your Layout XML templates. Use it as follows:

```bash
"${PODS_ROOT}/Layout/LayoutTool/LayoutTool" strings "${SRCROOT}/path/to/your/layout/xml/"
```


# Xcode Extension

If you are writing Layout XML inside Xcode, you may wish to install the Layout Xcode Editor Extension, which provides a subset of [LayoutTool]'s functionality directly inside the Xcode IDE.

## Installation

The latest built binary of Layout for Xcode is included in the project inside the `EditorExtension` directory, and you can just drag-and-drop it to your Applications folder to install.

Once installed, run the Layout for Xcode app and follow the on-screen instructions.

To ensure compatibility, always update the Layout for Xcode app at the same time as updating the Layout framework, because using an old version of Layout for Xcode to format XML files containing newer features may result in data loss or corruption.

**Note:** The Layout for Xcode app is only updated when there are changes that affect its behavior, so don't worry if the version doesn't match exactly.

## Formatting

When you have a Layout XML file open in Xcode, select the `Editor > Layout > Format XML` menu to reformat the file.


# FAQ

*Q. How is this different from frameworks like [React Native](https://facebook.github.io/react-native/)?*

> React Native is a complete x-platform replacement for native iOS and Android development, whereas Layout is a way to build ordinary iOS UIKit apps more easily. In particular, Layout has much tighter integration with native UIKit controls, requires less boilerplate to use custom controls, and works directly with your existing native Swift code.

*Q. How is this different from frameworks like [Render](https://github.com/alexdrone/Render)?*

> The programming model is very similar, but Layout's runtime expression language means that you can do a larger proportion of your UI development without needing to restart the Simulator.

*Q. Does Layout use Flexbox?*

> No. Layout requires you to position each view explicitly using top/left/width/height properties, but its percentage-based units and auto-sizing feature make it easy to create complex layouts with minimal code. You can also use iOS's native flexbox-style `UIStackView` within your Layout templates.

*Q. Why does Layout use XML instead of a more modern format like JSON?*

> XML is better suited to representing document-like structures such as view hierarchies. JSON does not distinguish between node types, attributes, and children in its syntax, which leads to a lot of extra verbosity when representing hierarchical structures because each node must include keys for "type" and "children", or equivalent. JSON also doesn't support comments, which are useful in complex layouts. While XML isn't perfect, it is the most appropriate of the formats that iOS has built-in support for.

*Q. Do I really have to write my layouts in XML?*

> You can create `LayoutNode`s manually in code, but XML is the recommended approach for now since it makes it possible to use the live reloading feature.

*Q. Is Layout App Store-safe? Has it been used in production?*

> Yes, we have submitted apps using Layout to the App Store, and they have been approved without issue.

*Q. Which platforms are supported?*

> Layout works on iOS 9.0 and above. There is currently no support for other Apple OSes (tvOS, watchOS, macOS), nor competing platforms such as Android or Windows.

*Q. Will Layout ever support watchOS/tvOS?*

> There are no plans at the moment, but it should be fairly simple to add support for iOS-derivative platforms. If you need this, please create a pull request with whatever changes are required to make Layout build on those platforms.

*Q. Will Layout ever support macOS/AppKit?*

> There are no plans at the moment, but this would make sense in future given the shared language and similar frameworks. If you are interested in implementing such a feature, please create an issue on GitHub to discuss the approach.

*Q. Will Layout ever support Android/Windows?*

> There are no plans to port Layout to other platforms at the moment. Android and Windows in particular already use a human-readable XML format for their view templates, which eliminates some of the need for a Layout-like replacement.

*Q. Why isn't Cmd-R reloading my XML file in the simulator?*

> Make sure that the `Hardware > Keyboard > Connect Hardware Keyboard` option is enabled in the simulator.

*Q. Why do I get an error saying my custom view class isn't recognized?*

> Read the [Namespacing](#namespacing) section above.

*Q. Why do I get an error when trying to set a property of my custom component?*

> Read the [Custom Property Types](#custom-property-types) section above.

*Q. Do I have to use a `UIViewController` subclass load my layout?*

> No. See the [Advanced Topics](#advanced-topics) section above.

*Q. When I launched my app, Layout asked me to select a source file and I chose the wrong one, now my app isn't working correctly. What do I do?*

> If the app runs OK, or displays a Red Box, you can reset it with Cmd-Alt-R. If it's actually crashing, the best option is to delete the app from the Simulator then re-install it.
