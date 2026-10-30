result
==============================

For working with errors (error) and warnings (warnings) we have a special class Result

    {Result, utils: {err: {_argError}}} = require '../src'

    focusOnCheck = ""


    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '010_result:', ->

Result objects allow accumulating metadata about messages.  The metadata includes:
* type - the type of the message: error, warn or info
* code - the code of the message.  A string containing the message code, with the namespace
* args - the arguments of the message.  An optional parameter

      check "simple result", ->

        result = new Result

Messages can be of three types:
* error - an error
* warn - a warning
* info - information

        result.error 'test.sampleMessage'
        result.warn 'test.sampleMessage2', a: 12
        result.info 'test.sampleMessage3', b: 'test', c: false

All messages are accumulated into the messages array

        expect(result.messages).sameStructure [
          {type: 'error', code: 'test.sampleMessage'}
          {type: 'warn', code: 'test.sampleMessage2', a: 12}
          {code: 'test.sampleMessage3', b: 'test', c: false}
        ]

Several Result objects can be combined into one

      check "combine results", ->

We create a root Result object, and for the test we immediately add a message to it

        result = new Result
        result.info 'test.rootMessage'

        expect(result.isError).toBeFalsy()
        expect(result.messages).sameStructure [
          {code: 'test.rootMessage'}
        ]

Suppose that a method returned another result object, containing in particular errors

        resultA = new Result
        resultA.error 'test.sampleMessage'
        resultA.warn 'test.sampleMessage2'

        expect(resultA.isError).toBeTruthy()
        expect(resultA.messages).sameStructure [
          {type: 'error', code: 'test.sampleMessage'}
          {type: 'warn', code: 'test.sampleMessage2'}
        ]

When combining, all messages from the result returned by the method are added to the root Result

        result.add resultA

        expect(result.isError).toBeTruthy()
        expect(result.messages).sameStructure [
          {code: 'test.rootMessage'}
          {type: 'error', code: 'test.sampleMessage'}
          {type: 'warn', code: 'test.sampleMessage2'}
        ]

For uniformity, an object of class Result is passed as the first parameter to methods, so that the methods can report the errors they find through it

      check "result as first argument", (done) ->

        sampleMethod = (result, arg1) ->

          new Promise (resolve, reject) ->

            if arg1 != 'good'

              result.error 'invalidArg', arg: 'arg1', value: arg1

              reject(); return

            resolve()

            return # new Promise

        c = 2

Successful call

        goodResult = new Result

        sampleMethod goodResult, 'good'
        .then ->

          expect(goodResult.isError).toBeFalsy()
          expect(goodResult.messages).sameStructure []

          done() if --c == 0

          return

Call with an error in the result

        badResult = new Result

        sampleMethod badResult, 'bad'
        .then (-> return), ->

          expect(badResult.isError).toBeTruthy()
          expect(badResult.messages).sameStructure [{type: 'error', code: 'invalidArg', arg: 'arg1', value: 'bad'}]

          done() if --c == 0

          return

pathFunc
------------------------------

To be able to bind a message to a specific element of the tree, one can save a pathFunc along with the message.

For this we create a Result object, into which we pass a function that returns the current context when needed

      check "pathFunc", ->

        field = 'field1'

        result = new Result (path) -> (Result.prop field) path

We add an error while the pathFunc function returns `{type: 'field', fld: 'field 1'}`

        result.error 'test.fieldError'

        field = 'field2'

We add an error while the pathFunc function returns `{type: 'field', fld: 'field 2'}`

        result.error 'test.fieldError'

And we get the list of messages with the saved contexts

        expect(result.messages).sameStructure [
          {type: 'error', path: 'field1', code: 'test.fieldError'}
          {type: 'error', path: 'field2', code: 'test.fieldError'}
        ]

There can be several contexts

        prop = 'A'

        [oldContext, result.pathFunc] = [result.pathFunc, (path) -> (Result.prop prop, oldContext) path]

        result.error 'test.fieldError'

        prop = 'B'

        result.error 'test.fieldError'

        result.pathFunc = oldContext

        result.error 'test.fieldError'

As a result, while the second context is present, a list of contexts is made in the result

        expect(result.messages).sameStructure [
          {type: 'error', path: 'field1', code: 'test.fieldError'}
          {type: 'error', path: 'field2', code: 'test.fieldError'}
          {type: 'error', path: 'field2.A', code: 'test.fieldError'}
          {type: 'error', path: 'field2.B', code: 'test.fieldError'}
          {type: 'error', path: 'field2', code: 'test.fieldError'}
        ]

For multi-step processing it is necessary to create a separate Result for each step.  But at the same time it is important that the
pathFunc of the original Result is carried over into this result.  If another Result is passed as the parameter for the new Result, then the messages
are saved into the new result

      check "copy result.pathFunc to localResult",  ->

        field = 'fieldA'

        result = new Result fldPathFunc = (path) -> (Result.prop field) path

        expect(result.isError).toBe false

        localResult = new Result result

        expect(localResult.pathFunc).toBe result.pathFunc

        expect(localResult.isError).toBe false

        localResult.error 'test.fieldError'

        expect(result.isError).toBe false

        expect(localResult.isError).toBe true

        prop = 'propA'

        [oldContext, localResult.pathFunc] = [localResult.pathFunc, subPathFunc = ((path) -> (Result.prop prop, oldContext) path)]

        localResult.error 'test.fieldError'

        expect(result.pathFunc).sameStructure fldPathFunc

        expect(localResult.pathFunc).sameStructure subPathFunc

        expect(localResult.isError).toBe true

        expect(localResult.messages).sameStructure [
          {type: 'error', path: 'fieldA', code: 'test.fieldError'}
          {type: 'error', path: 'fieldA.propA', code: 'test.fieldError'}
        ]

We check that an exception is returned if the parameter is not correct

      for errValue in [true, false, 12, 'str', {}, []]

        do (errValue) -> check "error: invalid parameter: #{errValue}", ->

          expect(-> new Result errValue).toThrow _argError 'Invalid argument', 'pathFuncOrResult', errValue

      check "add path to message as parameter", ->

        result = new Result

        expect(result.log 'error', (Result.prop 'propA'), 'dsc.code').sameStructure
          type: 'error'
          path: 'propA'
          code: 'dsc.code'

        expect(result.error (Result.prop 'propA'), 'dsc.code').sameStructure
          type: 'error'
          path: 'propA'
          code: 'dsc.code'

        expect(result.info (Result.index 20, Result.prop 'propA'), 'dsc.code', v: 20).sameStructure
          path: 'propA[20]'
          code: 'dsc.code'
          v: 20

        expect(result.warn (Result.prop 'D', Result.prop 'propA'), 'dsc.code', v: 20).sameStructure
          type: 'warn'
          path: 'propA.D'
          code: 'dsc.code'
          v: 20

context
------------------------------

For nested processing of elements, one must be able to process each level, knowing which element
is being processed.  If an error occurred at the nested level, it will be visible also when exiting the nested context at
the level above, even if inside the nested context isResult was reset to false.

      check "context: keep errors", ->

        (result = new Result).context (->), ->

          result.error 'someError'

          expect(result.isError).toBe true

When entering context isError is reset to false

          result.context (->), ->

            expect(result.isError).toBe false

When exiting, the presence of the error is restored

          expect(result.isError).toBe true

          result.isError = false

        expect(result.isError).toBe true

empty context
------------------------------

For nested processing, when there is no real context, the result.context method can be called without the first parameter

      check "empty context: keep errors", ->

        (result = new Result).context  ->

          result.error 'someError'

          expect(result.isError).toBe true

When entering context isError is reset to false

          result.context ->

            expect(result.isError).toBe false

When exiting, the presence of the error is restored

          expect(result.isError).toBe true

          result.isError = false

        expect(result.isError).toBe true
