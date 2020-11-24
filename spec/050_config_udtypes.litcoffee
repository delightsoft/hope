Типы полей документов объявляемые пользователем
------------------------------

    {Result,
    config: {compile: {_processUdtypes: processUdtypes}}
    types: {compile: {_builtInTypes: builtInTypes, _reservedTypes: reservedTypes, _typeProps: typeProps}}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return
    xcheck = (itName, itBody) -> return

    describe '050_config_udtypes:', ->

      check "correct", ->

        conf = $$src:

          udtypes:

            strBased: type: 'string(20)'

            intBased: type: 'int'

            currency: type: 'intBased'

        processUdtypes (result = new Result), conf

        expect(result.messages).toEqual []

        expect(conf.udtypes).sameStructure

          strBased: strBased = name: 'strBased', type: 'string', length: 20

          intBased: intBased = name: 'intBased', type: 'integer'

          currency: currency = name: 'currency', type: 'integer', udType: 'intBased'

          $$list: [strBased, intBased, currency]

      check "cycled", ->

        conf = $$src:

          udtypes:

            one: type: 'two'

            two: type: 'one'

            a: type: 'c'

            b: type: 'a'

            c: type: 'b'

        processUdtypes (result = new Result), conf

        expect(result.messages).toEqual [
          {type: 'error', path: 'udtypes', code: 'dsc.cycledUdtypes', value: ['one', 'two']}
          {type: 'error', path: 'udtypes', code: 'dsc.cycledUdtypes', value: ['a', 'c', 'b']}]

        expect(conf.udtypes).not.toBeDefined()

    #      check 'subtable udtype', ->
    #
    #        conf = $$src:
    #
    #          udtypes:
    #
    #            a:
    #
    #              fields:
    #
    #                f1: type: 'int'
    #
    #                f2: type: 'string(20)'
    #
    #        processUdtypes (result = new Result), conf
    #
    #        expect(result.messages).toEqual []

        #        expect(conf.udtypes).sameStructure {}

      check 'structure udtype', ->

        # TODO:

      check 'dsvalue', ->

        conf = $$src:

          udtypes:

            one: type: 'value'

            two: type: 'dsvalue'

        processUdtypes (result = new Result), conf

        expect(result.messages).toEqual []

        expect(conf.udtypes).sameStructure

          one: one = name: 'one', type: 'dsvalue'

          two: two = name: 'two', type: 'dsvalue'

          $$list: [one, two]

      for type in builtInTypes

        do (type) -> check "error: built-in type name: '#{type}'", ->

          (((conf = {}).$$src = {}).udtypes = {})[type] = type: 'int'

          processUdtypes (result = new Result), conf

          expect(result.messages).toEqual [{type: 'error', path: "udtypes.#{type}", code: 'dsc.builtInTypeName'}]

          expect(conf.udtypes).not.toBeDefined()

      for type in reservedTypes

        do (type) -> check "error: reserved type name: '#{type}'", ->

          (((conf = {}).$$src = {}).udtypes = {})[type] = type: 'int'

          processUdtypes (result = new Result), conf

          expect(result.messages).toEqual [{type: 'error', path: "udtypes.#{type}", code: 'dsc.reservedTypeName'}]

          expect(conf.udtypes).not.toBeDefined()
