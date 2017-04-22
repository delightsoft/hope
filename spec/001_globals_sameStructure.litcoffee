
globals jsondiff
==============================

    {Result, compareStructures} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '001_global_jsonDiff:', ->

При работе со спецификация для работы со структурами документов, сталкнулся с проблемой понятного для человека
сравнения двух структур.  Структуры могут содержать кольцевые ссылки.

Использование готового модуля jsondiffpatch вопрос не решило.  На примере сравнение в простой спецификации deepClone,
выяснилось что он сбоит на объектах или массивах внутри массива.  А на пример отладки метода link, стало понятно, что
он не умеет сравнивать структуры с кольцевыми ссылками.  Поэтому пишем свое.  А коль, это уже случилась когда есть
некоторые готовые наработки, то для формирования отчета будем использовать класс DSCommon - Result.

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

Полезный для сложных ситуаций момент - данные в объектах (map'ах) проверяются именно в той последовательности как они
перечислены в expected

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
