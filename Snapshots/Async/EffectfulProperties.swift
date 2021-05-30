var contents: String {
    get async throws {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            throw FileError.missing
        }

        do {
            return try String(contentsOf: url)
        } catch {
            throw FileError.unreadable
        }
    }
}
