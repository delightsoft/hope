Типы полей документов объявляемые пользователем
------------------------------

    {Result,
    config: {compile: {_processUdtypes: processUdtypes}}
    types: {compile: {_builtInTypes: builtInTypes, _reservedTypes: reservedTypes, _typeProps: typeProps}}} = require '../src'

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
