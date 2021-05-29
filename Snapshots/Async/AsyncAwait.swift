func processWeather() async {
    let records = await fetchWeatherHistory()
    let average = await calculateAverageTemperature(for: records)
    let response = await upload(result: average)
    print("Server response: \(response)")
}

enum UserError: Error {
    case invalidCount, dataTooLong
}

func fetchUsers(count: Int) async throws -> [String] {
    if count > 3 {
        // Don't attempt to fetch too many users
        throw UserError.invalidCount
    }

    // Complex networking code here; we'll just send back up to `count` users
    return Array(["Antoni", "Karamo", "Tan"].prefix(count))
}

func save(users: [String]) async throws -> String {
    let savedUsers = users.joined(separator: ",")

    if savedUsers.count > 32 {
        throw UserError.dataTooLong
    } else {
        // Actual saving code would go here
        return "Saved \(savedUsers)!"
    }
}

func updateUsers() async {
    do {
        let users = try await fetchUsers(count: 3)
        let result = try await save(users: users)
        print(result)
    } catch {
        print("Oops!")
    }
}
