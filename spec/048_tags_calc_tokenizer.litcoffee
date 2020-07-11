Tags.Calc._Tokenzier
==============================

Это внутрений метод tags.calc, для разобра выражения.  Однако его тоже полезно специфицировать - так правильнее и надежнее

    {Result, tags: {calc: {_tokenizer: tokenizer}}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "048_tags_calc_tokenizer", ->

      check "simple", ->

        nextToken = tokenizer (result = new Result), 'a, boom.aaa + c - d, #a1, !#test.b2'

        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe 'boom.aaa'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe 'c'
        expect(nextToken()).toBe '-'
        expect(nextToken()).toBe 'd'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '#a1'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '!'
        expect(nextToken()).toBe '#test.b2'
        expect(nextToken()).toBe null

Выражение не может начинаться с операции

      check "error: operation before element/tag name", ->

        nextToken = tokenizer (result = new Result), expr =  ' - a'

Возврат undefined означает, что найдена ошибка

        expect(nextToken()).toBe undefined

После завершения обработки все остальные вызовы дают null

        expect(nextToken()).toBe null
        expect(nextToken()).toBe null

        expect(result.messages).sameStructure [
          {type: 'error',  code: 'dsc.invalidExpression', value: expr, position: 1}
        ]

Операции не могут идти не разделенными элементами

      check "error: sequantially few operations", ->

        nextToken = tokenizer (result = new Result), expr =  ' b - + a'

        expect(nextToken()).toBe 'b'
        expect(nextToken()).toBe '-'
        expect(nextToken()).toBe undefined
        expect(nextToken()).toBe null

        expect(result.messages).sameStructure [
          {type: 'error',  code: 'dsc.invalidExpression', value: expr, position: 5}
        ]

Закрывающая скобка может быть только после имени элемента/тега, и не может идти сразу за операцией

      check "ok: close paranthesis may come after element name", ->

        nextToken = tokenizer (result = new Result), expr =  'a, (b+c)'

        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '('
        expect(nextToken()).toBe 'b'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe 'c'
        expect(nextToken()).toBe ')'
        expect(nextToken()).toBe null

      check "ok: close paranthesis may come after tag name", ->

        nextToken = tokenizer (result = new Result), expr =  '(b+#tag)'

        expect(nextToken()).toBe '('
        expect(nextToken()).toBe 'b'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '#tag'
        expect(nextToken()).toBe ')'
        expect(nextToken()).toBe null

      check "error: close paranthesis cannot come after operation", ->

        nextToken = tokenizer (result = new Result), expr =  '(b+)'

        expect(nextToken()).toBe '('
        expect(nextToken()).toBe 'b'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe undefined

        expect(result.messages).sameStructure [
          {type: 'error',  code: 'dsc.invalidExpression', value: expr, position: 3}
        ]

Если, выражение заканчивается на операции - ошибка

      check "error: operation at the end of expression", ->

        nextToken = tokenizer (result = new Result), expr =  'b +'

        expect(nextToken()).toBe 'b'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe undefined

        expect(result.messages).sameStructure [
          {type: 'error',  code: 'dsc.invalidExpression', value: expr, position: 3}
        ]

Отрицание может идти в начале выражения, перед скобками и перед именами элементов и тегов.

      check "ok: exclamation mark at the begging", ->

        nextToken = tokenizer (result = new Result), expr =  '! a'

        expect(nextToken()).toBe '!'
        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe null

      check "ok: exclamation mark before open paraenthesis", ->

        nextToken = tokenizer (result = new Result), expr =  '!(a)'

        expect(nextToken()).toBe '!'
        expect(nextToken()).toBe '('
        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe ')'
        expect(nextToken()).toBe null

      check "ok: exclamation mark before names", ->

        nextToken = tokenizer (result = new Result), expr =  'a+!a,!#test'

        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '!'
        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '!'
        expect(nextToken()).toBe '#test'
        expect(nextToken()).toBe null

      check "error: exclamation mark with operation", ->

        nextToken = tokenizer (result = new Result), expr =  'a !a'

        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe undefined

        expect(result.messages).sameStructure [
          {type: 'error',  code: 'dsc.invalidExpression', value: expr, position: 2}
        ]

      check "error: two exclamation marks", ->

        nextToken = tokenizer (result = new Result), expr =  'a,!!a'

        expect(nextToken()).toBe 'a'
        expect(nextToken()).toBe '+'
        expect(nextToken()).toBe '!'
        expect(nextToken()).toBe undefined

        expect(result.messages).sameStructure [
          {type: 'error',  code: 'dsc.invalidExpression', value: expr, position: 3}
        ]
