actor SafeCollector {
    var deck: Set<String>

    init(deck: Set<String>) {
        self.deck = deck
    }

    func send(card selected: String, to person: SafeCollector) async -> Bool {
        guard deck.contains(selected) else { return false }

        deck.remove(selected)
        await person.transfer(card: selected)
        return true
    }

    func transfer(card: String) {
        deck.insert(card)
    }
}

class NewDataController {
    @MainActor func save() {
        print("Saving data…")
    }
}
