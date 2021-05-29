func printUserDetails() async {
    async let username = getUser()
    async let scores = getHighScores()
    async let friends = getFriends()

    let user = await UserData(name: username, friends: friends, highScores: scores)
    print("Hello, my name is \(user.name), and I have \(user.friends.count) friends!")
}

enum NumberError: Error {
    case outOfRange
}

func fibonacci(of number: Int) async throws -> Int {
    if number < 0 || number > 22 {
        throw NumberError.outOfRange
    }

    if number < 2 { return number }
    async let first = fibonacci(of: number - 2)
    async let second = fibonacci(of: number - 1)
    return try await first + second
}
