    {Result, sortedMap, utils: {prettyPrint}} = require '../src'

    flatMap = require '../src/flatMap'

    {compile: compileType} = require '../src/types'

    {compile: compileTags} = require '../src/tags'

    validateBuilder = require '../src/validate'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    compileFields = (result, fields) ->

      map = sortedMap result, fields, index: true

      name = undefined

      result.context ((path) -> (Result.prop name) path), ->

        map.$$list.forEach (field) ->

          name = field.name

          result.isError = false;

          compileType result, field.$$src, field, context: 'field'

          return

      compileTags (result = new Result), map

      map = validateBuilder.addValidate map

      sortedMap.finish result, map

      map # do ->

    describe '041_validate:', ->

На основаннит описания типа, могут быть созданны валидаторы отдельных полей.  Так и валидатор документа.

Простые типы

     typesDesc =

       string: strVal = {right: ['', 'test'], wrong: [undefined, null, 0, 12, true, false, [], {}]}

       text: strVal

       boolean: {right: [true, false], wrong: [undefined, null, 0, 12, '', 'test', [], {}]}

       integer: {right: [0, 1, -10], wrong: [undefined, null, true, false, 12.1, '', 'test', [], {}]},

       double: {right: [0, 1, -10.2], wrong: [undefined, null, true, false, '', 'test', [], {}]},

#       decimal: {right: ['123.456'], wrong: wrongVal = [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

       time: {right: ['12:15'], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

       date: {right: ['2020-11-15'], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

       dateonly: {right: ['2020-11-15T09:15Z'], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},

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

       type.enum = typeTestDesc.enum if typeTestDesc.enum

       if typeTestDesc.fields

         type.fields = typeTestDesc.fields

         compileTags (result = new Result), type.fields

       validate = validateBuilder type

       for value in typeTestDesc.right

         do (typeName, type, validate, value) -> check "#{typeName}: simple types - ok: #{prettyPrint value}", ->

           validate (result = new Result), value, type.fields?.$$tags.all

           expect(result.messages).sameStructure []

       for value in typeTestDesc.wrong

         do (typeName, type, validate, value) ->  check "#{typeName}: simple types - wrong: #{prettyPrint value}", ->

           validate (result = new Result), value, type.fields?.$$tags.all

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

       validate (result = new Result), {f1: 12, f2: 'test'}, fields.$$tags.all

       expect(result.messages).sameStructure []

     check "required: wrong", ->

       validate = validateBuilder

         type: 'structure'

         fields: fields = compileFields (result = new Result),

           f1: type: 'integer', required: true

           f2: type: 'string', length: 20, required: true

           f3: type: 'boolean'

       validate (result = new Result), {f3: false}, fields.$$tags.all

       expect(result.messages).sameStructure [
         {type: 'error', code: 'validate.requiredField', value: 'f1'},
         {type: 'error', code: 'validate.requiredField', value: 'f2'},
       ]

null

     check "null: ok", ->

       validate = validateBuilder

         type: 'structure'

         fields: fields = compileFields (result = new Result),

           f1: type: 'integer', null: true

           f2: type: 'string', length: 20, null: true

           f3: type: 'boolean'

       validate (result = new Result), {f1: null, f2: 'test', f3: false}, fields.$$tags.all

       expect(result.messages).sameStructure []

     check "null: wrong", ->

       validate = validateBuilder

         type: 'structure'

         fields: fields = compileFields (result = new Result),

           f1: type: 'integer', null: true

           f2: type: 'string', length: 20, null: true

           f3: type: 'boolean'

       validate (result = new Result), {f1: null, f2: 'test', f3: null}, fields.$$tags.all

       expect(result.messages).sameStructure [
         {type: 'error', path: 'f3', code: 'validate.invalidValue', value: null}
       ]

string: min, max, regexp, init

     check "string: wrong", ->

       compileFields (result = new Result),
         f1: type: 'string', length: 20, min: 40, init: ''
         ft1: type: 'text', min: 40, max: 30, init: ''

       expect(result.messages).sameStructure [
         {type: 'error', path: 'f1.min', code: 'dsc.tooBig', value: 40}
         {type: 'error', path: 'ft1.max', code: 'dsc.tooSmall', value: 30}
       ]

       compileFields (result = new Result),
         f1a: type: 'string', length: 20, min: 10, init: ''
         ft1a: type: 'text', min: 10, max: 5, init: ''

       expect(result.messages).sameStructure [
         {type: 'error', path: 'f1a.init', code: 'validate.tooShort', value: '', min: 10 }
         {type: 'error', path: 'ft1a.max', code: 'dsc.tooSmall', value: 5}
       ]

       compileFields (result = new Result),
         f1b: type: 'string', length: 20, min: 10, init: ''
         ft1b: type: 'text', min: 10, max: 5, init: ''

       expect(result.messages).sameStructure [
         {type: 'error', path: 'f1b.init', code: 'validate.tooShort', value: '', min: 10 }
         {type: 'error', path: 'ft1b.max', code: 'dsc.tooSmall', value: 5}
       ]

       compileFields (result = new Result),
         f2: type: 'string', length: 20, min: 10, max: 5
         ft2: type: 'text', min: 10, max: 5

       expect(result.messages).sameStructure [
         {type: 'error', path: 'ft2.max', code: 'dsc.tooSmall', value: 5}
       ]

       compileFields (result = new Result),
         f1: type: 'string', length: 20, min: '10', init: ''
         ft1: type: 'text', min: false, max: null, init: ''

       expect(result.messages).sameStructure [
         {type: 'error', path: 'f1.min', code: 'dsc.invalidValue', value: '10'}
         {type: 'error', path: 'ft1.min', code: 'dsc.invalidValue', value: false}
         {type: 'error', path: 'ft1.max', code: 'dsc.invalidValue', value: null }
       ]

int: min, max

double: min, max

decimal: precision, scale, min, max

    # TODO:

RegExp

      check "regexp: right", ->

       fields = compileFields (result = new Result),
         f1: type: 'string', length: 20, regexp: /.*/gi
         ft1: type: 'text', regexp: '/.*/gi'

       expect(fields.f1.regexp instanceof RegExp).toBe true
       expect(fields.ft1.regexp instanceof RegExp).toBe true

enum

structure, subtable

date, time

refers

    # TODO:

Кастомный валидатор

    # TODO:  С проверкой других полей

Валидатор документ

init
