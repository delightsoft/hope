config.docs.Doc.fields
==============================

    {Result, config: {compile: {_processActions: processActions}}, utils: {deepClone}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "062_config_actions", ->

general
------------------------------

      check "general", ->

        doc =
          name: 'Doc1'
          $$src:
            actions:
              actionA: {}
              actionB:
                arguments:
                  f1: type: 'string(20)', null: true, tags: 'a'
                  f2: type: 'subtable', fields:
                    fa: type: 'int'
                    fb: type: 'double', null: true, tags: 'a'
              actionC: {name: 'actionC', tags: 'a, b'}

        $$src = deepClone doc.$$src

        (res = {}).actions = processActions (result = new Result), doc, {}

        expect(result.messages).toEqual []

Исходный документ не изменяется

        expect(doc.$$src).sameStructure $$src

missing props
------------------------------

wrong values
------------------------------

unexpected props
------------------------------

