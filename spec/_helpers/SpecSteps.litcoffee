Тестирование сетевых соединений, требует чтобы сперва был написан код, который обрабатывает событие, и только
потом можно выполнить проверяемую операцию.  Однако, для спецификаций нужно писать что делаем, и только потом что
получаем.

Этот класс решает эту проблему, разделя шаги спецификации на часть - что хотим сделать (action), и часть - что
ожидаем (expect).  И эти части выполняются в обратной последовательности - сперва expect, а потом action.

Так как expect часто предполагает ожидание поступления сигнала, мы можем передать несколько callback-методов, и
метод expect будет считаться выполненым, если все callback-методы были вызваны.

    process = require 'process'

    class SpecSteps

Для отладки спецификации, полезно включать debug в true - тогда видно на каком шаге завис (не вызвал done) тест.

      constructor: (@context, @done, @debug) ->

        @steps = []

Так как все шаги определяются за один вызов функции, то логично запустить процесс выполнения на следующем тике.

        process.nextTick =>
          @_packStep() if @_action
          @_executeStep 1
        
        @_action = @_expects = null
        
Добавляем шаги в тест, через цепочку вызовов метода step.

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

Если мы прошли последний шаг, то вызываем метод done, данный нам из вне - чтобы завершить jasmine-тест.

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
