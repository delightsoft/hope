    {Result, types: {compile: compileType}, sortedMap, utils: {prettyPrint}} = require '../src'

    validateBuilder = require '../src/validate'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '042_validate:', ->

На основаннит описания типа, могут быть созданны валидаторы отдельных полей.  Так и валидатор документа.

Простые типы

     typesDesc =

       string: strVal = {right: ['', 'test'], wrong: [undefined, null, 0, 12, true, false, [], {}]}

       text: strVal

       boolean: {right: [true, false], wrong: [undefined, null, 0, 12, '', 'test', [], {}]}

       integer: {right: [0, 1, -10], wrong: [undefined, null, true, false, 12.1, '', 'test', [], {}]},

       double: {right: [0, 1, -10.2], wrong: [undefined, null, true, false, '', 'test', [], {}]},

#       decimal: {right: ['123.456'], wrong: wrongVal = [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]},
#
#       time: {right: ['12:15'], wrong: wrongVal},
#
#       date: {right: ['2020-11-15'], wrong: wrongVal},
#
#       dateonly: {right: ['2020-11-15T09:15Z'], wrong: wrongVal},

       enum: {enum: {a: {name: 'a'}, b: {name: 'b'}}, right: ['a', 'b'], wrong: wrongVal = [undefined, null, true, false, 0, 1, -10.2, '', 'test', [], {}]}
#       enum: {enum: {a: {name: 'a'}, b: {name: 'b'}}, right: ['a', 'b'], wrong: wrongVal},

       structure:

         fields: fieldsVal =

           f1: type: 'string', length: 10, validate: validateBuilder type: 'string', length: 10

           f2: type: 'integer', validate: validateBuilder type: 'integer'

           f3: type: 'boolean', validate: validateBuilder type: 'boolean'

         right: [{f1: 'test', f2: '12', f3: false}], wrong: [undefined, null, true, false, 0, 1, -10.2, '', 'test', []]

#       subtable: {right: [[], [fieldsVal], [fieldsVal, fieldsVal, fieldsVal]], wrong: wrongVal}
#
#       refers: {right: ['cY2yZAwgwkanklftLyYzL', '123@doc.Doc1'], wrong: wrongVal}

     for typeName, typeTestDesc of typesDesc

       type = {type: typeName}

       type.enum = typeTestDesc.enum if typeTestDesc.enum

       type.fields = typeTestDesc.fields if typeTestDesc.fields

       validate = validateBuilder type

       for value in typeTestDesc.right

         do (type, validate, value) -> check "#{typeName}: simple types - ok: #{prettyPrint value}", ->

           validate (result = new Result), value

           expect(result).resultContains []

       for value in typeTestDesc.wrong

         do (type, validate, value) ->  check "#{typeName}: simple types - wrong: #{prettyPrint value}", ->

           validate (result = new Result), value

           expect(result).resultContains [
             {type: 'error', code: 'dsc.invalidValue', value}
           ]

required

null

string: length

int: min, max

double: min, max

decimal: precision, scale, min, max

RegExp

enum

structure, subtable

date, time

refers

    # TODO:

Кастомный валидатор

    # TODO:  С проверкой других полей

Валидатор документ
