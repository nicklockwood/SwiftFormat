// swiftformat:options --allman true

func foo()
{
    return SessionManager
        .shared
        .validateSession()
        .switchMap
        { _ -> Observable<SomeEntity> in
            someCode()
        }
        .switchMap
        {
            otherCode()
        }
}

SessionManager
    .shared
    .validateSession()
    .switchMap
    { _ -> Observable<SomeEntity> in
        someCode()
    }
    .switchMap
    {
        otherCode()
    }

// swiftformat:options --allman false

SessionManager
    .shared
    .validateSession()
    .switchMap { _ -> Observable<SomeEntity> in
        someCode()
    }
    .switchMap {
        otherCode()
    }
