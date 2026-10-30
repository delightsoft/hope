Document field types
------------------------------

    {Result, types: {compile: compileType}, sortedMap} = require '../src'

    reservedTypes = compileType._reservedTypes

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '040_types:', ->

A field type is defined by several attributes:
- type - system type
- udtype - user-defined type, if there is one
- length - length for strings
- enum - set of values for enum
- fields - set of fields for struct[ure] or subtable
- null - the field may have a null value

Technical trick: To cover individual points of the specification we define our own check method, which can substitute a call
to fit for the test specified in focusOnCheck

These are the possible test values, so that they can be enumerated when checking that the compiler accepts only
a valid type

      testValues = [
        valUndefined = undefined
        valNull = null
        valBool = false
        valNum = 12
        valEmptyArray = []
        valEmptyMap = {}
        valEmptyStr = ''
        valArrayOfDocTypes = ['Doc1', 'Doc2']
          valArrayOfEnumObjects = [{name: 'Field1'}, {name: 'Field2'}, {name: 'Field3'}]
        valArrayOfFieldsDesc = [{name: 'field1', type: 'string', length: 10}, {name: 'field2', type: 'int'}, {name: 'field3', type: 'bool'}]
        valStr = 'str'
      ]

A list of field-description properties to enumerate, each with an example of an allowed type value

      propDescs = [
        {name: 'length', correctVal: valNum}
        {name: 'enum', correctVal: valArrayOfEnumObjects, skipVal: [valStr, valEmptyArray, valEmptyMap, valArrayOfFieldsDesc, valArrayOfDocTypes], required: true}

        {name: 'precision', correctVal: valNum, required: true}

scale is not a standalone property, it goes in pair with precision

        {name: 'scale', correctVal: valNum, optional: true, required: false}
        {name: 'fields', correctVal: valArrayOfFieldsDesc, skipVal: [valStr, valEmptyArray, valEmptyMap, valArrayOfDocTypes, valArrayOfEnumObjects], required: true}
        {name: 'null', correctVal: valBool, required: false}

        {name: 'refers', correctVal: valStr, required: true, skipVal: [valEmptyArray, valEmptyStr, valArrayOfDocTypes]}
      ]

This is the list of types built into DSCommon.  The attributes indicate which additional properties need (or may) be
specified for the given type.  They also say whether the type has a short name.
* short - short name
* notNull - for this type you cannot specify null: true
* autotypeBy - if the attribute named by the value is present in the field description and no type property is specified,
then type is set automatically
* length - length for the string type
* precision - length for the decimal type
* scale - number of digits after the decimal point for the decimal type.  An optional property
* enum - list of values for the enum type
* fields - list of fields for the structure and subtable types

      builtInTypes = [

        {name: 'string', short: 'str', length: true, null: true}
        {name: 'text', null: true}
        {name: 'boolean', short: 'bool', null: true}

        {name: 'integer', short: 'int', null: true}

At this stage there will be no support for long, since there is a question of how to use long in JavaScript.  long is not
part of JavaScript-number - as it is a double

        # {name: 'long', null: true}

And there will be no support for float - until it becomes clear why it is needed

        # {name: 'float', null: true}

        {name: 'double', null: true}

We will also hold off on decimal for now

        # {name: 'decimal', precision: true, scale: true, null: true}

        {name: 'time', null: true}
        {name: 'date', null: true}
        {name: 'timestamp', null: true}
#        {name: 'datetime', null: true}
        {name: 'now'}

        {name: 'json', null: true}
        {name: 'blob', null: true}
        {name: 'uuid', null: true}
        {name: 'enum', autotypeBy: 'enum', enum: true, null: true}

        {name: 'structure', autotypeBy: 'fields', short: 'struct', fields: true}
        {name: 'subtable', fields: true}

        {name: 'refers', short: 'ref', autotypeBy: 'refers', refers: true, null: true}
      ]

First we check that if the field description does not contain type, there will be an error

      check "type is missing", ->

        compileType (result = new Result), {}, {}

        expect(result).resultContains [
          {type: 'error', code: 'dsc.missingProp', value: 'type'}
        ]

      check "type has invalid chars in it's name", ->

        compileType (result = new Result), {type: '[WrongType]'}, {}

        expect(result).resultContains [
          {type: 'error', code: 'dsc.invalidTypeValue', value: '[WrongType]'}
        ]

We build the list of tests for each type, adding separate tests for short type names

      tests = []

      for type in builtInTypes

For short type names, we keep the full type name, so that we know what to expect from compileType

        type.fullname = type.name

        tests.push {name: type.name, type: type}

        if type.hasOwnProperty 'short'

          tests.push {name: type.short, type: type}

We create tests for the types and their abbreviated spellings

      for test in tests

Next, depending on which properties the given type may have, we check the variants of handling these properties

Required props
------------------------------

We check that the properties required for the type are present

        for prop in propDescs when prop.required && test.type[prop.name]

          do (test, prop) -> check "#{test.name}: required prop '#{prop.name}' missing", ->

            propDesc = {type: test.type.name}

            compileType (result = new Result), propDesc, {}

            expect(result).resultContains [
              {type: 'error', code: 'dsc.missingProp', value : prop.name}
            ]

Right value
------------------------------

We check that if the ds-type property is given a value of the wrong type, an error is returned

        for prop in propDescs when test.type[prop.name]

          for value in testValues when prop.correctVal != value && not (prop.skipVal && value in prop.skipVal)

            do (test, prop, value) -> check "#{test.name}: invalid prop '#{prop.name}' value: #{jasmine.pp value}", ->

              propDesc = {type: test.type.name}

              propDesc[prop.name] =

                if propDesc.fields

                  sortedMap (result = new Result), value

                else value

              compileType (result = new Result), propDesc, {}

              expect(result).resultContains (

For the remaining cases, the only correct value is the one specified in prop.correctVal

                [{type: 'error', path: prop.name, code: 'dsc.invalidValue', value: value}])

The scale property can go in pair with precision - we check how they work together

            if prop.name == 'precision'

              do (test, prop, value) -> check "#{test.name}: invalid prop 'scale' value: #{jasmine.pp value}", ->

                propDesc = {type: test.type.name, precision: prop.correctVal}

                propDesc.scale = value

                compileType (result = new Result), propDesc, {}

                expect(result).resultContains [
                  {type: 'error', path: 'scale', code: 'dsc.invalidValue', value: value}
                ]

string
--------------------

      for lengthValue in [10, 256, 2123]

        do (lengthValue) -> check "string: parse length from type: #{lengthValue}", ->

The length may be specified in the type string, in parentheses

          typeDesc = {type: "string(#{lengthValue})"}

          expect(compileType (result = new Result), typeDesc, {}).sameStructure

            type: 'string'

            length: lengthValue

If the length is specified in parentheses in the type, there must be no length property

          typeDesc = {type: "string(#{lengthValue})", length: 10}

          compileType (result = new Result), typeDesc, {}

          expect(result).resultContains [
            {type: 'error', path: "(#{lengthValue})", code: 'dsc.ambiguousProp', name: 'length', value1: lengthValue, value2: 10}
          ]

A negative length is incorrect

      for lengthValue in [-1000, -1, 0]

        do (lengthValue) -> check "string: invalid length: #{lengthValue}", ->

Both in parentheses

          typeDesc = {type: "string(#{lengthValue})"}

          compileType (result = new Result), typeDesc, {}

          expect(result).resultContains [
            {type: 'error', path: "(#{lengthValue})", code: 'dsc.invalidValue', value: lengthValue}
          ]

And in the length property

          typeDesc = {type: "string", length: lengthValue}

          compileType (result = new Result), typeDesc, {}

          expect(result).resultContains [
            {type: 'error', path: 'length', code: 'dsc.invalidValue', value: lengthValue}
          ]

If the length in the type name is written incorrectly, an error is returned

      check 'string: invalid parenthesis', ->

        compileType (result = new Result), {type: invalidType = 'string (20'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.invalidTypeValue', value: invalidType}]

        compileType (result = new Result), {type: invalidType = 'string (20) extra'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.invalidTypeValue', value: invalidType}]

        compileType (result = new Result), {type: invalidType = 'string ()'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.invalidTypeValue', value: invalidType}]

enum
--------------------

enum can be specified in several ways:
* an array of strings
* a string, where the values are separated by commas
* as an array of objects, where the names of the elements are given in the name property
* as a map, in which the keys are the names of the elements.  In this case the value can be either an object or true

      check 'enum: as array of strings', ->

        res = compileType (result = new Result), {type: 'enum', enum: ['v1', 'v2', 'v3']}, {}

        expect(result.messages).toEqual []

        expect(res).sameStructure
          type: 'enum'
          enum:
            v1: v1 = {name: 'v1'}
            v2: v2 = {name: 'v2'}
            v3: v3 = {name: 'v3'}
            $$list: [v1, v2, v3]

      check 'enum: comma delimited string', ->

        res = compileType (result = new Result), {type: 'enum', enum: 'v1, v2, v3'}, {}

        expect(result.messages).sameStructure []

        expect(res).sameStructure
          type: 'enum'
          enum:
            v1: v1 = {name: 'v1'}
            v2: v2 = {name: 'v2'}
            v3: v3 = {name: 'v3'}
            $$list: [v1, v2, v3]

      check 'enum: list of objects', ->

        res = compileType (result = new Result), {
          type: 'enum'
          enum: [
            {name: 'v1'}
            {name: 'v2'}
            {name: 'v3'}
          ]}, {}

        expect(result.messages).sameStructure []

        expect(res).sameStructure
          type: 'enum'
          enum:
            v1: v1 = {name: 'v1'}
            v2: v2 = {name: 'v2'}
            v3: v3 = {name: 'v3'}
            $$list: [v1, v2, v3]

      check 'enum: map of objects or true-values', ->

        res = compileType (result = new Result), {
          type: 'enum'
          enum:
            v1: true
            v2: true
            v3: {},
        }, {}

        expect(result.messages).sameStructure []

        expect(res).sameStructure
          type: 'enum'
          enum:
            v1: v1 = {name: 'v1'}
            v2: v2 = {name: 'v2'}
            v3: v3 = {name: 'v3'}
            $$list: [v1, v2, v3]

fields
--------------------

fields can be specified in several ways:
* as an array of objects, where the field name is given in the name property and the elements contain the field properties
* as a map, in which the keys are the field names, and the elements contain the field properties

      check 'fields: list of objects', ->

        res = compileType (result = new Result), {
          type: 'structure'
          fields: fields = [
            {name: 'v1', type: 'string', length: 20}
            {name: 'v2', type: 'integer'}
            {name: 'v3', type: 'uuid'}
          ]}, {fields: sortedMap result, fields}

        expect(result.messages).sameStructure []

        expect(res).sameStructure
          type: 'structure'
          fields:
            v1: v1 = {name: 'v1', $$src: {name: 'v1', type: 'string', length: 20}}
            v2: v2 = {name: 'v2', $$src: {name: 'v2', type: 'integer'}}
            v3: v3 = {name: 'v3', $$src: {name: 'v3', type: 'uuid'}}
            $$list: [v1, v2, v3]

      check 'fields: map of objects', ->

        res = compileType (result = new Result), {
          type: 'structure'
          fields: fields =
            v1: {type: 'string', length: 20}
            v2: {name: 'v2', type: 'integer'}
            v3: {type: 'uuid'}
        }, {fields: sortedMap result, fields}

        expect(result.messages).sameStructure []

        expect(res).sameStructure
          type: 'structure'
          fields:
            v1: v1 = {name: 'v1', $$src: {type: 'string', length: 20}}
            v2: v2 = {name: 'v2', $$src: {name: 'v2', type: 'integer'}}
            v3: v3 = {name: 'v3', $$src: {type: 'uuid'}}
            $$list: [v1, v2, v3]

refers
--------------------

A reference to a document is specified:
* either through the refers property
* or in parentheses in the type property

      check 'refers: type string options',  ->

        expect(compileType (result = new Result), type: 'refers (Doc)', {}).sameStructure
          type: 'refers'
          refers: 'Doc'

        expect(result.messages).sameStructure []

if refers is specified as the #any tag - then it can accept documents of any type

      check 'refers: type string options',  ->

        expect(compileType (result = new Result), type: 'refers (#any)', {}).sameStructure
          type: 'refers'
          refers: '#any'

        expect(result.messages).sameStructure []

        expect(compileType (result = new Result), refers: '#any', {}).sameStructure
          type: 'refers'
          refers: '#any'
        expect(result.messages).sameStructure []

if refers is given as a list of document types - as an array or as a delimiter-separated string

      check 'refers: type string options',  ->

        expect(compileType (result = new Result), type: 'refers (Doc1, Doc2)', {}).sameStructure
          type: 'refers'
          refers: 'Doc1, Doc2'
        expect(result.messages).sameStructure []

        expect(compileType (result = new Result), refers: 'Doc1, Doc2', {}).sameStructure
          type: 'refers'
          refers: 'Doc1, Doc2'
        expect(result.messages).sameStructure []

        expect(compileType (result = new Result), refers: ['Doc1', 'Doc2'], {}).sameStructure
          type: 'refers'
          refers: ['Doc1', 'Doc2']
        expect(result.messages).sameStructure []

a document can be specified both by the name of the document type and by a tag

      # TODO: Implement in other spec

implicit types
--------------------

If type is not specified, but there are other properties from which the type can be determined, then the type property does not have to be specified.

Properties from which the type can be determined:
- enum -> the enum type
- fields -> the structure type
- refers -> the refers type

      check 'enum: implicit type by property', ->

        res = compileType (result = new Result), {enum: 'a, b, c'}, {}

        expect(result.messages).sameStructure []

        expect(res).sameStructure
          type: 'enum'
          enum:
            a: a = {name: 'a'}
            b: b = {name: 'b'}
            c: c = {name: 'c'}
            $$list: [a, b, c]

      check 'fields: implicit type by property', ->

        expect(compileType (result = new Result), {fields: fields = [{name: 'fld1', type: 'integer'}, {name: 'fld2', type: 'text'}]}, {fields: sortedMap result, fields}).sameStructure
          type: 'structure'
          fields:
            fld1: fld1 = {name: 'fld1', $$src: {name: 'fld1', type: 'integer'}}
            fld2: fld2 = {name: 'fld2', $$src: {name: 'fld2', type: 'text'}}
            $$list: [fld1, fld2]

      check 'refers: implicit type by property', ->

        expect(compileType (result = new Result), {refers: '#all'}, {}).sameStructure
          type: 'refers'
          refers: '#all'

reserved types
--------------------

      for type in reservedTypes

        do (type) -> check "reserved type: '#{type}'", ->

          res = compileType (result = new Result), {type: type}, {}

          expect(result.messages).sameStructure [{type: 'error', code: 'dsc.reservedType', value: type}]

udtype
--------------------

udtypes (named types) are specified in config.udtypes

We consider all types that are neither built-in nor reserved to be an udType

      check "unknown type, expect to be an udType", ->

        res = compileType (result = new Result), {type: 'wrongType'}, {}

        expect(res).toEqual udType: 'wrongType'

The udType property is not set directly.  The name is taken from the config.udtypes key

      check "error: attr udType is not expected", ->

        res = compileType (result = new Result), {type: 'int', udType: 'intBasedType'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.reservedAttr', value: 'udType'}]

      check "error: attr 'null' is not allowed in udt", ->

        res = compileType (result = new Result), {type: 'int', null: true}, {}, context: 'udtype'

        expect(result.messages).sameStructure [{type: 'error', path: 'null', code: 'dsc.notApplicableInUdtype'}]

Further processing for the presence of udt is a separate step in the ...config_udtypes specification
