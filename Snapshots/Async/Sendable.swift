func runLater(_ function: @escaping @Sendable () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: function)
}
