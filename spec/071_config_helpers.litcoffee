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
                    sa: type: 'date'
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
                    a2: type: 'dateonly', tags: 'y'
                  result:
                    r:
                      fields:
                        x: type: 'string(20)'
                        y: type: 't2'

      # TODO: Validate

      check '$$calc', ->

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, false

После линкиовки доступен метод $$calc на всех sortedMap у которых есть теги

        mask1 = linkedConfig.docs['doc.DocA'].fields.$$calc '#a - #b'

        expect(mask1.list).toEqual [linkedConfig.docs['doc.DocA'].fields.fldG]

        mask2 = linkedConfig.docs['doc.DocA'].fields.$$calc '#a - fldG'

        expect(mask2.list).toEqual [linkedConfig.docs['doc.DocA'].fields.fldA]

Ответы кешируются

        expect(linkedConfig.docs['doc.DocA'].fields.$$calc '#a - #b').toEqual mask1

      check '$$new', ->

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, false

        newDoc = linkedConfig.docs['doc.DocA'].fields.$$new()

        expect(newDoc).toEqual

          fldA: null

          fldG: ''

          fldQ: sa: null, sb: 0, sc: 'a', sd: 'x'

subtale с признаком required создаются с одной новой пустой записью

        newDoc = linkedConfig.docs['anamespace.DocB'].fields.$$new()

        expect(newDoc).toEqual

          fldA: [],

          fldB: [
            { f1: 0, f2: '' }
          ]

записи для subtable можно создавать через $$new в поле типа subtable

        newRow = linkedConfig.docs['anamespace.DocB'].fields.fldA.fields.$$new()

        expect(newRow).toEqual

          f1: 12

          f2: 'tralala'
