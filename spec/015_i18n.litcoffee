I18n (Internationalization)
==============================

Общий принцип локализации, это то что коду сообщения соответствует функция, в config.i18n, которая создает сообщение.

    {Result, i18n, utils} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '015_i18n:', ->

      beforeEach ->

Сообщения - это flatMap

        messages =

          test:

Сообщение test.messageA без аргументов

            messageA: @f3 = -> "Message A"

Сообщение test.messageB с аргументов

            messageB: @f4 = (args) -> "Message B. Value: #{args.value}"

Сообщение в виде просто строки

            messageC: @s1 = 'Simple Message'

Или даже числа

            messageD: @n1 = 121

Перед использование данных для интернационализации надо выполнить метод i18n.link

        @messages = i18n.link (@result = new Result), messages

Метод i18n.link пересобирает сообщения из иерархической структуры в плоский map.  При этом будут выданы предупреждения
об отсуствующих частях

      check "A", ->

        expect(@messages).sameStructure
          'test.messageA': @f3
          'test.messageB': @f4
          'test.messageC': @s1
          'test.messageD': @n1

Метод i18n.format форматирует сообщения            
            
      check "B", ->

Если сообщение есть в локализации, получаем локализованное сообщение

        expect(i18n.format @messages, code: 'test.messageA').toBe 'Message A'

Если сообщение есть в локализации и содержит параметры, то получаем локализованное сообщение с параметрами

        expect(i18n.format @messages, code: 'test.messageB', value: '123').toBe 'Message B. Value: 123'

Если локализация сообщения - просто строка, то эту строку в результате и получаем

        expect(i18n.format @messages, code: 'test.messageC').toBe 'Simple Message'

Если локализация сообщения не функция и не строка, то получаем значение локализации в строчном виде

        expect(i18n.format @messages, code: 'test.messageD').toBe '121'

Если сообщения НЕТ в локализации, то оставляем название сообщения

        expect(i18n.format @messages, code: 'test.messageQ').toBe 'test.messageQ'

Если сообщения НЕТ в локализации, и оно с параметрами, то оставляем название сообщения и добавляем параметр в конец
сообщения в виде JSON.

        expect(i18n.format @messages, code: 'test.messageF', value: '123').toBe 'test.messageF{"value":"123"}'

Code сообщения должен соотвествовать структуре локализации

      check "C", ->

Есди Test с большой буквы, уже не находим вариант где test с маленькой буквы

        expect(i18n.format @messages, code: 'Test.messageA').toBe 'Test.messageA'

То же для MessageA с большой буквы

        expect(i18n.format @messages, code: 'test.MessageA').toBe 'test.MessageA'

Если путь к сообщению содержит дополнительные шаги, то тоже не находится промежуточный вариант

        expect(i18n.format @messages, code: 'test.messageA.extra').toBe 'test.messageA.extra'

Сообщение может содержать контекст, который форматируется по тем же правилам что и основное сообщение, только
метод выбирается из config.i18n.contexts

      check "D", ->

        expect(i18n.format @messages, path: 'config', code: 'test.messageA')
        .toBe "config: Message A"

        expect(i18n.format @messages, path: 'config', code: 'test.messageB', value: '123')
        .toBe "config: Message B. Value: 123"

Форматирование может вестись без i18n колекции.  Тогда форма работает так как если бы локализация всегда не была найдена

      check "E", ->

        expect(i18n.format undefined, code: 'test.messageA').toBe 'test.messageA'

Если сообщение есть в локализации и содержит параметры, то получаем локализованное сообщение с параметрами

        expect(i18n.format null, code: 'test.messageB', value: 123).toBe 'test.messageB{"value":123}'

Если сообщение содержит path, то он добавляется к сообщение без локализации

      check "F", ->

        expect(i18n.format null, path: 'a[1]', code: 'test.messageB', value: 123)
        .toBe "a[1]: test.messageB{\"value\":123}"