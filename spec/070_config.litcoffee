config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '070_config', ->

Модель документов, состоит из следующих элементов:
* Пользовательские типы (udtype)
* Описание документов
* Система прав, внутри документов
* Описание меню

      beforeEach ->

        @config =
          # TODO: Menu
          udtypes:
            t1: type: 'int'
            t2: type: 't1', extra: {a:0, b:0}
            t3: enum: 'a,b,c'
            t4: type: 't2', extra: {a:1}
          docs:
            DocA:
              fields:
                fldA: refers: 'anamespace.DocB', extra: {f: 123} # TODO: Process refers
                fldG: type: 'string(20)', tags: 'a'
                fldQ:
                  fields:
                    sa: type: 'timestamp'
                    sb: type: 't4', required: true, null: true, extra: {b:2}
                    sc: type: 't3', required: true
                    sd:
                      tags: 'namespace.tag'
                      enum:
                        x: extra: {a:12}
                        y: {}
              actions:
                close: {}
                open: {}
                list:
                  arguments:
                    z: type: 'int', tags: 'a'
                    x: type: 'string(20)', null: true

              states:
                opened:
                  update: 'fldA'
                  transitions:
                    close: 'closed'
                closed:
                  view: 'fldA, fldG'
                  transitions:
                    open: 'opened'
            # TODO: Rights
            'anamespace.DocB': # TODO: Process names with namespaces
              fields:
                fldA: refers: 'doc.DocA'
                fldB: type: 'string(20)'
                fldC: refers: ['doc.DocA']
                fldD: refers: '#all'
                fldT: type: 't2'
          api:
            api1:
              extra: t: '321'
              methods:
                methodA:
                  tags: 'a, b'
                  extra: a: 12, b: '123'
                  arguments:
                    a1: type: 'double', tags: 'x, y'
                    a2: type: 'date', tags: 'y'
                  result:
                    r:
                      fields:
                        x: type: 'string(20)'
                        y: type: 't2'
            api2: {methods: []} # nothing


      check 'general', ->

Документы задаются в виде sortedMap в элементе docs.  Namespace'ы документов, указываются в именах элементов.

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        docA = res.docs['doc.DocA']

Документы в docs.$$list должны быть в альфавитном порядке

        expect(res.docs.$$list[0].name).toBe 'anamespace.DocB'

Если документ был указан в корне без namespace'а - то он помещается в стандартный namespace 'doc'.

        expect(res.docs.$$list[1].name).toBe 'doc.DocA'

        expect(res.docs['doc.DocA'].fields['fldQ'].fields['sb'].extra).toEqual {a: 1, b: 2}

      check 'unlink/link', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, true

        expect(linkedConfig).sameStructure res
