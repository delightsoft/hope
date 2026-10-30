Testing network connections requires that the code handling the event be written first, and only then can the
operation under test be performed.  However, for specifications we need to write what we do, and only afterwards
what we get.

This class solves this problem by splitting the specification steps into a part - what we want to do (action), and a
part - what we expect (expect).  And these parts are executed in reverse order - expect first, then action.

Since expect often involves waiting for a signal to arrive, we can pass several callback methods, and
the expect method is considered complete only if all the callback methods have been called.

    process = require 'process'

    class SpecSteps

For debugging a specification, it is useful to set debug to true - then you can see at which step a test got stuck (did not call done).

      constructor: (@context, @done, @debug) ->

        @steps = []

Since all steps are defined within a single function call, it makes sense to start the execution process on the next tick.

        process.nextTick =>
          @_packStep() if @_action
          @_executeStep 1
        
        @_action = @_expects = null
        
Steps are added to the test through a chain of calls to the step method.

      _packStep: ->
        if @_expects == null
          @step @_action
        else
          @step action: @_action, expect: @_expects
        @_action = @_expects = null
    
      action: (action) ->
        @_packStep() if @_action
        @_action = action
        @
        
      _addExpect: (expect) ->
        (@_expects ?= []).push expect
    
      step: (arg) ->

        if typeof arg == 'object'
          throw new Error 'Invalid \'arg\'' unless arg != null
          for k, v of arg
            throw new Error "Unexpected 'arg.#{k}' in #{arg}" unless k == 'action' || k == 'expect'
            throw new Error "Invalid 'arg.#{k}': #{v}" unless typeof v == 'function' || (k == 'expect' && Array.isArray(v))
          throw new Error "Missing 'arg.action'" unless arg.hasOwnProperty 'action'
          throw new Error "'arg.expect' must have at least one 'done' parameter" unless !arg.hasOwnProperty('expect') || arg.expect.length > 0
        else if typeof arg == 'function'
          arg = action: arg

        else throw new Error "Invalid arg: #{arg}"

        @steps.push arg

        @ # step:

      _executeStep: (stepIndex) ->

If we have passed the last step, we call the done method given to us from the outside - in order to complete the jasmine test.

        if stepIndex > @steps.length
          @done()
          return

        console.log 'step: ', stepIndex if @debug

        step = @steps[stepIndex - 1]
        actionDoneCount = step.action.length
        expectDoneCount = if step.expect then step.expect.length else 0

        doneCount = expectDoneCount + actionDoneCount

        doneFunc = (i) =>
          console.info "passed done(#{i})" if @debug
          do (invoked = false) => () =>
            if invoked
              if @debug
                console.info "done(#{i}) invoked twice"
              return
            console.info "done(#{i})" if @debug
            invoked = true
            if --doneCount == 0
              process.nextTick =>
                @_executeStep stepIndex + 1
                return
            return

        if (step = @steps[stepIndex - 1]).hasOwnProperty 'expect'
          
          doneCount = step.expect.length

          if typeof step.expect == 'function'
            step.expect.apply @context, (doneFunc(i + 1) for i in [actionDoneCount...(actionDoneCount + expectDoneCount)])
          else
            for exp, i in step.expect
              exp.call @context, doneFunc(i + 1)

        if step.action.length > 0
          step.action.apply @context, (doneFunc(i + 1) for i in [0...actionDoneCount])
        else
          step.action.call @context

        if (actionDoneCount + expectDoneCount) == 0
          @_executeStep stepIndex + 1

    module.exports = (context, done, debug) ->

      throw new Error "Invalid argument 'context': #{conext}" unless typeof context == 'object' && context != null
      throw new Error "Invalid argument 'done': #{done}" unless typeof done == 'function'

      new SpecSteps context, done, debug

    module.exports.Class = SpecSteps
