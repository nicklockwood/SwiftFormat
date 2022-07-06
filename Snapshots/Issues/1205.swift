private extension FooOperator {
    var op: ((Double, Double) -> Double)? {
        switch self {
        case .unknown:
            return nil
        case .add:
            return (+)
        case .subtract:
            return (-)
        case .multiply:
            return (*)
        case .divide:
            return (/)
        }
    }
}
