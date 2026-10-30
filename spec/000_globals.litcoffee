DSCommon code everywhere relies on the following assumptions:
- Global Promise is implemented by the bluebird library

    {Result, compareStructures, utils: {err: {isResult}}} = require '../src'

    beforeEach ->

      Error.stackTraceLimit = 30;

To verify that a Result object contains specific messages, we define a custom matcher

      jasmine.addMatchers

        resultContains: (util, customEqualityTesters) ->

          compare: (actual, expected) ->

            # check that actual is of the correct type

            unless isResult actual

              return {

                pass: false

                message: "Expected actual value to be a Result object, but it was '#{jasmine.pp actual}'."}

            # check that it is an array

            unless (failed = not Array.isArray expected)

              failed = true for v in expected when not (typeof v == 'object' && v != null)

            if failed

              return {

                pass: false

                message: "Expected actual value to be an array of Result messages, but it is '#{jasmine.pp expected}'."}

            # search among the received messages so that every expected message is present

            for expectedMessage in expected

              pass = false

              pass = true for actualMessage in actual.messages when util.equals expectedMessage, actualMessage, customEqualityTesters

              (missingMessages = []).push expectedMessage unless pass

            if missingMessages # compare: (actual, expected) ->

              pass: false

              # message: "Expected #{nodeJSUtil.inspect actual.messages} to has following messages #{nodeJSUtil.inspect missingMessages}"

              message: "Expected #{jasmine.pp actual.messages} to has following messages #{jasmine.pp missingMessages}."

            else

              pass: true

        sameStructure: (util, customEqualityTesters) ->

          compare: (actual, expected) ->

            compareStructures (result = new Result), actual, expected

            if result.messages.length > 0

              pass: false

              # message: "Diff: #{jasmine.pp result.messages}"
              message: "Diff: #{jasmine.pp result.messages};\n Actual: '#{jasmine.pp actual}';\n Expected: '#{jasmine.pp expected}'"

            else

              pass: true
