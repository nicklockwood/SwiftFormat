.update(
    a, { _ in
        s(…) // …
    }
)

func a(s: String) -> JSON {
    return Data(s).utf8
}

func b(status: String, payload: String) -> String {
    return "\"data\": {\n\(status),\n\(payload)\n}"
}

let somethingReallyReallyLongJson = a(s: b(status: """
                                           "status": {
                                              "success": [],
                                              "error": []
                                           }
                                           """,
                                           """
                                           "payload": {
                                              "header": "<h1>",
                                              "div": "<div>"
                                           }
                                           """)
)
