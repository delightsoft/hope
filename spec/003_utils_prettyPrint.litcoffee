utils sortKeys
==============================

    {utils: {prettyPrint}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '003_utils_prettyPrint:', ->

      check 'general', ->

        expect(prettyPrint 0).toBe '0'
        expect(prettyPrint false).toBe 'false'
        expect(prettyPrint true).toBe 'true'
        expect(prettyPrint null).toBe 'null'
        expect(prettyPrint undefined).toBe 'undefined'
        expect(prettyPrint '').toBe '\'\''
        expect(prettyPrint 'string').toBe '\'string\''

        expect(prettyPrint {a:12, b:20, c:30}).toBe '{a: 12, b: 20, c: 30}'

        expect(prettyPrint [10, true, null, undefined]).toBe '[10, true, null, undefined]'

      check 'limit the list', ->

        list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

        expect(prettyPrint list).toBe '[0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ...]'

      check 'limit the map', ->

        map =
          a: 1
          b: 2
          c: 3
          d: 4
          e: 5
          f: 6
          g: 7
          h: 8
          i: 9
          j: 10
          k: 11

        expect(prettyPrint map).toBe '{a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8, i: 9, j: 10 ...}'

      check 'limit levels', ->

        object =

          a:

            b:

              c: 12

        expect(prettyPrint object).toBe '{a: {b: [object]}}'

      check 'limit levels', ->

        list = [10, [20, [30]]]

        expect(prettyPrint list).toBe '[10, [20, [list]]]'

      check 'skip props with $', ->

        object =

          a: true

          $f: false

          d: [12, 20, {t: 20}]

        expect(prettyPrint object).toBe '{a: true, d: [12, 20, [object]]}'

      check 'complex keys in parenthesises', ->

        object =

          null: 20

          10: 100

          'with space': 10

          '&!strang chars': 0

        expect(prettyPrint object).toBe '{10: 100, null: 20, \'with space\': 10, \'&!strang chars\': 0}'
