func typeMismatch(
    for symbol: String,
    index: Int,
    expected types: [String],
    got: String
) -> RuntimeErrorType {
    var types = Set(types).sorted()
    if let index = types.firstIndex(of: "block") {
        types.append(types.remove(at: index))
    }
    let expected: String
    switch types.count {
    case 1:
        expected = types[0]
    case 2:
        expected = "\(types[0]) or \(types[1])"
    default:
        expected = "\(types.dropLast().joined(separator: ", ")), or \(types.last!)"
    }
    return .typeMismatch(for: symbol, index: index, expected: expected, got: got)
}
