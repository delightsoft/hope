utils
==============================

    {Result, utils: {checkItemName, deepClone, combineMsg, sortedMap}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '004_utils_deepClone:', ->

deepClone
------------------------------
      
Глубокое клонирование может применяться для любых типов


      check "main", ->

        src =

          'undef': undefined

          'bool': true

          num: 10

          str: 'a string'

          map:

            a: 12

            f: -> funtion

          arr: [undefined, false, 1, 'string', {b: 121}, [false, 20]]

        dest = deepClone src

        # expect(dest).jsonDiff src # TODO: Report to jsondiffpatch as error example. diff fails on b:121 and [false, 20]
        expect(dest).sameStructure src

Клонируются объекты

        expect(dest.map).not.toBe src.map

Клонируются массивы

        expect(dest.arr).not.toBe src.arr

А вот функцию сохраняются

        expect(dest.map.f).toBe src.map.f

Свойтсва начинающиеся в $$ не клонируются и не копируются в результат клонирования.  Это нужно, чтобы при клонировании
не дублировались свойства типа $$list, $$tags, $$doc, хранящие кольцевые ссылки на объекты

      check "do not clone props with $$", ->

        src =

          fld1: fld1 = {name: 'fld1', type: 'integer'}

          $$list: [fld1]

          $$tags:

            tag1: [fld1]

        dest = deepClone src

        expect(dest).sameStructure

          fld1: {name: 'fld1', type: 'integer'}

Можно добавлять сперциальную обработку для определенных полей.  Если метод customClone (второй параметр) перехватил клонирование для поля,
то он возвращает массив из одного элемента с результирующим значением.

      check "customClone", ->

        src =

          fld1: fld1 = {name: 'fld1', type: 'integer'}

          fields: []

          skipThis: true

        dest = deepClone src, (k, v) ->

          switch k

            when 'fields' then ['custom value']

Если значение undefined, то свойство не клонируется

            when 'skipThis' then [undefined ]

        expect(dest).sameStructure

          fld1: {name: 'fld1', type: 'integer'}

          fields: 'custom value'

      check "loops", ->

        root = {}

        root.b =

          a: root

        root.c = [root]

        root.d = [root.b, root.c]

        res = deepClone root

        expect(res.b.a).toBe res

        expect(res.c[0]).toBe res

        expect(res.c).toEqual [res]

        expect(res.d).toEqual [{a: res}, [res]]




