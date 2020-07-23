config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '073_config_system_fields_and_actions', ->

      beforeEach ->

        @config =

          docs:
            Doc1:
              fields:
                f1: type: 'int', tags: 't1'
                f2: type: 'string(20)', tags: 't1', required: true
                f3: type: 'boolean', required: true

          api:
            api1:
              methods:
                method1:
                  arguments:
                    a: type: 'int', tags: 't1', required: true
                    b: type: 'timestamp', required: true
                  result:
                    r1: type: 'int', tags: 't1'
                    r2: type: 'double', required: true

      check 'general', ->

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(Object.keys(deepClone(linkedConfig.docs['doc.Doc1'].fields))).toEqual ['id', 'rev', 'f1', 'f2', 'f3', 'options', 'created', 'modified', 'deleted']

        expect(Object.keys(deepClone(linkedConfig.docs['doc.Doc1'].actions))).toEqual ['create', 'retrieve', 'update', 'delete', 'restore']

        expect(Object.keys(deepClone(linkedConfig.api['api1'].methods['method1'].arguments))).toEqual ['a', 'b']

        expect(Object.keys(deepClone(linkedConfig.api['api1'].methods['method1'].result))).toEqual ['r1', 'r2']
