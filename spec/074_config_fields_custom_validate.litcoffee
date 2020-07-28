config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    processCustomValidate = require '../src/validate/processCustomValidate'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '074_config_fields_custom_validate', ->

      beforeEach ->

Билдер валидатора. В него передаются result, field, плюс все параметры единой строкой из func(param1, param2, ...) из аттрибута validate.
this - модель fields. field - описание поля

        @greaterThanNumber = (result, field, params, attrValue) ->

          n = parseFloat params

          if isNaN(n)

            result.error('dsc.invalidArguments', {value: attrValue})

            return

Возвращает валидатор, где fieldsLevel это уровень полей, в котором находится поле.

          (result, value, fieldsLevel) ->

            result.error 'validate.mustBeGraterThen', {value, n} unless value > n

            return

        @fields =

          f1: name: 'f1', type: 'double', validate: 'greaterThanNumber(0)'
          f2: name: 'f2', type: 'double', validate: 'greaterThanNumber(abc)'
          f3: name: 'f3', type: 'double', validate: 'greaterThanNumber'
          f4: name: 'f4', type: 'double', validate: 'wrong(321)'
          f5: name: 'f5', type: 'double', validate: 'wrong'

      check 'processCustomValidate', ->

        customValidate = processCustomValidate (result = new Result), @fields.f1, @fields, {@greaterThanNumber}

        expect(result.messages).toEqual []

        customValidate (result = new Result), 12.2

        expect(result.messages).toEqual []

        customValidate (result = new Result), 0

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.mustBeGraterThen', value: 0, n: 0}
        ]

        customValidate (result = new Result), -1

        expect(result.messages).toEqual [
          {type: 'error', code: 'validate.mustBeGraterThen', value: -1, n: 0}
        ]

      check 'processCustomValidate: wrong', ->

        customValidate = processCustomValidate (result = new Result), @fields.f2, @fields, {@greaterThanNumber}

        expect(result.messages).toEqual [
          {type: 'error', path: 'validate', code: 'dsc.invalidArguments', value: 'greaterThanNumber(abc)'}
        ]

        customValidate = processCustomValidate (result = new Result), @fields.f3, @fields, {@greaterThanNumber}

        expect(result.messages).toEqual [
          {type: 'error', path: 'validate', code: 'dsc.invalidArguments', value: 'greaterThanNumber'}
        ]

        customValidate = processCustomValidate (result = new Result), @fields.f4, @fields, {@greaterThanNumber}

        expect(result.messages).toEqual [
          {type: 'error', path: 'validate', code: 'dsc.unknownValidator', value: 'wrong(321)'}
        ]

        customValidate = processCustomValidate (result = new Result), @fields.f5, @fields, {@greaterThanNumber}

        expect(result.messages).toEqual [
          {type: 'error', path: 'validate', code: 'dsc.unknownValidator', value: 'wrong'}
        ]

      check 'general', ->

        config =

          validators:

            greaterThanNumber: @greaterThanNumber

          docs: Doc1: fields:

            f1: type: 'double', validate: 'greaterThanNumber(0)'

        res = compileConfig (result = new Result), config

        expect(result.messages).toEqual []

        unlinkedConfig = deepClone unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, docs: {}, validators: {@greaterThanNumber}

        linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), {f1: 0}

        expect(result.messages).toEqual [
          {type: 'error', path: 'f1', code: 'validate.mustBeGraterThen', value: 0, n: 0}
          {type: 'error', path: 'id', code: 'validate.requiredField'}
        ]
