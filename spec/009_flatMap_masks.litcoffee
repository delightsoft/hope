flat map masks
==============================

    {Result, flatMap, BitArray} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '009_flatMap_masks:', ->

When working with a hierarchical structure, it is useful, for elements containing nested elements, to pre-calculate in advance, in addition
to $$index, masks that include the field together with all the fields nested in it.

This functionality is an option of the flatMap method, but it is split out into a separate specification, because bitArray is used for this,
which in turn is specified through the basic flatMap functionality.

      beforeEach ->

        doc =
          fld1: {}
          fld2:
            fields:
              fld2a: {}
              fld2b:
                fields:
                  fld2b1: {}
          fld3: {}

        @map = flatMap (result = new Result), doc, 'fields'

        expect(result.messages).sameStructure []

        flatMap.index result, @map, 'fields', mask: true

        expect(result.messages).sameStructure []

        flatMap.finish result, @map, 'fields'

        expect(result.messages).sameStructure []

      check "general", ->

        expect(@map.fld1.$$mask).not.toBeDefined()
        expect(@map.fld2.$$mask.valueOf()).toEqual [2, 3, 4]
        expect(@map.fld2.fields.fld2a.$$mask).not.toBeDefined()
        expect(@map.fld2.fields.fld2b.$$mask.valueOf()).toEqual [4]
        expect(@map.fld2.fields.fld2b.fields.fld2b1.$$mask).not.toBeDefined()
        expect(@map.fld3.$$mask).not.toBeDefined()

For working with nested fields, we adhere to the following rules:
- if at least one nested field is marked, then the field that includes it must also be marked in the mask
- and vice versa, if a marked field has no marked nested fields - then all of them must be marked

      check "fix items vertical", ->

        mask = new BitArray @map

        mask.set @map.fld2.fields.fld2b.$$index

        mask.fixVertical()

        expect(mask.valueOf()).toEqual [1,3,4]

However this rule is only correct when we collect data about field availability before starting logical operations with masks

There is the reverse task: if, after logical operations with masks, we have selected fields with nested fields among which
no nested field is selected, then such a field must be removed from the result

      check "clear items vertical", ->

        mask = new BitArray @map

        mask.set @map.fld2.$$index

        mask.set @map.fld2.fields.fld2b.$$index

        mask.clearVertical()

        expect(mask.valueOf()).toEqual []
