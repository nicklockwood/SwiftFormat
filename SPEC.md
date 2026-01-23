# `--ifdef no-indent` Specification

This document specifies the expected behavior of the `--ifdef no-indent` option for SwiftFormat.

## Core Principle

With `no-indent`, the content inside `#if`/`#else`/`#elseif`/`#endif` blocks should be at the **same indentation level** as the `#if` directive itself. No extra indentation is added for being "inside" the conditional block.

## Scenarios

### 1. Basic `#if` block at scope level

**Before:**
```swift
func foo() {
    #if DEBUG
        print("debug")
    #endif
}
```

**After:**
```swift
func foo() {
    #if DEBUG
    print("debug")
    #endif
}
```

### 2. `#if` with `#else`

**Before:**
```swift
func foo() {
    #if DEBUG
        print("debug")
    #else
        print("release")
    #endif
}
```

**After:**
```swift
func foo() {
    #if DEBUG
    print("debug")
    #else
    print("release")
    #endif
}
```

### 3. `#if` with `#elseif`

**Before:**
```swift
func foo() {
    #if os(iOS)
        print("iOS")
    #elseif os(macOS)
        print("macOS")
    #else
        print("other")
    #endif
}
```

**After:**
```swift
func foo() {
    #if os(iOS)
    print("iOS")
    #elseif os(macOS)
    print("macOS")
    #else
    print("other")
    #endif
}
```

### 4. `#if` in method chain (after closing brace)

**Before:**
```swift
var body: some View {
    VStack {
        Text("Hello")
    }
    #if os(iOS)
        .padding()
    #endif
}
```

**After:**
```swift
var body: some View {
    VStack {
        Text("Hello")
    }
    #if os(iOS)
    .padding()
    #endif
}
```

### 5. `#if` in method chain (inline with modifiers)

**Before:**
```swift
var body: some View {
    Text("Hello")
        .font(.title)
        #if os(iOS)
            .padding()
        #endif
}
```

**After:**
```swift
var body: some View {
    Text("Hello")
        .font(.title)
        #if os(iOS)
        .padding()
        #endif
}
```

### 6. `#if` already at correct level (no change)

**Before:**
```swift
var body: some View {
    Text("Hello")
        .font(.title)
        #if os(iOS)
        .padding()
        #endif
}
```

**After:**
```swift
var body: some View {
    Text("Hello")
        .font(.title)
        #if os(iOS)
        .padding()
        #endif
}
```

### 7. Under-indented `#if` gets fixed

**Before:**
```swift
func foo() {
#if DEBUG
print("debug")
#endif
}
```

**After:**
```swift
func foo() {
    #if DEBUG
    print("debug")
    #endif
}
```

### 8. `#if` wrapping switch cases

**Before:**
```swift
switch value {
case .a:
    break
#if DEBUG
    case .b:
        break
#endif
}
```

**After:**
```swift
switch value {
case .a:
    break
#if DEBUG
case .b:
    break
#endif
}
```

### 9. `#if` with `indentCase: true`

**Before:**
```swift
switch value {
    case .a:
        break
    #if DEBUG
        case .b:
            break
    #endif
}
```

**After:**
```swift
switch value {
    case .a:
        break
    #if DEBUG
    case .b:
        break
    #endif
}
```

### 10. Nested `#if` blocks

**Before:**
```swift
func foo() {
    #if os(iOS)
        #if DEBUG
            print("iOS debug")
        #endif
    #endif
}
```

**After:**
```swift
func foo() {
    #if os(iOS)
    #if DEBUG
    print("iOS debug")
    #endif
    #endif
}
```

### 11. `#if` with multiple statements

**Before:**
```swift
func foo() {
    #if DEBUG
        let x = 1
        let y = 2
        print(x + y)
    #endif
}
```

**After:**
```swift
func foo() {
    #if DEBUG
    let x = 1
    let y = 2
    print(x + y)
    #endif
}
```

### 12. `#if` in method chain with multiple modifiers

**Before:**
```swift
var body: some View {
    Text("Hello")
        #if os(iOS)
            .font(.title)
            .foregroundColor(.blue)
            .padding()
        #elseif os(macOS)
            .font(.headline)
            .padding(.all, 20)
        #endif
}
```

**After:**
```swift
var body: some View {
    Text("Hello")
        #if os(iOS)
        .font(.title)
        .foregroundColor(.blue)
        .padding()
        #elseif os(macOS)
        .font(.headline)
        .padding(.all, 20)
        #endif
}
```

### 13. `#if` after method chain continues

**Before:**
```swift
var body: some View {
    Text("Hello")
        .font(.title)
        #if os(iOS)
            .padding()
        #endif
        .background(Color.white)
}
```

**After:**
```swift
var body: some View {
    Text("Hello")
        .font(.title)
        #if os(iOS)
        .padding()
        #endif
        .background(Color.white)
}
```

### 14. `#if` at file scope

**Before:**
```swift
#if DEBUG
    let debugMode = true
#else
    let debugMode = false
#endif
```

**After:**
```swift
#if DEBUG
let debugMode = true
#else
let debugMode = false
#endif
```

### 15. `#if` wrapping entire type members

**Before:**
```swift
struct Foo {
    #if DEBUG
        var debugValue: Int
    #endif

    var normalValue: String
}
```

**After:**
```swift
struct Foo {
    #if DEBUG
    var debugValue: Int
    #endif

    var normalValue: String
}
```

### 16. `#if` with comments inside

**Before:**
```swift
func foo() {
    #if DEBUG
        // This is a debug comment
        print("debug")
    #endif
}
```

**After:**
```swift
func foo() {
    #if DEBUG
    // This is a debug comment
    print("debug")
    #endif
}
```

### 17. `#if` preserves position when at linewrap level

**Before:**
```swift
var body: some View {
    Text("Hello")
        #if os(iOS)
        .padding()
        #endif
}
```

**After (no change - already correct):**
```swift
var body: some View {
    Text("Hello")
        #if os(iOS)
        .padding()
        #endif
}
```

### 18. Complex nested view with `#if`

**Before:**
```swift
var body: some View {
    HStack {
        List {
            Text("Item")
        }
        .listStyle(.plain)
        #if os(iOS)
            .introspect(.list, on: .iOS(.v15)) { _ in }
        #elseif os(macOS)
            .introspect(.list, on: .macOS(.v12)) { _ in }
        #endif
    }
}
```

**After:**
```swift
var body: some View {
    HStack {
        List {
            Text("Item")
        }
        .listStyle(.plain)
        #if os(iOS)
        .introspect(.list, on: .iOS(.v15)) { _ in }
        #elseif os(macOS)
        .introspect(.list, on: .macOS(.v12)) { _ in }
        #endif
    }
}
```

## Summary

| Scenario | `#if` position | Content position |
|----------|---------------|------------------|
| At scope level | Stays at scope level | Same as `#if` |
| Under-indented | Fixed to scope level | Same as `#if` |
| In method chain (linewrap) | Stays at linewrap level | Same as `#if` |
| Over-indented content | N/A | Dedented to match `#if` |

## Comparison with other modes

| Mode | `#if` behavior | Content behavior |
|------|---------------|------------------|
| `indent` | At scope level | Indented one level from `#if` |
| `no-indent` | Preserved if valid, fixed if under-indented | Same level as `#if` |
| `outdent` | Pushed to column 0 | Preserved |
| `preserve` | Preserved exactly | Preserved exactly |
