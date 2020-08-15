config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    processCustomValidate = require '../src/validate/processCustomValidate'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '075_config_fields_required_validate', ->

      check 'required - not null with beforeAction flag = true', ->

        res = compileConfig (result = new Result),

          docs: Doc1: fields:

            a: type: 'string(20)', required: true

            b: type: 'int', required: true, null: true

            c: type: 'int'

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig(res)

        linkedConfig = linkConfig unlinkedConfig, false

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {a: 'test', b: 24, c: 36}, {beforeAction: false}).toEqual
          save: true, goodForAction: false

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {}, {beforeAction: true}).toEqual
          save: true, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', path: 'a', code: 'validate.requiredField'}
          {type: 'error', path: 'b', code: 'validate.requiredField'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {a: 'test'}, {beforeAction: false}).toEqual
          save: true, goodForAction: false

        expect(result.messages).toEqual []

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {a: 'test'}, {beforeAction: true}).toEqual
          save: true, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', path: 'b', code: 'validate.requiredField'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {a: '', b: null}, {beforeAction: true}).toEqual
          save: true, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', path: 'a', code: 'validate.requiredField'}
            {type: 'error', path: 'b', code: 'validate.requiredField'}
        ]

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {a: 'test', b: 12, d: 121}, {beforeAction: true}).toEqual
          save: false, goodForAction: false

        expect(result.messages).toEqual [
          {type: 'error', path: 'd', code: 'validate.unknownField', value: 121}
        ]

        expect(linkedConfig.docs['doc.Doc1'].fields.$$validate (result = new Result()), {a: 'test', b: 12, d: 121}, {beforeAction: true, strict: false}).toEqual
          save: true, goodForAction: true

        expect(result.messages).toEqual [
        ]


