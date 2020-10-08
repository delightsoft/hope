config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '90_vueDebugWatchBuilder', ->

      check 'general', ->

        res = compileConfig (result = new Result), {
          docs: Doc1: fields:
            a: type: 'string(20)'
            b: type: 'int', null: true
            st: type: 'subtable', fields:
              c: type: 'boolean'
              d: type: 'structure', fields:
                e: type: 'double'
            str: type: 'structure', fields:
              e: type: 'date'
              s: type: 'subtable', fields:
                s2: fields:
                  f1: type: 'int'
        }, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, false

        watchFunc = linkedConfig.docs['doc.Doc1'].fields.$$vueDebugWatchBuilder 'model'

        model =
          a: '123'
          b: null
          st: [
            {c: true, d: e: 12.21}
            {c: false, d: e: 24}
          ]
          str:
            e: '2020-08-22'
            s: [
              {s2: f1: 12}
              {s2: f1: 24}
              {s2: f1: 36}
            ]

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual []

        model.a = 'test'
        model.st[0] = {c: false, d: e: 12.21}
        model.st[1].d = e: 112
        model.str = e: '2020-08-21', s: [
          {s2: f1: 12}
          {s2: f1: 24}
          {s2: f1: 36}
        ]

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st[0]', code: 'changed'}
          {type: 'warn', path: 'model.st[1].d', code: 'changed'}
          {type: 'warn', path: 'model.str', code: 'changed' }
        ]

        model.st.push {c: false, d: e: 20}

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st[2]', code: 'added'}
        ]


        model.st.shift()

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st[0]', code: 'changed'}
          {type: 'warn', path: 'model.st[1]', code: 'changed'}
          {type: 'warn', path: 'model.st[2]', code: 'removed'}
        ]

        model.st = [
          {c: true, d: e: 12.21}
          {c: false, d: e: 24}
        ]

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st', code: 'changed'}
        ]

        model.st[1].d = e: 121

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st[1].d', code: 'changed'}
        ]

        model.st = null
        model.str = undefined

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st', code: 'removed', value: null}
          {type: 'warn', path: 'model.str', code: 'removed', value: undefined}
        ]

        model.st = [
          {c: true, d: e: 12.21}
          {c: false, d: e: 24}
        ]
        model.str =
          e: '2020-08-22'
          s: [
            {s2: f1: 12}
            {s2: f1: 24}
            {s2: f1: 36}
          ]

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st', code: 'added'}
          {type: 'warn', path: 'model.str', code: 'added'}
        ]

        watchFunc (result = new Result()), 12

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model', code: 'removed'}
        ]

        watchFunc = linkedConfig.docs['doc.Doc1'].fields.$$vueDebugWatchBuilder 'model'

        watchFunc (result = new Result()), 24

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model', code: 'missing'}
        ]

        watchFunc = linkedConfig.docs['doc.Doc1'].fields.$$vueDebugWatchBuilder 'model'

        watchFunc (result = new Result()), {}

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model.st', code: 'missing', value: undefined}
          {type: 'warn', path: 'model.str', code: 'missing', value: undefined}
        ]

        watchFunc (result = new Result()), model

        expect(result.messages).toEqual [
          {type: 'warn', path: 'model', code: 'changed'}
        ]
