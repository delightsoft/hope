
globals jsondiff
==============================

    {Result, compareStructures} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '001_global_jsonDiff:', ->

While working on the spec for document structure handling, I ran into the problem of making a comparison of two structures
human-readable. Structures may contain circular references.

Using the ready-made jsondiffpatch module did not solve the problem. In a simple deepClone spec experiment,
it turned out that it fails on objects or arrays nested inside an array. And while debugging the link method as an example,
it became clear that it cannot compare structures with circular references. So we write our own. And since some
ready-made groundwork already existed, we will use the DSCommon - Result class to produce the report.

      check "ok: tree", ->

        tree =
          a: 12
          b: ->
          c: true
          d: false
          e: {}
          f: []
          g: ''
          h: undefined
          i: null
          s:
            a: 12
            b: ->

        expect(tree).sameStructure tree

      check "ok: cicle", ->

        tree =
          a: 12
          b: ->
          c: true
          d: false
          e: {}
          f: []
          g: ''
          h: undefined
          i: null
          s:
            a: 12
            b: ->

        tree.s.a = tree

        expect(tree).sameStructure tree

A useful point for complicated situations - data in objects (maps) is checked exactly in the sequence in which it
is listed in the expected

      check "error: right sequence of messages", ->

        treeActual =
          a: 12
          b: 'string'
          c: true

        treeExpected =
          a: ''
          b: false

        compareStructures (result = new Result), treeActual, treeExpected

        expect(result.messages).toEqual [
          {path: 'a', code: 'diffType', actual: 'number', expected: 'string'}
          {path: 'b', code: 'diffType', actual: 'string', expected: 'boolean'}
          {path: 'c', code: 'extra', value: true}
        ]

        treeExpected2 =
          b: false
          a: ''

        compareStructures (result = new Result), treeActual, treeExpected2

        expect(result.messages).toEqual [
          {path: 'b', code: 'diffType', actual: 'string', expected: 'boolean'}
          {path: 'a', code: 'diffType', actual: 'number', expected: 'string'}
          {path: 'c', code: 'extra', value: true}
        ]
