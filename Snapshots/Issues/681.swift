someController = SomeController(action: { [unowned self] in
                                    self.value = true; self.actionCalled()
                                },
                                otherParameter: parameter)
