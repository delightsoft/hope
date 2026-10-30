Tags.Calc
==============================

A method for processing expressions that contain tags.  The result is a list of elements that were obtained either
directly or through tags.

Operations that can be used in the string:
* , (comma) (or + (plus)) - adding elements
* \- (minus) - removing the elements of the group on the right from the group of elements on the left of the operand
* ! (exclamation mark) - obtaining the inverse group of elements
* ( ) (parentheses) - grouping of operations

In an operation, tag names begin with '#', while plain elements use their names unchanged.

Example of an operation: *(#topFields - username) + #!adminFields* , which means take all the fields with the tag topFields,
except the username field, and add to them all the fields, except the fields marked with the tag adminFields.

It is important that the elements in the resulting list appear in exactly the same order as in the original
list of elements.  This will be needed when building screen forms, when it matters that the fields are displayed in the same order
in which they were defined in the original model.

**For the future:**
- We should consider whether to add a standalone negation operation, so that one could take all
the fields except the specified one, or take the inverse result of the operation in parentheses.
- Whether to add a multiplication operation ('*'), so that one could obtain the intersection of two sets.  This, however,
properly requires adding operation prioritization

    {Result, flatMap, tags: {calc: calcTags, compile: compileTags}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '046_tags_calc', ->

We create a document for checking different expressions

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

        @fields = flatMap (result = new Result), @fields, 'fields'

        expect(result.messages).toEqual []

        flatMap.index result, @fields, 'fields', mask: true

        expect(result.messages).toEqual []

        compileTags result, @fields

        expect(result.messages).toEqual []

        flatMap.finish result, @fields, 'fields', validate: false

        expect(result.messages).toEqual []

      check 'ok', ->

        expect((calcTags (result = new Result), @fields, 'fld1, fld2, fld4').valueOf()).toEqual [0, 1, 8]

        expect((calcTags (result = new Result), @fields, 'fld3').valueOf()).toEqual [2]

        expect((calcTags (result = new Result), @fields, 'fld3').fixVertical().valueOf()).toEqual [2, 3, 4, 5, 6, 7]

        expect((calcTags (result = new Result), @fields, 'fld3.fld3c, fld4').valueOf()).toEqual [5, 8]

        expect((calcTags (result = new Result), @fields, '#a, #test.b').valueOf()).toEqual [0, 3, 8]

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
          {type: 'error', code: 'dsc.unknownItem', expr: 'fld1, aaa, fld2, bbb', value: 'aaa', position: 6}
          {type: 'error', code: 'dsc.unknownItem', expr: 'fld1, aaa, fld2, bbb', value: 'bbb', position: 17}
        ]

        calcTags (result = new Result), @fields, expr = '#a, #f, #test.b, #q, #ui.a123'

        expect(result.messages).sameStructure [
          {type: 'error', code: 'dsc.unknownTag', expr: '#a, #f, #test.b, #q, #ui.a123', value: 'f', position: 4}
          {type: 'error', code: 'dsc.unknownTag', expr: '#a, #f, #test.b, #q, #ui.a123', value: 'q', position: 17}
          {type: 'error', code: 'dsc.unknownTag', expr: '#a, #f, #test.b, #q, #ui.a123', value: 'ui.a123', position: 21}
        ]

      check 'error: unknown names: not strict', ->

        calcTags (result = new Result), @fields, expr = 'fld1, aaa, fld2, bbb', strict: false

        expect(result.messages).sameStructure []

      check 'list expr', ->

        res = calcTags (result = new Result), @fields, ['fld1', 'fld2'], strict: false

        expect(result.messages).sameStructure []

        expect(res.valueOf()).sameStructure [0, 1]

        res = calcTags (result = new Result), @fields, ['fld2,fld3'], strict: false

        expect(result.messages).sameStructure []

        expect(res.valueOf()).sameStructure [1, 2]

        res = calcTags (result = new Result), @fields, [], strict: false

        expect(result.messages).sameStructure []

        expect(res.valueOf()).sameStructure []
