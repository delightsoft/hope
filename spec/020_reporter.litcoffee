reporter
==============================

Reporter and Result solve a very similar task - outputting messages.  The difference is that Result accumulates messages,
but does not output them anywhere itself.  And Reporter outputs messages as they arrive.  In particular, it can output
messages from a Result

All messages about found errors and warnings about possible errors are issued through the reporter method.

    {Result, Reporter, i18n} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '020_reporter:', ->

A Reporter object can work without localization, which is useful in the development process

      check "A", ->

        reporter = new Reporter

        reporter._print = jasmine.createSpy 'reporter.print'

Messages can be of three types:
* error - an error
* warn - a warning
* info - information

        reporter.error 'test.sampleMessage'
        reporter.warn 'test.sampleMessage2', a: 12
        reporter.info 'test.sampleMessage3', b: 'test', c: false

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'test.sampleMessage']
          ['warn', 'test.sampleMessage2{"a":12}']
          ['info', 'test.sampleMessage3{"b":"test","c":false}']
        ]

        reporter._print.calls.reset()

But the standard mode is working with localization

      check "B", ->

Set up a test localization

        messages =

          dsc:

            messageA: (args) -> "Message A: Val: #{args.value}"

            messageB: 'simple message'

Translate the configuration into its working version via the link operation

        messages = i18n.link (result = new Result), messages

        expect(result.isError).toBeFalsy()

Create a report object with the localization from config

        reporter = new Reporter messages

Add the method through which the output happens

        reporter._print = jasmine.createSpy 'reporter.print'

Output several messages

        reporter.info 'dsc.messageA', value: null

        reporter.error 'dsc.messageB'

        reporter.warn 'dsc.messageC', a: 12, s: 'test'

Check that all messages arrived at reporter._print in the expected form

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['info', 'Message A: Val: null']
          ['error', 'simple message']
          ['warn', 'dsc.messageC{"a":12,"s":"test"}']
        ]

Reset _print for the next test

        reporter._print.calls.reset()

Output of a result
------------------------------

        result = new Result

        result.log 'error', 'dsc.messageA', value: 121
        result.log 'info', 'dsc.messageB'

        reporter.logResult result

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'Message A: Val: 121']
          ['info', 'simple message']
        ]

        reporter._print.calls.reset()

Output of a result with context
------------------------------

        field = 'Field1'

        result = new Result (path) -> (Result.prop field) path

        result.log 'error', 'dsc.messageA', value: 'test'

        field = 'Field2'

        result.log 'info', 'dsc.messageB'

        reporter.logResult result

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'Field1: Message A: Val: test']
          ['info', 'Field2: simple message']
        ]

        reporter._print.calls.reset()

And now also with the name of the action

        reporter.logResult result, 'dsc.messageA', value: 111

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'Message A: Val: 111']
          ['error', 'Field1: Message A: Val: test']
          ['info', 'Field2: simple message']
        ]

        reporter._print.calls.reset()

Reporter must be indistinguishable from Result when working with context and outputting messages
------------------------------

      check 'Resport has same interface as Result (1)', ->

        reporter = new Reporter

        reporter._print = jasmine.createSpy 'reporter.print'

        reporter.context (Result.prop 'testProp'), ->

          reporter.error 'dsc.errMsg', value: 100

          reporter.warn 'dsc.warnMsg', value: 50

          reporter.info 'dsc.infoMsg', value: 10

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'testProp: dsc.errMsg{"value":100}']
          ['warn', 'testProp: dsc.warnMsg{"value":50}']
          ['info', 'testProp: dsc.infoMsg{"value":10}']
        ]

      check 'Resport has same interface as Result (2)', ->

        reporter = new Reporter

        reporter._print = jasmine.createSpy 'reporter.print'

        reporter.error Result.prop('testProp'), 'dsc.errMsg', value: 100

        reporter.warn Result.prop('testProp'), 'dsc.warnMsg', value: 50

        reporter.info Result.prop('testProp'), 'dsc.infoMsg', value: 10

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'testProp: dsc.errMsg{"value":100}']
          ['warn', 'testProp: dsc.warnMsg{"value":50}']
          ['info', 'testProp: dsc.infoMsg{"value":10}']
        ]

      check "contextResport has same interface as Result (3): keep errors", ->

        reporter = new Reporter

        reporter._print = jasmine.createSpy 'reporter.print'

        (result = reporter).context (->), ->

          result.error 'someError'

          expect(result.isError).toBe true # ###

          # When entering the context, isError is reset to false

          result.context (->), ->

            expect(result.isError).toBe false

          # When exiting, the presence of the error is restored

          expect(result.isError).toBe true

          result.isError = false

        expect(result.isError).toBe true # ###

