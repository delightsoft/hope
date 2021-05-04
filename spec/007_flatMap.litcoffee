flat map
==============================

    {Result, flatMap, utils: {checkItemName, deepClone, combineMsg, err: {isResult, invalidArg, tooManyArgs}}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '007_flatMap:', ->

Флетмап (flatMap) - это соглашению по работе с иерархическими коллекциями.  Флетмап это расширение
соглашения - сортедмап (sortedMap).

      beforeEach ->

        @src =
          item1: true
          item2:
            subitems:
              item2a: true
              item2b: true
          item3: true

Флетмап добавляет в коллекцию sortedMap, коллекцию $$flat, которая содержит элементы всех уровней.  В качестве ключей
в $$flat используются полные имена элементов, и есть полный список элементов, в порядке как они приходтся при
обходе структуры, в $$flat.$$list.

        @flatMap =
          item1: @item1 = {name: 'item1', $$index: 0}
          item2: @item2 =
            name: 'item2'
            $$index: 1
            subitems:
              item2a: @item2a = {name: 'item2a', fullname: 'item2.item2a', $$index: 2}
              item2b: @item2b = {name: 'item2b', fullname: 'item2.item2b', $$index: 3}
              $$list: [@item2a, @item2b]
          item3: @item3 = {name: 'item3', $$index: 4}
          $$list: [@item1, @item2, @item3]
          $$flat:
            'item1': @item1
            'item2': @item2
            'item2.item2a': @item2a
            'item2.item2b': @item2b
            'item3': @item3
            $$list: [@item1, @item2, @item2a, @item2b, @item3]

Методу flatMap передается метод, который возвращает вложенную коллекцию элемента.  Так как в разных случаях
это свойство может называтьcz по разному - fields, как пример.

      check 'process subitems', ->

        res = flatMap (result = new Result), @src, 'subitems', boolean: true

        flatMap.index result, res, 'subitems'

        flatMap.finish result, res, 'subitems'

        expect(result.messages).sameStructure []

        expect(res).sameStructure @flatMap
