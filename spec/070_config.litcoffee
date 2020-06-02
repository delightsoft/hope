config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "070_config", ->

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
            t2: type: 't1'
          docs:
            DocA:
              fields:
                fldA: {refers: 'anamespace.DocB'} # TODO: Process refers
                fldG: {type: 'string(20)', tags: 'a'}
              actions:
                close: -> a = 12; return
                open: -> return
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
                fldA: {refers: 'doc.DocA'}
                fldB: {type: 'string(20)'}
                fldC: {refers: ['doc.DocA']}
                fldD: {refers: '#all'}
                fldT: {type: 't2'}

      check 'general', ->

Документы задаются в виде sortedMap в элементе docs.  Namespace'ы документов, указываются в именах элементов.

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

        docA = res.docs['doc.DocA']

Документы в docs.$$list должны быть в альфавитном порядке

        expect(res.docs.$$list[0].name).toBe 'anamespace.DocB'

Если документ был указан в корне без namespace'а - то он помещается в стандартный namespace 'doc'.

        expect(res.docs.$$list[1].name).toBe 'doc.DocA'

      check 'unlink', ->

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

      check 'link', ->

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig

        expect(linkedConfig).sameStructure res
