func forcedSelection(for list: [Value], current selection: UserSelection<Value>) -> UserSelection<Value> {
    switch (list.count, list.first) {
    case (_, nil),
         (0, _):
        return .none
    case let (1, selection?):
        return .single(selection)
    default:
        return selection
    }
}
