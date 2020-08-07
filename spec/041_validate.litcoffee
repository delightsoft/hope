    {Result, sortedMap, utils: {prettyPrint}, tags: {compile: compileTags}, config: {link, unlink}} = require '../src'

    flatMap = require '../src/flatMap'

    {compile: compileType} = require '../src/types'

    {compile: compileTags} = require '../src/tags'

    validateBuilder = require '../src/validate'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    compileFields = (result, fields) ->

      map = flatMap result, fields, 'fields', index: true, mask: true

      name = undefined

      result.context ((path) -> (Result.prop name) path), ->

        map.$$list.forEach (field) ->

          name = field.name

          compileType result, field.$$src, field, context: 'field'

          return

      compileTags result, map

      map = validateBuilder.addValidate map

      compileTags result, map

      sortedMap.finish result, map

      doc = name: 'doc.Doc1', fields: map, actions: {$$list: [], $$tags: {all: '...'}}, states: {$$list: []}

      res = unlink docs: {'doc.Doc1': doc, $$list: [doc]}, api: {$$list: []}

      res = link res

      res.docs['doc.Doc1'].fields # (result, fields) ->

    describe '041_validate:', ->

На основаннит описания типа, могут быть созданны валидаторы отдельных полей.  Так и валидатор документа.

Простые типы

      typesDesc =

         string: strVal = {length: 20, right: ['', 'test'], wrong: [undefined, null, 0, 12, true, false, [], {}]}

         text: strVal

         boolean: {right: [true, false], wrong: [undefined, null, 0, 12, '', 'test', [], {}]}

         integer: {right: [0, 1, -10], wrong: [undefined, null, true, false, 12.1, '', 'test', [], {}]},

         double: {right: [0, 1, -10.2], wrong: [undefined, null, true, false, '', 'test', [], {}]},

  #       decimal: {right: ['123.456'], wrong: wrongVal = [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

         time: {right: ['12:15'], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

         date: {right: ['2020-11-15'], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

         timestamp: {right: ['2020-11-15T09:15Z'], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

         enum: {enum: {a: {name: 'a'}, b: {name: 'b'}}, right: ['a', 'b'], wrong: wrongVal = [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]}

         structure:

           fields: compileFields (result = new Result),

             f1: type: 'string', length: 10

             f2: type: 'integer'

             f3: type: 'boolean'

           right: [fieldsVal = {f1: 'test', f2: 12, f3: false}]

           wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', []]

         subtable:

           fields: compileFields (result = new Result),

             f1: type: 'string', length: 10

             f2: type: 'integer'

             f3: type: 'boolean'

           right: [[], [fieldsVal], [fieldsVal, fieldsVal, fieldsVal]]

           wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', {}]

  #       refers: {right: ['cY2yZAwgwkanklftLyYzL', '123@doc.Doc1'], wrong: wrongVal}

      for typeName, typeTestDesc of typesDesc

        type = {type: typeName}

        type.length = typeTestDesc.length if typeTestDesc.length

        type.enum = typeTestDesc.enum if typeTestDesc.enum

        if typeTestDesc.fields

          type.fields = typeTestDesc.fields

          compileTags (result = new Result), type.fields

        validate = validateBuilder type

        for value in typeTestDesc.right

          do (typeName, type, validate, value) -> check "#{typeName}: simple types - ok: #{prettyPrint value}", ->

            validate (result = new Result), value, undefined, type.fields?.$$tags.all

            expect(result.messages).sameStructure []

        for value in typeTestDesc.wrong

          do (typeName, type, validate, value) ->  check "#{typeName}: simple types - wrong: #{prettyPrint value}", ->

            validate (result = new Result), value, undefined, type.fields?.$$tags.all

            expect(result.messages).sameStructure [
              {type: 'error', code: 'validate.invalidValue', value}
            ]

      check "required: ok", ->

        validate = validateBuilder

          type: 'structure'

          fields: fields = compileFields (result = new Result),

            f1: type: 'integer', required: true, validate: validateBuilder type: 'integer'

            f2: type: 'string', length: 20, required: true, validate: validateBuilder type: 'string', length: 20

            f3: type: 'boolean', validate: validateBuilder type: 'boolean'

        validate (result = new Result), {f1: 12, f2: 'test'}, undefined, fields.$$tags.all

        expect(result.messages).sameStructure []

      check "required: wrong", ->

        validate = validateBuilder

          type: 'structure'

          fields: fields = compileFields (result = new Result),

            f1: type: 'integer', required: true

            f2: type: 'string', length: 20, required: true

            f3: type: 'boolean'

        validate (result = new Result), {f3: false}, undefined, fields.$$tags.all

        expect(result.messages).sameStructure [
          {type: 'error', code: 'validate.requiredField', path: 'f1'},
          {type: 'error', code: 'validate.requiredField', path: 'f2'},
        ]

null

      check "null: ok", ->

        validate = validateBuilder

          type: 'structure'

          fields: fields = compileFields (result = new Result),

            f1: type: 'integer', null: true

            f2: type: 'string', length: 20, null: true

            f3: type: 'boolean'

        validate (result = new Result), {f1: null, f2: 'test', f3: false}, undefined, fields.$$tags.all

        expect(result.messages).sameStructure []

      check "null: wrong", ->

        validate = validateBuilder

          type: 'structure'

          fields: fields = compileFields (result = new Result),

            f1: type: 'integer', null: true

            f2: type: 'string', length: 20, null: true

            f3: type: 'boolean'

        validate (result = new Result), {f1: null, f2: 'test', f3: null}, undefined, fields.$$tags.all

        expect(result.messages).sameStructure [
          {type: 'error', path: 'f3', code: 'validate.invalidValue', value: null}
        ]

string: min, regexp, init

      check "string", ->

        compileFields (result = new Result),
          string1: type: 'string(10)', min: 5, init: '12'
          string2: type: 'string(10)', min: 5, init: '123456'
          string3: type: 'string(10)', min: 5, init: '123456789012'

        expect(result.messages).sameStructure [
          {type: 'error', path: 'string1.init', code: 'validate.tooShort', value: '12', min: 5}
          {type: 'error', path: 'string3.init', code: 'validate.tooLong', value: '123456789012', max: 10}
        ]

        compileFields (result = new Result), # unexpected тестируем отдельно.  при наличии других ошибок эта ошибка не возвращается
          string4: type: 'string(10)', min: 5, max: 20

        expect(result.messages).sameStructure [
          {type: 'error', path: 'string4', code: 'dsc.unexpectedProp', value: 'max'}
        ]

        compileFields (result = new Result),
          string5: type: 'string(10)', regexp: /\d{2,5}/i, init: '1'
          string6: type: 'string(10)', regexp: '/\\d{2,5}/i', init: '123'
          string7: type: 'string(10)', regexp: /\d{2,5}/i, init: '123456'

        expect(result.messages).sameStructure [
          {type: 'error', path: 'string5.init', code: 'validate.invalidValue', value: '1', regexp: '/\\d{2,5}/i'}
        ]

        compileFields (result = new Result),
          string10: type: 'string(10)', init: null
          string11: type: 'string(10)', init: 123
          string12: type: 'string(10)', init: true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'string10.init', code: 'validate.invalidValue', value: null}
          {type: 'error', path: 'string11.init', code: 'validate.invalidValue', value: 123}
          {type: 'error', path: 'string12.init', code: 'validate.invalidValue', value: true}
        ]

        compileFields (result = new Result),
          string20: type: 'string(10)', min: 20

        expect(result.messages).sameStructure [
          {type: 'error', path: 'string20.min', code: 'dsc.tooBig', value: 20}
        ]

text: min, max, regexp, init

      check "text", ->

        compileFields (result = new Result),
          text1: type: 'text', min: 5, init: '12'
          text2: type: 'text', min: 5, init: '123456'
          text3: type: 'text', min: 5, max: 10, init: '123456789012'

        expect(result.messages).sameStructure [
          {type: 'error', path: 'text1.init', code: 'validate.tooShort', value: '12', min: 5}
          {type: 'error', path: 'text3.init', code: 'validate.tooLong', value: '123456789012', max: 10}
        ]

        compileFields (result = new Result),
          text5: type: 'text', regexp: /\d{2,5}/i, init: '1'
          text6: type: 'text', regexp: /\d{2,5}/i, init: '123'
          text7: type: 'text', regexp: /\d{2,5}/i, init: '123456'

        expect(result.messages).sameStructure [
          {type: 'error', path: 'text5.init', code: 'validate.invalidValue', value: '1', regexp: '/\\d{2,5}/i'}
        ]

        compileFields (result = new Result),
          text10: type: 'text', init: null
          text11: type: 'text', init: 123
          text12: type: 'text', init: true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'text10.init', code: 'validate.invalidValue', value: null}
          {type: 'error', path: 'text11.init', code: 'validate.invalidValue', value: 123}
          {type: 'error', path: 'text12.init', code: 'validate.invalidValue', value: true}
        ]

        compileFields (result = new Result),
          text20: type: 'text', min: 20, max: 10

        expect(result.messages).sameStructure [
          {type: 'error', path: 'text20.max', code: 'dsc.tooSmall', value: 10}
        ]

int: min, max

      check "int", ->

        compileFields (result = new Result),
          int1: type: 'int', min: 10, max: 20, init: 5
          int2: type: 'int', min: 10, max: 20, init: 15
          int3: type: 'int', min: 10, max: 20, init: 25

        expect(result.messages).sameStructure [
          {type: 'error', path: 'int1.init', code: 'validate.tooSmall', value: 5, min: 10}
          {type: 'error', path: 'int3.init', code: 'validate.tooBig', value: 25, max: 20 }
        ]

double: min, max

      check "double", ->

        compileFields (result = new Result),
          double1: type: 'double', min: 10.0, max: 20.2, init: 5.12
          double2: type: 'double', min: 10.0, max: 20.2, init: 15.12
          double3: type: 'double', min: 10.0, max: 20.2, init: 25.12

        expect(result.messages).sameStructure [
          {type: 'error', path: 'double1.init', code: 'validate.tooSmall', value: 5.12, min: 10}
          {type: 'error', path: 'double3.init', code: 'validate.tooBig', value: 25.12, max: 20.2 }
        ]

decimal: precision, scale, min, max

    # TODO:

boolean: init

      check "boolean", ->

        compileFields (result = new Result),
          boolean1: type: 'boolean', init: true
          boolean2: type: 'boolean', min: 10, max: 20

        expect(result.messages).sameStructure [
          {type: 'error', path: 'boolean2', code: 'dsc.unexpectedProp', value: 'min'}
          {type: 'error', path: 'boolean2', code: 'dsc.unexpectedProp', value: 'max'}
        ]

        compileFields (result = new Result),
          boolean10: type: 'boolean', init: 123.45
          boolean11: type: 'boolean', init: 'wrong'
          boolean12: type: 'boolean', init: {}

        expect(result.messages).sameStructure [
          {type: 'error', path: 'boolean10.init', code: 'validate.invalidValue', value: 123.45}
          {type: 'error', path: 'boolean11.init', code: 'validate.invalidValue', value: 'wrong'}
          {type: 'error', path: 'boolean12.init', code: 'validate.invalidValue', value: {}}
        ]

enum: init

      check "enum", ->

        compileFields (result = new Result),
          enum1: enum: 'a,b,c', init: 'a'
          enum2: enum: 'a,b,c', init: 'wrong'
          enum3: enum: 'a,b,c', init: 12
          enum4: enum: 'a,b,c', init: false

        expect(result.messages).sameStructure [
          {type: 'error', path: 'enum2.init', code: 'validate.invalidValue', value: 'wrong'}
          {type: 'error', path: 'enum3.init', code: 'validate.invalidValue', value: 12}
          {type: 'error', path: 'enum4.init', code: 'validate.invalidValue', value: false}
        ]

structure, subtable: not init

      check "structure", ->

        compileFields (result = new Result),
          structure1: fields: {f1: {type: 'string(20)'}, f2: {type: 'string(20)'}}, init: 'wrong'
          structure2: fields: {f1: {type: 'string(20)'}, f2: {type: 'string(20)'}}, init: 123
          structure3: fields: {f1: {type: 'string(20)'}, f2: {type: 'string(20)'}}, init: true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'structure1', code: 'dsc.unexpectedProp', value: 'init'}
          {type: 'error', path: 'structure2', code: 'dsc.unexpectedProp', value: 'init'}
          {type: 'error', path: 'structure3', code: 'dsc.unexpectedProp', value: 'init'}
        ]

date, time, timestamp

      check "date", ->

        compileFields (result = new Result),
          date1: type: 'date', init: '2020-07-23'
          date2: type: 'date', init: 123
          date3: type: 'date', init: 'wrong'
          date4: type: 'date', init: false
          date5: type: 'date', init: null

        expect(result.messages).sameStructure [
          {type: 'error', path: 'date2.init', code: 'validate.invalidValue', value: 123}
          {type: 'error', path: 'date3.init', code: 'validate.invalidValue', value: 'wrong'}
          {type: 'error', path: 'date4.init', code: 'validate.invalidValue', value: false}
          {type: 'error', path: 'date5.init', code: 'validate.invalidValue', value: null}
        ]

      check "time", ->

        compileFields (result = new Result),
          time1: type: 'time', init: '10:12'
          time2: type: 'time', init: 123
          time3: type: 'time', init: 'wrong'
          time4: type: 'time', init: false
          time5: type: 'time', init: null

        expect(result.messages).sameStructure [
          {type: 'error', path: 'time2.init', code: 'validate.invalidValue', value: 123}
          {type: 'error', path: 'time3.init', code: 'validate.invalidValue', value: 'wrong'}
          {type: 'error', path: 'time4.init', code: 'validate.invalidValue', value: false}
          {type: 'error', path: 'time5.init', code: 'validate.invalidValue', value: null}
        ]

      check "timestamp", ->

        compileFields (result = new Result),
          timestamp1: type: 'timestamp', init: '2020-07-23 10:12'
          timestamp2: type: 'timestamp', init: 123
          timestamp3: type: 'timestamp', init: 'wrong'
          timestamp4: type: 'timestamp', init: false
          timestamp5: type: 'timestamp', init: null
          timestamp6: type: 'timestamp', null: true, init: null

        expect(result.messages).sameStructure [
          {type: 'error', path: 'timestamp2.init', code: 'validate.invalidValue', value: 123}
          {type: 'error', path: 'timestamp3.init', code: 'validate.invalidValue', value: 'wrong'}
          {type: 'error', path: 'timestamp4.init', code: 'validate.invalidValue', value: false}
          {type: 'error', path: 'timestamp5.init', code: 'validate.invalidValue', value: null}
        ]

refers

    # TODO:

Кастомный валидатор

    # TODO: С проверкой других полей

Валидатор документ

init
