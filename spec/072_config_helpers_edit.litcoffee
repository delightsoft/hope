config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = 'subtable in edit validator with required mask'
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
              actions:
                action1:
                  arguments:
                    a1: type: 'int', required: true
                    a2: type: 'string(20)', required: true
                    a3: type: 'text'
                  result:
                    r1: type: 'int', required: true
                    r2: type: 'string(20)', required: true
                    r3: type: 'text'

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
              access: ({view, update, actions, required}) ->
                view.set '#t1'
                update.set '#t1'
                return
              validate: (result, fields) ->
                result.error 'err1' if fields.f1 == 20
                result.error (-> 'f2.f3[0]'), 'err2' if fields.f1 == 30
                result.error (-> 'f1'), 'err3' if fields.f1 == 40
                result.error (-> 'f2'), 'err4' if fields.f1 == 40
                return

          api:
            api1:
              method1:
                argAccess: ({view, update, required}) ->
                  view.set '#t1'
                  update.set '#t1'
                  return
                argValidate: (result  , fields) -> result.error 'err2' if fields.a == 12; return
                resultAccess: ({view, update, required}) ->
                  view.set '#t1'
                  update.set '#t1'
                  return
                resultValidate: (result, fields) -> result.error 'err3' if fields.r2 == 2.4; return

      check 'required in action arguments', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        linkedConfig.docs['doc.Doc1'].actions['action1'].arguments.$$validate (result = new Result),

          {a1: 12, a3: false}, {beforeAction: true}

        expect(result.messages).toEqual [
          {type: 'error', path: 'a3', code: 'validate.invalidValue', value: false}
          {type: 'error', path: 'a2', code: 'validate.requiredField'}
        ]

      check 'general', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        access = linkedConfig.docs['doc.Doc1'].$$access f1: 12, f2: 'test', f3: true

        delete access.modify
        access.view.list
        access.update.list
        access.required.list
        access.actions.list
        expect(access).toEqual
          view: linkedConfig.docs['doc.Doc1'].fields.$$tags.t1
          update: linkedConfig.docs['doc.Doc1'].fields.$$tags.t1
          required: linkedConfig.docs['doc.Doc1'].fields.$$tags.required
          actions: linkedConfig.docs['doc.Doc1'].actions.$$tags.all

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 12, f2: 'test', f3: true}, {strict: true}).toEqual save: false, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.unexpectedField', path: 'f3', value: true}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 12, f2: 'test', f3: true}, {beforeAction: true, strict: false}).toEqual save: true, goodForAction: true

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 20, f2: 'test', f3: true}, {beforeAction: true, strict: false}).toEqual save: true, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'err1'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 'wrong'}, {
          beforeAction: true
        }).toEqual save: false, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.invalidValue', path: 'f1', value: 'wrong'}
          {type: 'error', code: 'validate.requiredField', path: 'f2'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 20}, {
          beforeAction: true
        }).toEqual save: true, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.requiredField', path: 'f2'}
          {type: 'error', code: 'err1'}
        ]

      check 'edit validate builder', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {f1: 12, f2: 'test', f3: true}).toEqual save: true, goodForAction: false, messages: {}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {f1: 'wrong'}, {
          beforeAction: true
        }).toEqual
          save: false, goodForAction: false, messages:
            f1: type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'
            f2: {type: 'error', code: 'validate.requiredField', path: 'f2'}

        expect(-> linkedConfig.docs['doc.Doc1'].$$editValidate {f1: 'wrong'}, {test: 12, beforeBuild: false}).toThrow new Error "Unknown option: 'test'"

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          f1: 'wrong'
          f2: 12
          $$touched: {f2: true}
        }, {
          beforeAction: true
        }).toEqual
          save: false, goodForAction: false, messages:
            f1: type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'
            f2: {type: 'error', path: 'f2', code: 'validate.invalidValue', value: 12}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          f1: 'wrong'
          f2: 12
          $$touched: {f2: true}
        }, {
          beforeAction: false
        }).toEqual
          save: false, goodForAction: false, messages:
            f2: {type: 'error', path: 'f2', code: 'validate.invalidValue', value: 12}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          f1: 20
          f2: 'right'
          $$touched: {f1: true}
        }, {
          beforeAction: true
        }).toEqual
          save: true, goodForAction: false, messages:
            '': [{ type: 'error', code: 'err1' }]

        editValidate = linkedConfig.docs['doc.Doc1'].$$editValidate

        model =
          f1: 20
          f2: 'right'
          $$touched: {f1: true}

        expect(editValidate model, {
          beforeAction: true
        })
          .toEqual
          save: true, goodForAction: false, messages:
            '': [{type: 'error', code: 'err1'}]

        model.f1 = 'wrong'

        expect(editValidate model, {
          beforeAction: false
        }).toEqual
          save: false, goodForAction: false, messages:
            f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}

        expect(editValidate deepClone model, {
          beforeAction: false
        }).toEqual
          save: false, goodForAction: false, messages:
            f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          f1: 30
          f2: 'right'
        }, {
          beforeAction: true
        }).toEqual
          save: true, goodForAction: false, messages:
            'f2.f3[0]': {type: 'error', path: 'f2.f3[0]', code: 'err2'}

        editValidate = linkedConfig.docs['doc.Doc1'].$$editValidate

        model =
          f1: 40
          f2: 'right'
          $$touched: {f1: true}

        expect(editValidate model, {
          beforeAction: true
        }).toEqual
          save: true,
          goodForAction: false,
          messages:
            f1: {type: 'error', path: 'f1', code: 'err3'}
            f2: {type: 'error', path: 'f2', code: 'err4'}

        model.f1 = 'wrong'

        expect(editValidate model, {
          beforeAction: true
        }).toEqual
          save: false,
          goodForAction: false,
          messages:
            f1: {type: 'error', path: 'f1', code: 'validate.invalidValue', value: 'wrong'}

        model.f1 = 20

        expect(editValidate model, {
          beforeAction: true
        }).toEqual
          save: true,
          goodForAction: false,
          messages:
            '': [{type: 'error', code: 'err1'}]

      check 'edit validate builder on methods', ->

        res = compileConfig (result = new Result), @config, true

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, @code

        expect(linkedConfig.api['api1'].methods['method1'].arguments.$$editValidate {a: 12}, {beforeAction: true}).toEqual save: true, goodForAction: false, messages: {
          '': [{type: 'error', code: 'err2'}]
        }

        expect(linkedConfig.api['api1'].methods['method1'].result.$$editValidate {r2: 2.4}, {beforeAction: true}).toEqual save: true, goodForAction: false, messages: {
          '': [{type: 'error', code: 'err3'}]
        }

        expect(linkedConfig.api['api1'].methods['method1'].arguments.$$editValidate {a: 0}, {beforeAction: true}).toEqual save: true, goodForAction: true, messages: {}

        expect(linkedConfig.api['api1'].methods['method1'].result.$$editValidate {r1: 1}, {beforeAction: true}).toEqual save: true, goodForAction: true, messages: {}

      check 'required empty string', ->

        res = compileConfig (result = new Result), {
          docs:
            Doc1:
              fields:
                f1: type: 'string(40)'
                f2: type: 'string(20)', required: true
        }, true

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, docs: 'doc.Doc1': access: (fields) ->
          view: @fields.$$tags.all
          update: @fields.$$tags.all
          required: @fields.$$tags.required
          access: @actions.$$tags.all

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {f1: '', f2: ''}, {
          beforeAction: true
        }).toEqual
          save: true
          goodForAction: false
          messages:
            f2: {type: 'error', path: 'f2', code: 'validate.requiredField'}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          f1: '',
          f2: '',
          $$touched: f1: true, f2: true
        }, {
          beforeAction: false
        }).toEqual
          save: true
          goodForAction: false
          messages: {}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          f1: '',
          f2: '',
          $$touched: f1: false, f2: false
        }, {
          beforeAction: true
        }).toEqual
          save: true
          goodForAction: false
          messages:
            f2: {type: 'error', path: 'f2', code: 'validate.requiredField'}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          $$touched: f1: false, f2: false
        }, {
          beforeAction: false
        }).toEqual
          save: true
          goodForAction: false
          messages: {}

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          $$touched: f1: false, f2: false
        }, {
          beforeAction: true
        }).toEqual
          save: true
          goodForAction: false
          messages:
            f2: {type: 'error', path: 'f2', code: 'validate.requiredField'}

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

        linkedConfig = linkConfig unlinkedConfig, docs: 'doc.Doc1': access: (fields) ->
          view: @fields.$$tags.all
          update: @fields.$$tags.all
          required: @fields.$$tags.required
          access: @actions.$$tags.all

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate st: [{f1: '', f2: ''}]).toEqual save: true, goodForAction: false, messages: {
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          st: [{f1: '', f2: ''}]
          $$touched: f1: true, f2: true
        }, {beforeAction: false}).toEqual save: true, goodForAction: false, messages: {
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          st: [{f1: '', f2: '', $$touched: f1: true, f2: true}, {f1: null, f2: 12, $$touched: f1: true, f2: true}]
          $$touched: {}
        }, {
          beforeAction: true
        })
        .toEqual save: false, goodForAction: false, messages: {
          'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
          'st[1].f1': {type: 'error', path: 'st[1].f1', code: 'validate.invalidValue', value: null}
          'st[1].f2': {type: 'error', path: 'st[1].f2', code: 'validate.invalidValue', value: 12}
          'st[0].f3': {type: 'error', path: 'st[0].f3', code: 'validate.requiredField'}
          'st[1].f3': {type: 'error', path: 'st[1].f3', code: 'validate.requiredField'}
        }

      check 'subtable in edit validator with required mask', ->

        res = compileConfig (result = new Result), {
          docs:
            Doc1:
              fields:
                st: type: 'subtable', fields:
                  f1: type: 'string(40)'
                  f2: type: 'string(20)'
                  f3: type: 'int', required: true
        }, true

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, docs: 'doc.Doc1': access: ->
          view: @fields.$$tags.all
          update: @fields.$$tags.all
          actions: @actions.$$tags.all
          required: @fields.$$calc('st.f2, st.f3')

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate st: [{f1: '', f2: ''}]).toEqual save: true, goodForAction: false, messages: {
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate {
          st: [{f1: '', f2: '', $$touched: f1: true, f2: true}]
          $$touched: {}
        }, {beforeAction: false}).toEqual save: true, goodForAction: false, messages: {
        }

        expect(linkedConfig.docs['doc.Doc1'].$$editValidate
          st: [
            {f1: '', f2: '', $$touched: f1: true, f2: true}
            {f1: null, f2: 12, $$touched: f1: true, f2: true}
          ]
          $$touched: {}

        , {beforeAction: true})

          .toEqual save: false, goodForAction: false, messages: {
            'st[0].f2': {type: 'error', path: 'st[0].f2', code: 'validate.requiredField'}
            'st[0].f3': {type: 'error', path: 'st[0].f3', code: 'validate.requiredField'}
            'st[1].f1': {type: 'error', path: 'st[1].f1', code: 'validate.invalidValue', value: null}
            'st[1].f2': {type: 'error', path: 'st[1].f2', code: 'validate.invalidValue', value: 12}
            'st[1].f3': {type: 'error', path: 'st[1].f3', code: 'validate.requiredField'}
          }
