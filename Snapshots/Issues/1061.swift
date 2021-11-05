// swiftformat:options --indent 4
// swiftformat:options --xcodeindentation disabled
// swiftformat:options --self init-only
// swiftformat:options --stripunusedargs closure-only
// swiftformat:options --commas inline
// swiftformat:options --wraparguments before-first
// swiftformat:options --wrapcollections before-first

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func handleGenericError(_ error: Error) {
        if let requestableError = error as? RequestableError,
           case let .underlying(error as NSError) = requestableError, // <--- throws error about missing '{' here
           error.code == NSURLErrorNotConnectedToInternet
        {
            print("Error handled")
        } else {
            showGenericError()
        }
    }

    private func errorMessageStringForError(_ error: Error?) -> String {
        let errorMessage: String
        // Get error message for statusCode error, Othrewise return generic error
        if let requestableError = error as? RequestableError, // <--- throws error about missing '{' here
           case let .statusCode(statusCode, _, _, error as GenericResponseError) = requestableError
        {
            print(error)
            print(statusCode)
            errorMessage = "errorMessageStringForErrorCode(status: statusCode, code: error.intCode)"
        } else {
            errorMessage = "systemUnavailable"
        }
        return errorMessage
    }
}
