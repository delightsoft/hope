result
==============================

Для работы с ошибками (error) и предупреждениями (warnings) у нас есть специальный класс Result

    {Result, utils: {err: {_argError}}} = require '../src'

    focusOnCheck = ""


    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '010_result:', ->

Объекты Result позволяют накапливать методанные по сообщениям.  Методанные включают:
* type - тип сообщения: error, warn или info
* code - код сообщения.  Строка включающая код сообщения, с namespace'ом
* args - аргументы сообщения.  Не обязательный параметр

      check "simple result", ->

        result = new Result

Сообщения могут быть трех типов:
* error - ошибка
* warn - предупреждения
* info - информация

        result.error 'test.sampleMessage'
        result.warn 'test.sampleMessage2', a: 12
        result.info 'test.sampleMessage3', b: 'test', c: false

Все сообщения, складываются в массив messages

        expect(result.messages).sameStructure [
          {type: 'error', code: 'test.sampleMessage'}
          {type: 'warn', code: 'test.sampleMessage2', a: 12}
          {code: 'test.sampleMessage3', b: 'test', c: false}
        ]

Несколько Result объектов, можно объединять в один

      check "combine results", ->

Создаем головоной Result объект, и для теста добавляем туда сразу сообщение

        result = new Result
        result.info 'test.rootMessage'

        expect(result.isError).toBeFalsy()
        expect(result.messages).sameStructure [
          {code: 'test.rootMessage'}
        ]

Предположим, что метод вернул другой result объект, содержащий в себе в том числе ошибки

        resultA = new Result
        resultA.error 'test.sampleMessage'
        resultA.warn 'test.sampleMessage2'

        expect(resultA.isError).toBeTruthy()
        expect(resultA.messages).sameStructure [
          {type: 'error', code: 'test.sampleMessage'}
          {type: 'warn', code: 'test.sampleMessage2'}
        ]

При объединении, в головном Result добавятся все сообщения из result, который вернул метод

        result.add resultA

        expect(result.isError).toBeTruthy()
        expect(result.messages).sameStructure [
          {code: 'test.rootMessage'}
          {type: 'error', code: 'test.sampleMessage'}
          {type: 'warn', code: 'test.sampleMessage2'}
        ]

Для единообразия объект класса Result передается как первый параметр в методы, чтобы через него методы могли сообщить найденные ошибки

      check "result as first argument", (done) ->

        sampleMethod = (result, arg1) ->

          new Promise (resolve, reject) ->

            if arg1 != 'good'

              result.error 'invalidArg', arg: 'arg1', value: arg1

              reject(); return

            resolve()

            return # new Promise

        c = 2

Успешный вызов

        goodResult = new Result

        sampleMethod goodResult, 'good'
        .then ->

          expect(goodResult.isError).toBeFalsy()
          expect(goodResult.messages).sameStructure []

          done() if --c == 0

          return

Вызов с ошибкой в результате

        badResult = new Result

        sampleMethod badResult, 'bad'
        .then (-> return), ->

          expect(badResult.isError).toBeTruthy()
          expect(badResult.messages).sameStructure [{type: 'error', code: 'invalidArg', arg: 'arg1', value: 'bad'}]

          done() if --c == 0

          return

pathFunc
------------------------------

Чтобы можно было сообщение привязать к конкретному элементу дерева, можно вместе с сообщением сохранять pathFunc.

Для этого создаем Result объект, в которой передаем функцию, которая при необходимости возвращает текущий context

      check "pathFunc", ->

        field = 'field1'

        result = new Result (path) -> (Result.prop field) path

Добавляем ошибку когда функция pathFunc возвращает `{type: 'field', fld: 'field 1'}`

        result.error 'test.fieldError'

        field = 'field2'

Добавляем ошибку когда функция pathFunc возвращает `{type: 'field', fld: 'field 2'}`

        result.error 'test.fieldError'

И получаем список сообщений с сохраненными контекстами

        expect(result.messages).sameStructure [
          {type: 'error', path: 'field1', code: 'test.fieldError'}
          {type: 'error', path: 'field2', code: 'test.fieldError'}
        ]

Контекстов может быть несколько

        prop = 'A'

        [oldContext, result.pathFunc] = [result.pathFunc, (path) -> (Result.prop prop, oldContext) path]

        result.error 'test.fieldError'

        prop = 'B'

        result.error 'test.fieldError'

        result.pathFunc = oldContext

        result.error 'test.fieldError'

В результате пока есть второй контекст, в результате делается список контектов

        expect(result.messages).sameStructure [
          {type: 'error', path: 'field1', code: 'test.fieldError'}
          {type: 'error', path: 'field2', code: 'test.fieldError'}
          {type: 'error', path: 'field2.A', code: 'test.fieldError'}
          {type: 'error', path: 'field2.B', code: 'test.fieldError'}
          {type: 'error', path: 'field2', code: 'test.fieldError'}
        ]

Для многошаговой обработки необходимо для каждого шага создавать собственный Result.  Но при этом важно чтобы в этот
result переносился pathFunc исходного Result'а.  Если в качестве параметра для нового Result передать другой, то сообщения
сохраняемые в новый result

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

Проверяем, что возвращается exception, если параметр не верен

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

Для вложенной обработки элементов, нужно иметь возможность каждый уровень обрабатывать, зная какой элемент
обрабатывается.  Если ошибка произошла на вложенном уровне, то она будет видна и при выходе из вложенного контекста на
уровне выше, даже если внутри вложенного контекста был сброс isResult в false.

      check "context: keep errors", ->

        (result = new Result).context (->), ->

          result.error 'someError'

          expect(result.isError).toBe true

При входе в context isError сбрасывается в false

          result.context (->), ->

            expect(result.isError).toBe false

При выходе наличие ошибки восстанавливается

          expect(result.isError).toBe true

          result.isError = false

        expect(result.isError).toBe true

empty context
------------------------------

Для вложенной обработки, когда нет реального контекста, метод result.context можно вызывать без первого параметра

      check "empty context: keep errors", ->

        (result = new Result).context  ->

          result.error 'someError'

          expect(result.isError).toBe true

При входе в context isError сбрасывается в false

          result.context ->

            expect(result.isError).toBe false

При выходе наличие ошибки восстанавливается

          expect(result.isError).toBe true

          result.isError = false

        expect(result.isError).toBe true
