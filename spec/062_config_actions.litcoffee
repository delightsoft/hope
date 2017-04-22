config.docs.Doc.fields
==============================

    {Result, config: {compile: {_processActions: processActions}}, utils: {deepClone}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "062_config_actions", ->

general
------------------------------

      check "general", ->

        doc =
          name: 'Doc1'
          $$src:
            actions:
              actionA: {value: ->}
              actionB: ->
              actionC: {name: 'actionC', value: (->), tags: 'a, b'}

        $$src = deepClone doc.$$src

        (res = {}).fields = processActions (result = new Result), doc

        expect(result.messages).toEqual []

Исходный документ не изменяется

        expect(doc.$$src).sameStructure $$src

missing props
------------------------------

wrong values
------------------------------

unexpected props
------------------------------

