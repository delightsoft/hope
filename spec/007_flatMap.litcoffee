flat map
==============================

    {Result, flatMap, utils: {checkItemName, deepClone, combineMsg, err: {isResult, invalidArg, tooManyArgs}}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '007_flatMap:', ->

FlatMap is an agreement on working with hierarchical collections.  FlatMap is an extension
of the agreement - sortedMap.

      beforeEach ->

        @src =
          item1: true
          item2:
            subitems:
              item2a: true
              item2b: true
          item3: true

FlatMap adds to the sortedMap collection a collection $$flat, which contains the elements of all levels.  As keys
in $$flat the full names of elements are used, and there is a full list of elements, in the order in which they are encountered
while traversing the structure, in $$flat.$$list.

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

The flatMap method is passed a method, which returns the nested collection of an element.  Since in different cases
this property may be named differently - fields, as an example.

      check 'process subitems', ->

        res = flatMap (result = new Result), @src, 'subitems', boolean: true

        flatMap.index result, res, 'subitems'

        flatMap.finish result, res, 'subitems'

        expect(result.messages).sameStructure []

        expect(res).sameStructure @flatMap
