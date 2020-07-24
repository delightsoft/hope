Типы полей документов
------------------------------

    {Result, types: {compile: compileType}, sortedMap} = require '../src'

    reservedTypes = compileType._reservedTypes

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '040_types:', ->

Тип поля задается несколькими аттрибутами:
- type - системный тип
- udtype - пользовательский тип (user defined), если есть
- length - длина для строк
- enum - набор значений для enum
- fields - набор полей для struct[ure] или subtable
- null - поле может иметь значение null

Тех. прием: Для отработки отдельных пунктов спецификации делаем свой метод check, который может подставлять вызов
fit, для задачи указанной в focusOnCheck

Это возможные тестовые значения, чтобы можно было их перебирать при проверке, что комплиятор пропускает только
допустимый тип

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

Список свойст описания полей, для перебора, с указанием примера допустимого типа

      propDescs = [
        {name: 'length', correctVal: valNum}
        {name: 'enum', correctVal: valArrayOfEnumObjects, skipVal: [valStr, valEmptyArray, valEmptyMap, valArrayOfFieldsDesc, valArrayOfDocTypes], required: true}

        {name: 'precision', correctVal: valNum, required: true}

scale это не самостоятельное свойство, оно идет в паре с precision

        {name: 'scale', correctVal: valNum, optional: true, required: false}
        {name: 'fields', correctVal: valArrayOfFieldsDesc, skipVal: [valStr, valEmptyArray, valEmptyMap, valArrayOfDocTypes, valArrayOfEnumObjects], required: true}
        {name: 'null', correctVal: valBool, required: false}

        {name: 'refers', correctVal: valStr, required: true, skipVal: [valEmptyArray, valEmptyStr, valArrayOfDocTypes]}
      ]

Это список встроенных в DSCommon типов.  Атрибуты говорят какие дополнительные поля нужно (можно) указывать для
данного типа.  А так же есть у ли у типа короткое название.
* short - короткое название
* notNull - для данного типа нельзя указать null: true
* autotypeBy - если указанный в значении атрибут присутствует в описании поля и при этом не указано свойство type,
то type проставляется автоматически
* length - длина для типа string
* precision - длина для типа decimal
* scale - количество знаков после запятой для типа decimal.  Не обязательное свойство
* enum - список значения для типа enum
* fields - список полей для типов structure и subtable

      builtInTypes = [

        {name: 'string', short: 'str', length: true, null: true}
        {name: 'text', null: true}
        {name: 'boolean', short: 'bool', null: true}

        {name: 'integer', short: 'int', null: true}

На этом этапе поддержки long не будет. так как есть вопрос, как исползоваться long в JavaScript.  long не входит
в JavaScript-number - так как это double

        # {name: 'long', null: true}

И не будет поддержки float - пока не станет понятно зачем на это

        # {name: 'float', null: true}

        {name: 'double', null: true}

C decimal тоже пока повременим

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

        #{name: 'dsvalue', short: 'value', null: true}
      ]

Для начала проверяем, что если описание поля, не содержит type, то будет ошибка

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

Формируем список тестов для каждого типа, добавляя отдельные тесты для коротких имен типов

      tests = []

      for type in builtInTypes

Для коротких имен типов, сохраняем полное имя типа, чтоб знать что ожидать в результате compileType

        type.fullname = type.name

        tests.push {name: type.name, type: type}

        if type.hasOwnProperty 'short'

          tests.push {name: type.short, type: type}

Создаем тесты для типов и их сокращенных написаний

      for test in tests

Далее, в зависимости от того, какие свойства могут быть у данного типа проверяем варианты обработки этих свойств

Required props
------------------------------

Проверяем, что свойства обязательные для типа присутствуют

        for prop in propDescs when prop.required && test.type[prop.name]

          do (test, prop) -> check "#{test.name}: required prop '#{prop.name}' missing", ->

            propDesc = {type: test.type.name}

            compileType (result = new Result), propDesc, {}

            expect(result).resultContains [
              {type: 'error', code: 'dsc.missingProp', value : prop.name}
            ]

Right value
------------------------------

Проверяем, что если в свойстве ds-типа, указано не верный тип значения, то возвращается ошибка

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

Для остальных случаев, правильное значение только то, которая указано в prop.correctVal

                [{type: 'error', path: prop.name, code: 'dsc.invalidValue', value: value}])

К свойство precision, в паре может идти свойство scale - проверяем как они работают в паре

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

Длина может быть указана в строки типа, в скобках

          typeDesc = {type: "string(#{lengthValue})"}

          expect(compileType (result = new Result), typeDesc, {}).sameStructure

            type: 'string'

            length: lengthValue

Если длина указана в скобках в типе, то не должно быть свойства length

          typeDesc = {type: "string(#{lengthValue})", length: 10}

          compileType (result = new Result), typeDesc, {}

          expect(result).resultContains [
            {type: 'error', path: "(#{lengthValue})", code: 'dsc.ambiguousProp', name: 'length', value1: lengthValue, value2: 10}
          ]

Отрицательная длина - это не правильно

      for lengthValue in [-1000, -1, 0]

        do (lengthValue) -> check "string: invalid length: #{lengthValue}", ->

Как в скобках

          typeDesc = {type: "string(#{lengthValue})"}

          compileType (result = new Result), typeDesc, {}

          expect(result).resultContains [
            {type: 'error', path: "(#{lengthValue})", code: 'dsc.invalidValue', value: lengthValue}
          ]

Так и в свойстве length

          typeDesc = {type: "string", length: lengthValue}

          compileType (result = new Result), typeDesc, {}

          expect(result).resultContains [
            {type: 'error', path: 'length', code: 'dsc.invalidValue', value: lengthValue}
          ]

Если длина в имени типа написана не верно, то возвращается ошибка

      check 'string: invalid parenthesis', ->

        compileType (result = new Result), {type: invalidType = 'string (20'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.invalidTypeValue', value: invalidType}]

        compileType (result = new Result), {type: invalidType = 'string (20) extra'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.invalidTypeValue', value: invalidType}]

        compileType (result = new Result), {type: invalidType = 'string ()'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.invalidTypeValue', value: invalidType}]

enum
--------------------

enum может быть задан несколькими способами:
* массив строк
* строка, с где значения разделены запятыми
* как массив объектов, где имя элементов задано в свойтсве name
* как map, в котором ключи - названия элементов.  при этом значение может быть как объект, так и true

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

fields может быть задан несколькими способами:
* как массив объектов, где имя поля задано в свойтсве name и элементы содержат свойства полей
* как map, в котором ключи - названия полей, и элементы содержат свойства полей

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

ссылка на документ задается:
* или через свойство refers
* или в скобках в свойстве type

      check 'refers: type string options',  ->

        expect(compileType (result = new Result), type: 'refers (Doc)', {}).sameStructure
          type: 'refers'
          refers: 'Doc'

        expect(result.messages).sameStructure []

если refers задан как тег #any - тогда он может принимать документы любого типа

      check 'refers: type string options',  ->

        expect(compileType (result = new Result), type: 'refers (#any)', {}).sameStructure
          type: 'refers'
          refers: '#any'

        expect(result.messages).sameStructure []

        expect(compileType (result = new Result), refers: '#any', {}).sameStructure
          type: 'refers'
          refers: '#any'
        expect(result.messages).sameStructure []

есди refers задан, списком типов документов - в виде массива или как строка с разделителем

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

документ может быть задан, как названием типа документа, так и тегом

      # TODO: Implement in other spec

implicit types
--------------------

Если не указан type, но есть другие свойства, из которых можно опеределить тип, то свойство type указывать не обязательно.

Свойства по которым можно определить тип:
- enum -> тип enum
- fields -> тип structure
- refers -> тип refers

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

udtypes (именованные типы) задаются в config.udtypes

Cчитаем все типы, которые не являются встроенными и зарезервированными, что это udType

      check "unknown type, expect to be an udType", ->

        res = compileType (result = new Result), {type: 'wrongType'}, {}

        expect(res).toEqual udType: 'wrongType'

Свойство udType не задается на прямую.  Это имя берется из ключа config.udtypes

      check "error: attr udType is not expected", ->

        res = compileType (result = new Result), {type: 'int', udType: 'intBasedType'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.reservedAttr', value: 'udType'}]

      check "error: type 'dsvalue' is not allowed in a field def", ->

        res = compileType (result = new Result), {type: 'dsvalue'}, {}

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.notAllowedInFieldDef', value: 'dsvalue'}]

        res = compileType (result = new Result), {type: 'dsvalue'}, {}, context: 'field'

        expect(result.messages).sameStructure [{type: 'error', code: 'dsc.notAllowedInFieldDef', value: 'dsvalue'}]

        res = compileType (result = new Result), {type: 'dsvalue'}, {}, context: 'udtype'

        expect(result.messages).sameStructure []

      check "error: attr 'null' is not allowed in udt", ->

        res = compileType (result = new Result), {type: 'dsvalue', null: true}, {}, context: 'udtype'

        expect(result.messages).sameStructure [{type: 'error', path: 'null', code: 'dsc.notApplicableInUdtype'}]

Дальнейшая обработка на наличие udt - это отдельный шаг в спецификации ...config_udtypes
