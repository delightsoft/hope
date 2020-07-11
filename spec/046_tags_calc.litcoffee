Tags.Calc
==============================

Метод для обработки выражений, содержаших теги.  Результатом является список элементов, которые были получени или
напрямую или через теги.

Операции которые можно использовать в строке
* , (запятая) (или + (плюс)) - добавление элементов
* \- (минус) - удаление элементов из группы справ, из группы элементов слева от операнда
* ! (восклицательный знак) - получение обратной группы элементов
* ( ) (скобки) - группирование операций

В операции имена тегов начинаются с '#', а для простых элементов используются имена без изменений.

Пример операции: *(#topFields - username) + #!adminFields* , что читается как взять все поля с тегом topFields,
кроме поля username, и добавить к ним все поля, кроме полей помеченных тегом adminFields.

Важно, чтоб элементы в полученном списке располагались имеено в той же последовательности, как и в исходном
списке элементов.  Это пригодиться при формировании экранных форм, когда важно чтоб поля отображались в том же порядке,
как они были определены в исходной модели.

**На будущее:**
- Надо подумать, не стоит ли добавить самостоятельную операцию отрицание, чтобы можно было взять все
поля кроме указанного, или взять обратный результат от операции в скобках.
- Стоит ли добавить операцию умножение ('*'), чтобы можно было получить пересечение двух наборов.  Это, правда,
по хорошему потребует добавление приоритезации операций

    {Result, sortedMap, flatMap, tags: {calc: calcTags, compile: compileTags}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '046_tags_calc', ->

Создаем документ для проверки разных выражений

      beforeEach ->

        @fields =
          fld1: {tags: 'a, test.b, c'}    # 0
          fld2: {tags: ''}           # 1
          fld3:                      # 2
            tags: ''
            fields:
              fld3a: {tags: 'test.b'} # 3
              fld3b: {}              # 4
              fld3c:                 # 5
                tags: 'c'
                fields:
                  fld3a1: {tags: ''} # 6
                  fld3a2: {tags: ''} # 7
          fld4: {tags: 'a, test.b, c'}    # 8

        @fields = flatMap (result = new Result), @fields, 'fields', index: true, mask: true

        compileTags result, @fields

        flatMap.finish result, @fields, 'fields', validate: false

        expect(result.messages).toEqual []

      check 'ok', ->

        expect((calcTags (result = new Result), @fields, 'fld1, fld2, fld4').valueOf()).toEqual [0, 1, 8]

        expect((calcTags (result = new Result), @fields, 'fld3').valueOf()).toEqual [2, 3, 4, 5, 6, 7]

        expect((calcTags (result = new Result), @fields, 'fld3.fld3c, fld4').valueOf()).toEqual [2, 5, 6, 7, 8]

        expect((calcTags (result = new Result), @fields, '#a, #test.b').valueOf()).toEqual [0, 2, 3, 8]

        expect((calcTags (result = new Result), @fields, '#all').valueOf()).toEqual [0, 1, 2, 3, 4, 5, 6, 7, 8]

        expect((calcTags (result = new Result), @fields, '!fld2').valueOf()).toEqual [0, 2, 3, 4, 5, 6, 7, 8]

        expect((calcTags (result = new Result), @fields, 'fld1,fld2,fld4 & fld2,fld4').valueOf()).toEqual [1, 8]

        expect((calcTags (result = new Result), @fields, '(fld1,(fld2,fld4) & (fld2,fld4))').valueOf()).toEqual [1, 8]

        expect((calcTags (result = new Result), @fields, '#all - #a + fld1').valueOf()).toEqual [0, 1, 2, 3, 4, 5, 6, 7]

      check 'error: unbalanced parenthesises', ->

        calcTags (result = new Result), @fields, expr = 'fld1,(fld2'

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.unmatchParenthesis', position: expr.length, value: 'fld1,(fld2'}]

        calcTags (result = new Result), @fields, expr = 'fld1,(fld2))'

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.unmatchParenthesis', position: expr.length - 1, value: 'fld1,(fld2))'}]

      check 'error: unknown names', ->

        calcTags (result = new Result), @fields, expr = 'fld1, aaa, fld2, bbb'

        expect(result.messages).sameStructure [
          {type: 'error', code: 'dsc.unknownItem', value: 'aaa', position: 6}
          {type: 'error', code: 'dsc.unknownItem', value: 'bbb', position: 17}
        ]

        calcTags (result = new Result), @fields, expr = '#a, #f, #test.b, #q, #ui.a123'

        expect(result.messages).sameStructure [
          {type: 'error', code: 'dsc.unknownTag', value: 'f', position: 4}
          {type: 'error', code: 'dsc.unknownTag', value: 'q', position: 17}
          {type: 'error', code: 'dsc.unknownTag', value: 'ui.a123', position: 21}
        ]

