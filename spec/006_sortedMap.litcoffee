sorted map
==============================

    {Result, sortedMap, utils: {checkItemName, deepClone, combineMsg, err: {isResult, invalidArg, tooManyArgs}}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '006_sortedMap:', ->

# TODO: Добавить опциональное индексирование элементов для работы с bitArray

Сортедмап (sortedMap) - это соглашение по работе с коллекциями элементов - списками документов, полей, значений enum и
т.п. Полезно как иметь списко значений, так и map для быстрого нахождения элемента по имени.

sortedMap из списка или массива делает map (object):
* ключ - название элемента, значение - значение элемента
* специальный элемент - $$list, содержит список элементов
* все элементы приобразованны в объекты
* у каждого элемента есть свойство *name*, соотвествующие названию элемента
* и свойство *index*, содержащие индекс элемента в списке
* имена элементов должны быть из латинский символов и цифры, начинаться с цифры или маленькой буквы

Важно: sortedMap должен быть immutable, чтобы легче было отлаживать - не менять входящие данные

Можно получить sortedMap из объекта

      check "from map", ->

        res = sortedMap (result = new Result),

          doc1: {}

          doc2: {}

          doc3: {}

        expect(result.isError).toBe false

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {}}

          doc2: doc2 = {name: 'doc2', $$src: {}}

          doc3: doc3 = {name: 'doc3', $$src: {}}

          $$list: [doc1, doc2, doc3]

Можно получить sortedMap из массива

      check "from array", ->

        res = sortedMap (result = new Result), [{name: 'doc1'}, {name: 'doc2'}, {name: 'doc3'}]

        expect(result.isError).toBe false

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {name: 'doc1'}}

          doc2: doc2 = {name: 'doc2', $$src: {name: 'doc2'}}

          doc3: doc3 = {name: 'doc3', $$src: {name: 'doc3'}}

          $$list: [doc1, doc2, doc3]

И из строки

      check "from string", ->

        res = sortedMap (result = new Result), 'doc1, doc2, doc3', string: true

        expect(result.isError).toBe false

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1'}

          doc2: doc2 = {name: 'doc2'}

          doc3: doc3 = {name: 'doc3'}

          $$list: [doc1, doc2, doc3]

Есть два параметра:
* result - объект типа Result
* value - значение для обработки

      check "invalid argument 'result'", ->

        expect(-> sortedMap()).toThrow new Error "Invalid argument 'result': undefined"

Значение иожет быть только или объект или массив

      for wrongValue in [undefined, null, false, 12, '', {}, []]

        do (wrongValue) -> check "invalid argument 'value': #{jasmine.pp wrongValue}", ->

          sortedMap (result = new Result), wrongValue

          expect(result.isError).toBe true

          expect(result.messages).sameStructure [
            {type: 'error', code: 'dsc.invalidValue', value: wrongValue}
          ]

Значение может быть обработано только один раз

      check "one time processing",  ->

        res = sortedMap (result = new Result), map =

          doc1: {}

        expect(-> sortedMap (result = new Result), res).toThrow new Error 'Value was already processed by sortedMap()'

Если значения заданы в object, то значения могут содердать name

      check "name in the element", ->

        res = sortedMap (result = new Result),

          doc1: {v: 12}

          doc2: {name: 'doc2', v: 20}

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {v: 12}}

          doc2: doc2 = {name: 'doc2', $$src: {name: 'doc2', v: 20}}

          $$list: [doc1, doc2]

Но name в значении должно совпадать с ключом

      check "wrong name in the element", ->

        res = sortedMap (result = new Result), set =

          doc1: doc1 = {name: 'otherName', v: 12}

          doc2: {name: 'doc2', v: 20}

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'doc1', code: 'dsc.keyAndNameHasDifferenValues', value1: 'doc1', value2: 'otherName'}
        ]

Значение в map может быть или объектом или true

      check "'true' translated to object element map", ->

        res = sortedMap (result = new Result), {

          doc1: {v: 12}

          doc2: true

          doc3: {}}, boolean: true

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {v: 12}}

          doc2: doc2 = {name: 'doc2'}

          doc3: doc3 = {name: 'doc3', $$src: {}}

          $$list: [doc1, doc2, doc3]

      for wrongValue in [undefined, null, false, 12, 'a string', ['a', 'b']]

        do (wrongValue) -> check "invalid map element: #{wrongValue}", ->

          res = sortedMap (result = new Result), map =

            'doc1': wrongValue

          expect(result.isError).toBe true

          expect(result.messages).sameStructure [
            {type: 'error', path: 'doc1', code: 'dsc.invalidValue', value: wrongValue}
          ]

Значения в массиве могут быть или объектом или строкой

      check "'string' translated to an object in list", ->

        res = sortedMap (result = new Result), ['doc1', 'doc2'], string: true

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1'}

          doc2: doc2 = {name: 'doc2'}

          $$list: [doc1, doc2]

      for wrongValue in [undefined, null, true, false, 12, ['a', 'b']]

        do (wrongValue) -> check "invalid list element: #{wrongValue}", ->

          res = sortedMap (result = new Result), list = [wrongValue]

          expect(result.isError).toBe true

          expect(result.messages).sameStructure [
            {type: 'error', path: '[0]', code: 'dsc.invalidValue', value: wrongValue}
          ]

Объект в массиве обязательно должен иметь свойство name

      check "all list element must have 'name' prop", ->

        sortedMap (result = new Result), list = [{v: 12}, {name: 'doc2', v: 15}, {v: 20}]

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[0]', code: 'dsc.missingProp', value: 'name'}
          {type: 'error', path: '[2]', code: 'dsc.missingProp', value: 'name'}
        ]

В массиве не должно быть элементов с одинаковыми имена

      check "duplicated prop is not allowed in array", ->

        sortedMap (result = new Result), list = [{name: 'doc1'}, {name: 'doc1'}]

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[1]', code: 'dsc.duplicatedName', value: 'doc1'}
        ]

      check "duplicated prop is not allowed in comma separated string", ->

        sortedMap (result = new Result), list = 'doc1, doc1', string: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[1]', code: 'dsc.duplicatedName', value: 'doc1'}
        ]

Имена элементов могут состоять только из латинских букв и цифр, и обяхательно начанаться с маленькой буквы

      check "element 'name' prop must contain letters or digits, and start from lower char", ->

        sortedMap (result = new Result), list = [{name: 'BigName'}, {name: '4inch'}, {name: 'with space'}]

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[0]', code: 'dsc.invalidName', value: 'BigName'}
          {type: 'error', path: '[1]', code: 'dsc.invalidName', value: '4inch'}
          {type: 'error', path: '[2]', code: 'dsc.invalidName', value: 'with space'}
        ]

        sortedMap (result = new Result), value =
          BigName: {}
          '4inch': {}
          'with space': {}

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'BigName', code: 'dsc.invalidName', value: 'BigName'}
          {type: 'error', path: '4inch', code: 'dsc.invalidName', value: '4inch'}
          {type: 'error', path: 'with space', code: 'dsc.invalidName', value: 'with space'}
        ]

Модификация поведения sortedMap
------------------------------

Третий параметр в sortedMap это options, который может содержать следующие свойства
- checkName - метод проверки написания имени
- getValue - позволяет обрабатывать произвольное значение в map и присваевает значение в резльутат.
- boolean - true, если может быть true указано как значение.  Только map
- string - true, если можно указать как значение строку или массив строк.  Только списки
- index - true, добавляет в элементы свойство $$index, с порядковым номеро элемента в $$list

      check "'boolean = false' option", ->

        sortedMap (result = new Result),  {
          item1: true
          item2: {}
          item3: true}, string: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'item1', code: 'dsc.invalidValue', value: true}
          {type: 'error', path: 'item3', code: 'dsc.invalidValue', value: true}
        ]

      check "'string = false' option: string value", ->

        sortedMap (result = new Result), val = "item1, item2, item3", boolean: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', code: 'dsc.invalidValue', value: val}
        ]

      check "'string = false' option: array with a string value", ->

        sortedMap (result = new Result), [{name: 'item1'}, 'item2'], boolean: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[1]', code: 'dsc.invalidValue', value: 'item2'}
        ]

      check "'getValue' option", ->

        actions =

          action1: f1 = ->

          action2: {value: f2 = ->}

Метод getValue возвращает true, если это поддерживаемый тип значения.  И это значение перенесено в dest - собираемый
объект

        res = sortedMap (result = new Result), actions, getValue: (result, value, res) ->

          expect(isResult result).toBe true
          expect(typeof res == 'object' && res != null && !Array.isArray(res)).toBe true
          expect(arguments.length <= 3)

          expect(value).toBe f1

          if typeof f1 == 'function'

              res.value = f1

              return true

          false

        sortedMap.finish result, res, validate: false

        expect(result.messages).toEqual []

        expect(res).sameStructure
          action1: action1 = {name: 'action1', value: f1}
          action2: action2 = {name: 'action2'}
          $$list: [action1, action2]

      check "'copyProps' option", ->

        actions =

          action1: f1 = ->

          action2: {value: f2 = ->}

Метод copyProps копирует свойства исходного map в результат

        res = sortedMap (result = new Result), actions,

        getValue: (result, value, res) ->

Не копируем свойство в этом методе

          if typeof f1 == 'function'

            return true

          false
