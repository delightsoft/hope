config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '071_config_helpers', ->

Модель документов, состоит из следующих элементов:
* Пользовательские типы (udtype)
* Описание документов
* Система прав, внутри документов
* Описание меню

      beforeEach ->

        @config =
          udtypes:
            t1: type: 'int'
            t2: type: 't1'
            t3: enum: 'a,b,c'
          docs:
            DocA:
              fields:
                fldA: refers: 'anamespace.DocB', extra: {f: 123}, tags: 'a, b, c'
                fldG: type: 'string(20)', tags: 'a'
                fldQ:
                  tags: 'c'
                  fields:
                    sa: type: 'timestamp'
                    sb: type: 't1', required: true, null: true
                    sc: type: 't3', required: true
                    sd:
                      tags: 'namespace.tag'
                      enum:
                        x: extra: {a:12}
                        y: {}
            'anamespace.DocB': # TODO: Process names with namespaces
              fields:
                fldA:
                  type: 'subtable'
                  fields:
                    f1: type: 'integer', init: 12
                    f2: type: 'string(20)', init: 'tralala'
                fldB:
                  type: 'subtable'
                  required: true,
                  fields:
                    f1: type: 'double'
                    f2: type: 'string(20)'
          api:
            api1:
              methods:
                methodA:
                  arguments:
                    a1: type: 'double', tags: 'x, y'
                    a2: type: 'date', tags: 'y'
                  result:
                    r:
                      fields:
                        x: type: 'string(20)'
                        y: type: 't2'

      # TODO: Validate

      check '$$calc', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, false

После линкиовки доступен метод $$calc на всех sortedMap у которых есть теги

        mask1 = linkedConfig.docs['doc.DocA'].fields.$$calc '#a - #b'

        expect(mask1.list).toEqual [linkedConfig.docs['doc.DocA'].fields.fldG]

        mask2 = linkedConfig.docs['doc.DocA'].fields.$$calc '#a - fldG'

        expect(mask2.list).toEqual [linkedConfig.docs['doc.DocA'].fields.fldA]

Ответы кешируются

        # expect(linkedConfig.docs['doc.DocA'].fields.$$calc '#a - #b').toEqual mask1

      check '$$new', ->

        res = compileConfig (result = new Result), @config, false

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, false

        newDoc = linkedConfig.docs['doc.DocA'].fields.$$new()

        expect(newDoc).toEqual

          fldA: null

          fldG: ''

          fldQ: sa: null, sb: null, sc: 'a', sd: 'x'

subtale с признаком required создаются с одной новой пустой записью

        newDoc = linkedConfig.docs['anamespace.DocB'].fields.$$new()

        expect(newDoc).toEqual

          fldA: [],

          fldB: [
            { f1: 0, f2: '' }
          ]

        newDoc = linkedConfig.docs['anamespace.DocB'].fields.$$new({edit: true})

        expect(newDoc).toEqual

          fldA: [],

          fldB: [
            {f1: 0, f2: '', $$touched: {}}
          ]

          $$touched: {}

записи для subtable можно создавать через $$new в поле типа subtable

        newRow = linkedConfig.docs['anamespace.DocB'].fields.fldA.fields.$$new()

        expect(newRow).toEqual

          f1: 12

          f2: 'tralala'

        newRow = linkedConfig.docs['anamespace.DocB'].fields.fldA.fields.$$new({edit: true})

        expect(newRow).toEqual

          f1: 12

          f2: 'tralala'

          $$touched: {}

      check 'fix subtable $$new', ->

        res = compileConfig (result = new Result),
          docs:
            DocA:
              fields:
                str: fields:
                  f1: type: 'string(20)'
                  f2: type: 'string(20)', null: true
                sf: type: 'subtable', required: true, fields:
                  f1: type: 'string(20)'
                  f2: type: 'string(20)', null: true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, false

        newDoc = linkedConfig.docs['doc.DocA'].fields.$$new()

        newDoc.str.f1 = 'a'
        newDoc.str.f2 = 'b'

        newDoc.sf[0].f1 = '123'
        newDoc.sf[0].f2 = '321'

        newDoc2 = linkedConfig.docs['doc.DocA'].fields.$$new()

        expect(newDoc2).toEqual
          str:
            f1: ''
            f2: null
          sf: [{
            f1: ''
            f2: null
          }]

        expect(linkedConfig.docs['doc.DocA'].fields.sf.fields.$$new()).toEqual
          f1: ''
          f2: null

      check '$$fix', ->

        res = compileConfig (result = new Result), {
          docs:
            DocA:
              fields:
                f1: type: 'string(20)', tags: 'a'
                f2: type: 'string(20)', null: true
                str: fields:
                  f3: type: 'string(20)', tags: 'a'
                  f4: type: 'string(20)', null: true
                sf: type: 'subtable', required: true, fields:
                  f5: type: 'string(20)', tags: 'a'
                  f6: type: 'string(20)', null: true
        }, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        res = linkedConfig.docs['doc.DocA'].fields.$$fix {
          f1: '123'
          f2: '321'
          str:
            f3: 'a'
            f4: 'b'
          sf: [
            {f5: 'c', f6: null}
            {f5: 'd', f6: 'e'}
          ]}, mask: linkedConfig.docs['doc.DocA'].fields.$$tags.a

        expect(res).toEqual
          f1: '123'
          str:
            f3: 'a'
          sf: [
            {f5: 'c'}
            {f5: 'd'}
          ]

        res = linkedConfig.docs['doc.DocA'].fields.$$fix {
          f1: '123'
          # missing - f2: '321'
          extra: '987'
          str:
            f3: 'a'
            # missing - f4: 'b'
            extra: '987'
          sf: [
            {f5: 'c', extra: '987'}
            {f5: 'd', extra: '987'}
          ]}, edit: true

        expect(res).toEqual
          f1: '123'
          f2: null
          $$touched: {}
          str:
            f3: 'a'
            f4: null
            $$touched: {}
          sf: [
            {_i: 0, f5: 'c', f6: null, $$touched: {}}
            {_i: 1, f5: 'd', f6: null, $$touched: {}}
          ]

      check '$$get', ->

        res = compileConfig (result = new Result), {
          docs:
            DocA:
              fields:
                f1: type: 'string(20)', tags: 'a'
                f2: type: 'string(20)', null: true
                str: fields:
                  f3: type: 'string(20)', tags: 'a'
                  f4: type: 'string(20)', null: true
                sf: type: 'subtable', required: true, fields:
                  f5: type: 'string(20)', tags: 'a'
                  f6: type: 'string(20)', null: true
        }, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        res = linkedConfig.docs['doc.DocA'].fields.$$get {
          f1: '123'
          f2: null
          $$touched: {}
          str:
            f3: 'a'
            f4: null
            $$touched: {}
          sf: [
            {f5: 'c', f6: null, $$touched: {}}
            {f5: 'd', f6: null, $$touched: {}}
          ]
        }, linkedConfig.docs['doc.DocA'].fields.$$calc('f1,str.f4,sf.f6')

        expect(res).toEqual
        f1: '123'
        str:
          f4: null
        sf: [
          {f6: null}
          {f6: null}
        ]

      check '$$set', ->

        res = compileConfig (result = new Result), {
          docs:
            DocA:
              fields:
                f1: type: 'string(20)', tags: 'a'
                f2: type: 'string(20)', null: true
                str: fields:
                  f3: type: 'string(20)', tags: 'a'
                  f4: type: 'string(20)', null: true
                sf: type: 'subtable', required: true, fields:
                  f5: type: 'string(20)', tags: 'a'
                  f6: type: 'string(20)', null: true
        }, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        res = linkedConfig.docs['doc.DocA'].fields.$$set {
          f1: '123'
          f2: null
          $$touched: {}
          str:
            f3: 'a'
            f4: null
            $$touched: {}
          sf: [
            {f5: 'c', f6: null, $$touched: {}}
            {f5: 'd', f6: null, $$touched: {}}
          ]
        }, {
          f2: '321',
          str:
            f4: 'b'
          sf: [
            {f5: 'e'}
            {_i: 1, f6: 'test'}
            {f6: 'f'}
          ]
        }

        expect(res).toEqual
          f1: '123'
          f2: '321'
          str:
            f3: 'a'
            f4: 'b'
          sf: [
            {f5: 'e', f6: null}
            {f5: 'd', f6: 'test'}
            {f5: '', f6: 'f'}
          ]

      check '$$set: new structure new subtable', ->

        res = compileConfig (result = new Result), {
          docs:
            DocA:
              fields:
                f1: type: 'string(20)', tags: 'a'
                f2: type: 'string(20)', null: true
                str: fields:
                  f3: type: 'string(20)', tags: 'a'
                  f4: type: 'string(20)', null: true
                sf: type: 'subtable', required: true, fields:
                  f5: type: 'string(20)', tags: 'a'
                  f6: type: 'string(20)', null: true
        }, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        res = linkedConfig.docs['doc.DocA'].fields.$$set {
          f1: '123'
          $$touched: {}
        }, {
          f2: '321',
          str:
            f4: 'b'
          sf: [
            {f5: 'e'}
            {_i: 1, f6: 'test'}
            {f6: 'f'}
          ]
        }

        expect(res).toEqual
          f1: '123'
          f2: '321'
          str:
            f3: ''
            f4: 'b'
          sf: [
            {f5: 'e', f6: null}
            {f5: '', f6: 'test'}
            {f5: '', f6: 'f'}
          ]

      check '$$get: _i', ->

        res = compileConfig (result = new Result), {
          docs:
            DocA:
              fields:
                f1: type: 'string(20)', tags: 'a'
                sf: type: 'subtable', required: true, fields:
                  f5: type: 'string(20)', tags: 'a'
                  f6: type: 'string(20)', null: true
        }, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        res = linkedConfig.docs['doc.DocA'].fields.$$get
          f1: '123'
          sf: [
            {f5: 'c', f6: null, $$touched: {}}
            {f5: 'd', f6: null, _i: 1, $$touched: {}}
          ]
          $$touched: {}

        expect(res).toEqual
          f1: '123'
          sf: [
            {f5: 'c', f6: null}
            {f5: 'd', f6: null, _i: 1}
          ]

        res = linkedConfig.docs['doc.DocA'].fields.$$get {
          f1: '123'
          sf: [
            {f5: 'c', f6: null, $$touched: {}}
            {f5: 'd', f6: null, _i: 1, $$touched: {}}
          ]
          $$touched: {}}, undefined, noIndex: true

        expect(res).toEqual
          f1: '123'
          sf: [
            {f5: 'c', f6: null}
            {f5: 'd', f6: null}
          ]
