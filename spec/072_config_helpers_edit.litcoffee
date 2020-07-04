config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '071_config_helpers_edit', ->

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
                    b: type: 'date', required: true
                  result:
                    r1: type: 'int', tags: 't1'
                    r2: type: 'double', required: true

        @code =

          docs:
            'doc.Doc1':
              access: (fields) -> view: this.fields.$$tags.t1, update: this.fields.$$tags.t1
              validate: (result, fields) -> result.error 'err1' if fields.f1 == 20; return

          api:
            api1:
              argAccess: (fields) -> view: fields.$$tags.t1, update: fields.$$tags.t1
              argValidate: (result, fields) -> result.error 'err2' if fields.a == 12; return
              resultAccess: (fields) -> view: fields.$$tags.t1, update: fields.$$tags.t1
              resultValidate: (result, fields) -> result.error 'err3' if fields.r2 == 2.4; return

      check 'general', ->

        res = compileConfig (result = new Result), @config

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(linkedConfig.docs['doc.Doc1'].$$access f1: 12, f2: 'test', f3: true).toEqual
          view: linkedConfig.docs['doc.Doc1'].fields.$$tags.t1
          update: linkedConfig.docs['doc.Doc1'].fields.$$tags.t1

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 12, f2: 'test', f3: true}, {strict: true}).toEqual save: false, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.unexpectedField', name: 'f3', value: true}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 12, f2: 'test', f3: true}).toEqual save: true, submit: true

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 20, f2: 'test', f3: true}).toEqual save: true, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'err1'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 'wrong'}).toEqual save: false, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.invalidValue', value: 'wrong'}
          {type: 'error', code: 'validate.requiredField', value: 'f2'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 20}).toEqual save: true, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.requiredField', value: 'f2'}
        ]

        # TODO: method arg validate
        # TODO: method arg access
        # TODO: method result validate
        # TODO: method result access
