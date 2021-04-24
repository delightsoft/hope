Типы полей документов объявляемые пользователем
------------------------------

    Result = require('../src/result')

    processUdtypes = require('../src/config/_processUdtypes')

    processUdtypeFields = require('../src/config/_processUdtypeFields')

    focusOnCheck = 'general'
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return
    xcheck = (itName, itBody) -> return

    describe '052_config_udtypes_struct:', ->

      check "", ->

        config = $$src:

          udtypes:

            type1: fields:
              a: type: 'int'
              b: type: 'string(20)'

            type2: type: 'type1', fields:
              c: type: 'int'
              d: type: 'string(20)'

            type3: type: 'type1'

          docs: {}

        processUdtypes (result = new Result), config

        processUdtypeFields result, config

        expect(result.messages).toEqual []

        expect(config.udtypes.type1).toEqual
          name: 'type1'
          type: 'structure'
          fields:
            a: a = name: 'a', type: 'integer'
            b: b = name: 'b', type: 'string', length: 20
            $$list: [a, b]

        expect(config.udtypes.type2).toEqual
          name: 'type2'
          type: 'structure'
          udType: 'type1',
          fields:
            c: c = name: 'c', type: 'integer'
            d: d = name: 'd', type: 'string', length: 20
            $$list: [c, d]

        expect(config.udtypes.type3).toEqual
          name: 'type3'
          type: 'structure'
          udType: 'type1',
          fields:
            a: a = name: 'a', type: 'integer'
            b: b = name: 'b', type: 'string', length: 20
            $$list: [a, b]

# TODO: make fields in udtype
# TODO: check inheritance
# TODO: make ud struct type of doc fields
# TODO: make ud struct nullable
# TODO: make ud struct required
# TODO: inner dt types in fields
