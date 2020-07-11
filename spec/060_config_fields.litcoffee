config.docs.Doc.fields
==============================

    {Result, utils: {deepClone}, config: {compile: {_processFields: processFields}}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "060_config_fields", ->

general
------------------------------

      check "general", ->

        doc =
          name: 'Doc1'
          $$src:
            fields:
              fld1: type: 'int', tags: 'tag1'
              fld2: type: 'string(20)', tags: 'tag1, tag2'
              fld3:
                fields:
                  a: type: 'json', tags: 'tag2'
                  b: type: 'date'

        $$src = deepClone doc.$$src

        (res = {}).fields = processFields (result = new Result), doc, {}, 'fields', true

        expect(result.messages).toEqual []

Исходный документ не изменяется

        expect(doc.$$src).sameStructure $$src

missing props
------------------------------

wrong values
------------------------------

unexpected props
------------------------------

