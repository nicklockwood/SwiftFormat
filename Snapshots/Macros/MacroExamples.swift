// From https://github.com/DougGregor/swift-macro-examples/blob/main/MacroExamples/main.swift
// swiftformat:options --indent 2

import Foundation
import MacroExamplesLib

let x = 1
let y = 2
let z = 3

// "Stringify" macro turns the expression into a string.
print(#stringify(x + y))

// "AddBlocker" complains about addition operations. We emit a warning
// so it doesn't block compilation.
print(#addBlocker(x * y + z))

#myWarning("remember to pass a string literal here")

// Uncomment to get an error out of the macro.
// let text = "oops"
// #myWarning(text)

struct Font: ExpressibleByFontLiteral {
  init(fontLiteralName _: String, size _: Int, weight _: MacroExamplesLib.FontWeight) {}
}

let _: Font = #fontLiteral(name: "Comic Sans", size: 14, weight: .thin)

// "#URL" macro provides compile time checked URL construction. If the URL is
// malformed an error is emitted. Otherwise a non-optional URL is expanded.
print(#URL("https://swift.org/"))

let domain = "domain.com"
// print(#URL("https://\(domain)/api/path")) // error: #URL requires a static string literal
// print(#URL("https://not a url.com")) // error: Malformed url

// Use the "wrapStoredProperties" macro to deprecate all of the stored
// properties.
@wrapStoredProperties(#"available(*, deprecated, message: "hands off my data")"#)
struct OldStorage {
  var x: Int
}

// The deprecation warning below comes from the deprecation attribute
// introduced by @wrapStoredProperties on OldStorage.
_ = OldStorage(x: 5).x

// Move the storage from each of the stored properties into a dictionary
// called `_storage`, turning the stored properties into computed properties.
@DictionaryStorage
struct Point {
  var x: Int = 1
  var y: Int = 2
}

@CaseDetection
enum Pet {
  case dog
  case cat(curious: Bool)
  case parrot
  case snake
}

let pet: Pet = .cat(curious: true)
print("Pet is dog: \(pet.isDog)")
print("Pet is cat: \(pet.isCat)")

var point = Point()
print("Point storage begins as an empty dictionary: \(point)")
print("Default value for point.x: \(point.x)")
point.y = 17
print("Point storage contains only the value we set:  \(point)")

// MARK: - ObservableMacro

struct Treat {}

@Observable
final class Dog {
  var name: String?
  var treat: Treat?

  var isHappy: Bool = true

  init() {}

  func bark() {
    print("bork bork")
  }
}

let dog = Dog()
print(dog.name ?? "")
dog.name = "George"
dog.treat = Treat()
print(dog.name ?? "")
dog.bark()

// MARK: NewType

@NewType(String.self)
struct Hostname:
  NewTypeProtocol,
  Hashable,
  CustomStringConvertible
{}

@NewType(String.self)
struct Password:
  NewTypeProtocol,
  Hashable,
  CustomStringConvertible
{
  var description: String { "(redacted)" }
}

let hostname = Hostname("localhost")
print("hostname: description=\(hostname) hashValue=\(hostname.hashValue)")

let password = Password("squeamish ossifrage")
print("password: description=\(password) hashValue=\(password.hashValue)")

struct MyStruct {
  @AddCompletionHandler
  func f(a _: Int, for b: String, _: Double) async -> String {
    b
  }

  @AddAsync
  func c(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Result<String, Error>) -> Void) {
    completionBlock(.success("a: \(a), b: \(b), value: \(value)"))
  }

  @AddAsync
  func d(a _: Int, for _: String, _: Double, completionBlock: @escaping (Bool) -> Void) {
    completionBlock(true)
  }
}

@CustomCodable
struct CustomCodableString: Codable {
  @CodableKey(name: "OtherName")
  var propertyWithOtherName: String

  var propertyWithSameName: Bool

  func randomFunction() {}
}

Task {
  let myStruct = MyStruct()
  let a = try? await myStruct.c(a: 5, for: "Test", 20)

  await myStruct.d(a: 10, for: "value", 40)
}

MyStruct().f(a: 1, for: "hello", 3.14159) { result in
  print("Eventually received \(result + "!")")
}

let json = """
{
  "OtherName": "Name",
  "propertyWithSameName": true
}

""".data(using: .utf8)!

let jsonDecoder = JSONDecoder()
let product = try jsonDecoder.decode(CustomCodableString.self, from: json)
print(product.propertyWithOtherName)

@MyOptionSet<UInt8>
enum ShippingOptions {
  private enum Options: Int {
    case nextDay
    case secondDay
    case priority
    case standard
  }

  static let express: ShippingOptions = [.nextDay, .secondDay]
  static let all: ShippingOptions = [.express, .priority, .standard]
}

// `@MetaEnum` adds a nested enum called `Meta` with the same cases, but no
// associated values/payloads. Handy for e.g. describing a schema.
@MetaEnum enum Value {
  case integer(Int)
  case text(String)
  case boolean(Bool)
  case null
}

print(Value.Meta(.integer(42)) == .integer)
