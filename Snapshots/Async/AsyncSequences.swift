func printAllDoubles() async {
    for await number in DoubleGenerator() {
        print(number)
    }
}

func containsExactNumber() async {
    let doubles = DoubleGenerator()
    let match = await doubles.contains(16_777_216)
    print(match)
}
