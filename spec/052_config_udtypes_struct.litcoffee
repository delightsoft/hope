Типы полей документов объявляемые пользователем
------------------------------

    Result = require('../src/result')

    processUdtypes = require('../src/config/_processUdtypes')

    processUdtypeFields = require('../src/config/_processUdtypeFields')

    compile = require('../src/config/_compile')

    deepClone = require('../src/utils/_deepClone')

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return
    xcheck = (itName, itBody) -> return

    describe '052_config_udtypes_struct:', ->

      check 'general', ->

        _config =

          udtypes:

            email: type: 'string(20)'

            type1: fields:
              a: type: 'int'
              b: type: 'string(20)'

            type2: type: 'type1', fields:
              c: type: 'int'
              d: type: 'string(20)'

            type3: type: 'type1'

            type4:
              type: 'subtable'
              fields:
                x: type: 'email'
                y: type: 'type3'

          docs:

            Doc1:

              fields:
                f: type: 'type2', null: true, required: true
                h: type: 'type2', null: false, required: false
                i: type: 'type2', null: true, required: false
                p: type: 'type4', null: true, required: true

        config = $$src: deepClone _config

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

        config = deepClone _config

        res = compile result, config, true

    #        console.info 81, res.docs['doc.Doc1'].fields

        expect(result.messages).toEqual []

    #        expect(config.docs['doc.Doc1']).not.toEqual
    #
    #          name: 'doc.Doc1',
    #          fields:
    #            f: f =
    #              name: 'f',
    #              type: 'structure'
    #              required: true
    #              null: true
    #              udType: ['type2']
    #              '$$index': 0
    #              fields:
    #                c: f_c = name: 'c', type: 'integer', '$$index': 1
    #                d: f_d = name: 'd', type: 'string', length: 20, '$$index': 2
    #                $$list: [f_c, f_d]
    #            h: h = name: 'h', type: 'structure', udType: ['type2'], '$$index': 1
    #            i: i =
    #              name: 'i'
    #              type: 'structure'
    #              null: true
    #              udType: ['type2']
    #              '$$index': 2
    #            '$$list': [f],
    #            '$$flat': f: f, 'f.c': f_c, 'f.d': f_d, '$$list': [f, f_c, f_d]
    #            '$$tags': all: [f, f_c, f_d], none: [], required: []
    #          actions: '$$list': [], '$$tags': {none: [], all: []}
    #          states: '$$list': []
    #          '$$index': 0

# TODO: make fields in udtype
# TODO: check inheritance
# TODO: make ud struct type of doc fields
# TODO: make ud struct nullable
# TODO: make ud struct required
# TODO: inner dt types in fields
# TODO: validate is Ok with null: true, required: true struct struct/subtable
