config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '072_config_helpers_edit', ->

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

        @code =

          docs:
            'doc.Doc1':
              access: (fields) -> view: this.fields.$$tags.t1, update: this.fields.$$tags.t1
              validate: (result, fields) ->
                result.error 'err1' if fields.f1 == 20
                result.error (-> 'f2.f3[0]'), 'err2' if fields.f1 == 30
                result.error (-> 'f1'), 'err3' if fields.f1 == 40
                result.error (-> 'f2'), 'err4' if fields.f1 == 40
                return

          api:
            api1:
              method1:
                argAccess: (fields) -> view: this.$$tags.t1, update: this.$$tags.t1
                argValidate: (result  , fields) -> result.error 'err2' if fields.a == 12; return
                resultAccess: (fields) -> view: this.$$tags.t1, update: this.$$tags.t1
                resultValidate: (result, fields) -> result.error 'err3' if fields.r2 == 2.4; return

      check 'general', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(linkedConfig.docs['doc.Doc1'].$$access f1: 12, f2: 'test', f3: true).toEqual
          view: linkedConfig.docs['doc.Doc1'].fields.$$tags.t1
          update: linkedConfig.docs['doc.Doc1'].fields.$$tags.t1

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 12, f2: 'test', f3: true}, {strict: true}).toEqual save: false, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.unexpectedField', path: 'f3', value: true}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 12, f2: 'test', f3: true}).toEqual save: true, submit: true

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 20, f2: 'test', f3: true}).toEqual save: true, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'err1'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 'wrong'}).toEqual save: false, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.invalidValue', path: 'f1', value: 'wrong'}
          {type: 'error', code: 'validate.requiredField', path: 'f2'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 20}).toEqual save: true, submit: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.requiredField', path: 'f2'}
        ]

      check 'edit validate builder', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {f1: 12, f2: 'test', f3: true}).toEqual save: true, submit: true, messages: {}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {f1: 'wrong'}).toEqual
          save: false, submit: false, messages:
            f1: type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'
            f2: {type: 'error', code: 'validate.requiredField', path: 'f2'}

        expect(-> linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {f1: 'wrong'}, {test: 12, beforeBuild: false}).toThrow new Error "Unknown option; 'test'"

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          f1: 'wrong'
          f2: 12
          $$touched: {f2: true}
        }, {beforeSubmit: true}).toEqual
          save: false, submit: false, messages:
            f2: {type: 'error', path: 'f2', code: 'validate.invalidValue', value: 12}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          f1: 'wrong'
          f2: 12
          $$touched: {f2: true}
        }, {beforeSubmit: false}).toEqual
          save: false, submit: false, messages:
            f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}
            f2: {type: 'error', path: 'f2', code: 'validate.invalidValue', value: 12}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          f1: 20
          f2: 'right'
          $$touched: {f1: true}
        }, {beforeSubmit: true}).toEqual
          save: true, submit: true, messages: {}

        editValidate = linkedConfig.docs['doc.Doc1'].$$editValidateBuilder()

        model =
          f1: 20
          f2: 'right'
          $$touched: {f1: true}

        expect(editValidate model, {beforeSubmit: false}).toEqual
          save: true, submit: false, messages:
            '': [{type: 'error', code: 'err1'}]

        model.f1 = 'wrong'

        expect(editValidate model, {beforeSubmit: false}).toEqual
          save: false, submit: false, messages:
            '': [{type: 'error', code: 'err1'}]
            f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}

        expect(editValidate deepClone model, {beforeSubmit: false}).toEqual
          save: false, submit: false, messages:
            f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          f1: 30
          f2: 'right'
        }, {beforeSubmit: false}).toEqual
          save: true, submit: false, messages:
            'f2.f3[0]': {type: 'error', path: 'f2.f3[0]', code: 'err2'}

        editValidate = linkedConfig.docs['doc.Doc1'].$$editValidateBuilder()

        model =
          f1: 40
          f2: 'right'
          $$touched: {f1: true}

        expect(editValidate model, {beforeSubmit: false}).toEqual
        save: false, submit: false, messages:
          f1: {type: 'error', code: 'err3'}
          f2: {type: 'error', code: 'err4'}

        model.f1 = 'wrong'

        expect(editValidate model, {beforeSubmit: false}).toEqual
        save: false, submit: false, messages:
          f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}
          f2: {type: 'error', code: 'err4'}

        model.f1 = 20

        expect(editValidate model, {beforeSubmit: false}).toEqual
        save: false, submit: false, messages:
          '': [{type: 'error', code: 'err1'}]

      check 'edit validate builder on methods', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(linkedConfig.api['api1'].methods['method1'].arguments.$$editValidateBuilder() {a: 12}).toEqual save: true, submit: false, messages: {
          '': [{type: 'error', code: 'err2'}]
        }

        expect(linkedConfig.api['api1'].methods['method1'].result.$$editValidateBuilder() {r2: 2.4}).toEqual save: true, submit: false, messages: {
          '': [{type: 'error', code: 'err3'}]
        }

        expect(linkedConfig.api['api1'].methods['method1'].arguments.$$editValidateBuilder() {a: 0}).toEqual save: true, submit: true, messages: {}

        expect(linkedConfig.api['api1'].methods['method1'].result.$$editValidateBuilder() {r1: 1}).toEqual save: true, submit: true, messages: {}

      check 'required emty string in before edit', ->

        res = compileConfig (result = new Result), {
          docs:
            Doc1:
              fields:
                f1: type: 'string(40)'
                f2: type: 'string(20)', required: true
        }, true

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {f1: '', f2: ''}).toEqual save: true, submit: false, messages: {
          f2: {type: 'error', path: 'f2', code: 'validate.requiredField'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          f1: '',
          f2: '',
          $$touched: f1: true, f2: true
        }, {beforeSubmit: false}).toEqual save: true, submit: false, messages: {
          f2: {type: 'error', path: 'f2', code: 'validate.requiredField'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          f1: '',
          f2: '',
          $$touched: f1: false, f2: false
        }, {beforeSubmit: true}).toEqual save: true, submit: true, messages: {}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          $$touched: f1: false, f2: false
        }, {beforeSubmit: false}).toEqual save: true, submit: false, messages: {
          f2: {type: 'error', code: 'validate.requiredField', path: 'f2'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          $$touched: f1: false, f2: false
        }, {beforeSubmit: true}).toEqual save: true, submit: true, messages: {}

      check 'subtable in before edit', ->

        res = compileConfig (result = new Result), {
          docs:
            Doc1:
              fields:
                st: type: 'subtable', fields:
                  f1: type: 'string(40)'
                  f2: type: 'string(20)', required: true
                  f3: type: 'int', required: true
        }, true

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() st: [{f1: '', f2: ''}]).toEqual save: true, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[0].f3': {type: 'error', path: 'st[0].f3', code: 'validate.requiredField'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          st: [{f1: '', f2: ''}]
          $$touched: f1: true, f2: true
        }, {beforeSubmit: false}).toEqual save: true, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[0].f3': {type: 'error', path: 'st[0].f3', code: 'validate.requiredField'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          st: [{f1: '', f2: '', $$touched: f1: true, f2: true}, {f1: null, f2: 12, $$touched: f1: true, f2: true}]
          $$touched: {}
        }, {beforeSubmit: true}).toEqual save: false, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[1].f1': {type: 'error', path: 'st[1].f1', code: 'validate.invalidValue', value: null}
          'st[1].f2': {type: 'error', path: 'st[1].f2', code: 'validate.invalidValue', value: 12}
        }

      check 'remember prev business msgs', ->

        res = compileConfig (result = new Result), {
          docs:
            Doc1:
              fields:
                st: type: 'subtable', fields:
                  f1: type: 'string(40)'
                  f2: type: 'string(20)', required: true
                  f3: type: 'int', required: true
        }, true

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, docs: 'doc.Doc1': validate: (result, doc) ->
          unless doc.st[0].f2 == 'ok'
            result.error (-> 'st[0].f2'), 'business err'
            result.warn (-> 'st[0].f1'), 'business warn'

        expect(result.messages).toEqual []

        $$editValidate = linkedConfig.docs['doc.Doc1'].$$editValidateBuilder()

        expect($$editValidate {
          st: [{f1: '', f2: 123, $$touched: f1: true, f2: true}]
        }, {beforeSubmit: true}).toEqual save: false, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.invalidValue', value: 123}
        }

        expect($$editValidate {
          st: [{f1: '', f2: '', $$touched: f1: true, f2: true}]
        }, {beforeSubmit: true}).toEqual save: true, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
        }

        model = { # если модель меняется между вызовами $$editValidate, то бизнес ошибки сбрасываются
          st: [{f1: 'ok1', f2: 'ok2', $$touched: f1: true, f2: true}]
        }

        expect($$editValidate model, {beforeSubmit: false}).toEqual save: true, submit: false, messages: {
          'st[0].f1': { type: 'warn', path: 'st[0].f1', code: 'business warn'}
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'business err'}
        }

        model.st[0].f2 = 123

        expect($$editValidate model, {beforeSubmit: false}).toEqual save: false, submit: false, messages: {
          'st[0].f1': {type: 'warn', path: 'st[0].f1', code: 'business warn'}
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.invalidValue', value: 123}
        }

        model.st[0].f2 = 'ok'

        expect($$editValidate model, {beforeSubmit: false}).toEqual save: true, submit: true, messages: {}

      check 'subtable in before edit with reqired mask', ->

        res = compileConfig (result = new Result), {
          docs:
            Doc1:
              fields:
                st: type: 'subtable', fields:
                  f1: type: 'string(40)'
                  f2: type: 'string(20)'
                  f3: type: 'int'
        }, true

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, docs: 'doc.Doc1': access: ->
          view: this.fields.$$tags.all
          update: this.fields.$$tags.all
          actions: this.actions.$$tags.all
          required: this.fields.$$calc('st.f2, st.f3')

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() st: [{f1: '', f2: ''}]).toEqual save: true, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[0].f3': {type: 'error', path: 'st[0].f3', code: 'validate.requiredField'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          st: [{f1: '', f2: ''}]
          $$touched: f1: true, f2: true
        }, {beforeSubmit: false}).toEqual save: true, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[0].f3': {type: 'error', path: 'st[0].f3', code: 'validate.requiredField'}
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidateBuilder() {
          st: [{f1: '', f2: '', $$touched: f1: true, f2: true}, {f1: null, f2: 12, $$touched: f1: true, f2: true}]
          $$touched: {}
        }, {beforeSubmit: true}).toEqual save: false, submit: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[1].f1': {type: 'error', path: 'st[1].f1', code: 'validate.invalidValue', value: null}
          'st[1].f2': {type: 'error', path: 'st[1].f2', code: 'validate.invalidValue', value: 12}
        }
