Типы полей документов объявляемые пользователем
------------------------------

    {Result,
    config: {compile: {_processUdtypes: processUdtypes}}
    types: {compile: {_builtInTypes: builtInTypes, _reservedTypes: reservedTypes, _typeProps: typeProps}}} = require '../src'

    processDocs = require '../src/config/_processDocs'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return
    xcheck = (itName, itBody) -> return

    describe '051_config_udtypes_extraProps:', ->

      check "general", ->

        processUdtypes (result = new Result), res = $$src:

          udtypes:

            type1: type: 'string(20)', min: 10

            type2: type: 'type1', length: 15, min: 8

        expect(result.messages).toEqual []

        expect(res.udtypes.type1).toEqual
          name: 'type1'
          type: 'string'
          length: 20
          min: 10

        expect(res.udtypes.type2).toEqual
          name: 'type2'
          udType: 'type1'
          type: 'string'
          length: 15
          min: 8

      check "field with udt type", ->

        config = $$src:

          udtypes:

            type1: type: 'string(20)', min: 10

            type2: type: 'type1', length: 15, min: 8, init: '12345678'

            type3: enum: 'a, b, c', extra: {b: 2}

          docs:

            Doc1:

              fields:

                f1: type: 'type2', min: 12, length: 40, init: '123456789012'

                f2: type: 'type3', init: 'b', extra: {a: 1}

        result = new Result

        processUdtypes result, config

        processDocs result, config, true

        expect(result.messages).toEqual []

        expect(config.docs['doc.Doc1'].fields.f1).toEqual
          name: 'f1'
          $$index: 0
          udType: ['type2', 'type1']
          type: 'string'
          length: 40
          min: 12
          init: '123456789012'

        expect(config.docs['doc.Doc1'].fields.f2).toEqual
          name: 'f2'
          $$index: 1
          type: 'enum'
          enum: {a: {name: 'a'}, b: {name: 'b'}, c: {name: 'c'}, $$list: [{name: 'a'}, {name: 'b'}, {name: 'c'}]}
          init: 'b'
          udType: ['type3']
          extra: {b: 2, a: 1}
