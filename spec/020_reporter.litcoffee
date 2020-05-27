reporter
==============================

Reporter и Result решают очень похожую задачу - вывод сообщений.  Разница в том, что Result накапливает сообщения,
но сам их никуда не выводит.  А Reporter выводит сообщения по мере поступления.  В том числе, он может вывести
сообщения из Result

Все сообщения о найденных ошибках и предупреждения о возможных ошибках, выдаются через метод reporter.

    {Result, Reporter, i18n} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '020_reporter:', ->

Объект Reporter может работать без локализации, что полезно для процесса разработки

      check "A", ->

        reporter = new Reporter

        reporter._print = jasmine.createSpy 'reporter.print'

Сообщения могут быть трех типов:
* error - ошибка
* warn - предупреждения
* info - информация

        reporter.error 'test.sampleMessage'
        reporter.warn 'test.sampleMessage2', a: 12
        reporter.info 'test.sampleMessage3', b: 'test', c: false

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'test.sampleMessage']
          ['warn', 'test.sampleMessage2{"a":12}']
          ['info', 'test.sampleMessage3{"b":"test","c":false}']
        ]

        reporter._print.calls.reset()

Но штатный режим, это работа с локализацией

      check "B", ->

Задаем тестовую локализацию

        messages =

          dsc:

            messageA: (args) -> "Message A: Val: #{args.value}"

            messageB: 'simple message'

Переводим конфигурацию в рабочую верси, через операцию link

        messages = i18n.link (result = new Result), messages

        expect(result.isError).toBeFalsy()

Создаем объект отчёт с локализацией из config

        reporter = new Reporter messages

Добавляем метод, через который происходит вывод

        reporter._print = jasmine.createSpy 'reporter.print'

Делаем вывод нескольких сообщений

        reporter.info 'dsc.messageA', value: null

        reporter.error 'dsc.messageB'

        reporter.warn 'dsc.messageC', a: 12, s: 'test'

Проверяем что в reporter._print пришли все сообщения в ожидаемом виде

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['info', 'Message A: Val: null']
          ['error', 'simple message']
          ['warn', 'dsc.messageC{"a":12,"s":"test"}']
        ]

Сбрасываем _print для следующего теста

        reporter._print.calls.reset()

Вывод result
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

Вывод result с контекстом
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

А теперь ещё и с название действия

        reporter.logResult result, 'dsc.messageA', value: 111

        expect(reporter._print.calls.allArgs()).sameStructure [
          ['error', 'Message A: Val: 111']
          ['error', 'Field1: Message A: Val: test']
          ['info', 'Field2: simple message']
        ]

        reporter._print.calls.reset()

Reporter должен быть не отличим от Result при работе с контекстом и выводе сообщений
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

При входе в context isError сбрасывается в false

          result.context (->), ->

            expect(result.isError).toBe false

При выходе наличие ошибки восстанавливается

          expect(result.isError).toBe true

          result.isError = false

        expect(result.isError).toBe true # ###

