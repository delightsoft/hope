utils
==============================

    {Result, utils: {checkItemName, deepClone, combineMsg, sortedMap}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '004_utils_deepClone:', ->

deepClone
------------------------------

Deep cloning can be applied to any types


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

Objects are cloned

        expect(dest.map).not.toBe src.map

Arrays are cloned

        expect(dest.arr).not.toBe src.arr

But functions are preserved

        expect(dest.map.f).toBe src.map.f

Properties starting with $$ are not cloned and are not copied into the cloning result.  This is needed so that when cloning,
properties such as $$list, $$tags, $$doc - which store circular references to objects - are not duplicated

      check "do not clone props with $$", ->

        src =

          fld1: fld1 = {name: 'fld1', type: 'integer'}

          $$list: [fld1]

          $$tags:

            tag1: [fld1]

        dest = deepClone src

        expect(dest).sameStructure

          fld1: {name: 'fld1', type: 'integer'}

You can add special handling for specific fields.  If the customClone method (the second parameter) intercepts cloning for a field,
it returns an array with one element holding the resulting value.

      check "customClone", ->

        src =

          fld1: fld1 = {name: 'fld1', type: 'integer'}

          fields: []

          skipThis: true

        dest = deepClone src, customClone: (k, v) ->

          switch k

            when 'fields' then ['custom value']

If the value is undefined, the property is not cloned

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

      check "$$list", ->

        src = fld1: fld1 = {name: 'fld1', type: 'integer'}, $$list: [fld1]

        res = deepClone src, {all: true}

        expect(src.fld1).not.toBe res.$$list[0]

        expect(res.fld1).toBe res.$$list[0]
