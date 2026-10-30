sorted map
==============================

    {Result, sortedMap, utils: {checkItemName, deepClone, combineMsg, err: {isResult, invalidArg, tooManyArgs}}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '006_sortedMap:', ->

SortedMap is an agreement on working with collections of elements - lists of documents, fields, enum values and
so on. It is useful to have both a list of values and a map for quickly finding an element by name.

sortedMap turns a list or array into a map (object):
* the key is the name of the element, the value is the value of the element
* a special element - $$list, contains the list of elements
* all elements are converted into objects
* every element has a *name* property, corresponding to the name of the element
* and an *index* property, containing the index of the element in the list
* element names must consist of Latin characters and digits, and start with a digit or a lowercase letter

Important: sortedMap must be immutable, to make debugging easier - do not mutate the incoming data

sortedMap can be obtained from an object

      check "from map", ->

        res = sortedMap (result = new Result),

          doc1: {}

          doc2: {}

          doc3: {}

        expect(result.isError).toBe false

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {}}

          doc2: doc2 = {name: 'doc2', $$src: {}}

          doc3: doc3 = {name: 'doc3', $$src: {}}

          $$list: [doc1, doc2, doc3]

sortedMap can be obtained from an array

      check "from array", ->

        res = sortedMap (result = new Result), [{name: 'doc1'}, {name: 'doc2'}, {name: 'doc3'}]

        expect(result.isError).toBe false

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {name: 'doc1'}}

          doc2: doc2 = {name: 'doc2', $$src: {name: 'doc2'}}

          doc3: doc3 = {name: 'doc3', $$src: {name: 'doc3'}}

          $$list: [doc1, doc2, doc3]

And from a string

      check "from string", ->

        res = sortedMap (result = new Result), 'doc1, doc2, doc3', string: true

        expect(result.messages).sameStructure []

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1'}

          doc2: doc2 = {name: 'doc2'}

          doc3: doc3 = {name: 'doc3'}

          $$list: [doc1, doc2, doc3]

There are two parameters:
* result - an object of type Result
* value - the value to process

      check "invalid argument 'result'", ->

        expect(-> sortedMap()).toThrow new Error "Invalid argument 'result': undefined"

The value can only be either an object or an array

      for wrongValue in [undefined, null, false, 12, '']

        do (wrongValue) -> check "invalid argument 'value': #{jasmine.pp wrongValue}", ->

          sortedMap (result = new Result), wrongValue

          expect(result.isError).toBe true

          expect(result.messages).sameStructure [
            {type: 'error', code: 'dsc.invalidValue', value: wrongValue}
          ]

The value can be processed only once

      check "one time processing",  ->

        res = sortedMap (result = new Result), map =

          doc1: {}

        expect(-> sortedMap (result = new Result), res).toThrow new Error 'Value was already processed by sortedMap()'

If values are given as an object, then the values may contain name

      check "name in the element", ->

        res = sortedMap (result = new Result),

          doc1: {v: 12}

          doc2: {name: 'doc2', v: 20}

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {v: 12}}

          doc2: doc2 = {name: 'doc2', $$src: {name: 'doc2', v: 20}}

          $$list: [doc1, doc2]

But name in the value must match the key

      check "wrong name in the element", ->

        res = sortedMap (result = new Result), set =

          doc1: doc1 = {name: 'otherName', v: 12}

          doc2: {name: 'doc2', v: 20}

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'doc1', code: 'dsc.keyAndNameHasDifferenValues', value1: 'doc1', value2: 'otherName'}
        ]

The value in a map can be either an object or true

      check "'true' translated to object element map", ->

        res = sortedMap (result = new Result), {

          doc1: {v: 12}

          doc2: true

          doc3: {}}, boolean: true

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1', $$src: {v: 12}}

          doc2: doc2 = {name: 'doc2'}

          doc3: doc3 = {name: 'doc3', $$src: {}}

          $$list: [doc1, doc2, doc3]

      for wrongValue in [undefined, null, false, 12, 'a string', ['a', 'b']]

        do (wrongValue) -> check "invalid map element: #{wrongValue}", ->

          res = sortedMap (result = new Result), map =

            'doc1': wrongValue

          expect(result.isError).toBe true

          expect(result.messages).sameStructure [
            {type: 'error', path: 'doc1', code: 'dsc.invalidValue', value: wrongValue}
          ]

Values in an array can be either an object or a string

      check "'string' translated to an object in list", ->

        res = sortedMap (result = new Result), ['doc1', 'doc2'], string: true

        expect(result.messages).sameStructure []

        expect(res).sameStructure

          doc1: doc1 = {name: 'doc1'}

          doc2: doc2 = {name: 'doc2'}

          $$list: [doc1, doc2]

      for wrongValue in [undefined, null, true, false, 12, ['a', 'b']]

        do (wrongValue) -> check "invalid list element: #{wrongValue}", ->

          res = sortedMap (result = new Result), list = [wrongValue]

          expect(result.isError).toBe true

          expect(result.messages).sameStructure [
            {type: 'error', path: '[0]', code: 'dsc.invalidValue', value: wrongValue}
          ]

An object in an array must necessarily have the name property

      check "all list element must have 'name' prop", ->

        sortedMap (result = new Result), list = [{v: 12}, {name: 'doc2', v: 15}, {v: 20}]

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[0]', code: 'dsc.missingProp', value: 'name'}
          {type: 'error', path: '[2]', code: 'dsc.missingProp', value: 'name'}
        ]

There must be no elements with identical names in the array

      check "duplicated prop is not allowed in array", ->

        sortedMap (result = new Result), list = [{name: 'doc1'}, {name: 'doc1'}]

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[1]', code: 'dsc.duplicatedName', value: 'doc1'}
        ]

      check "duplicated prop is not allowed in comma separated string", ->

        sortedMap (result = new Result), list = 'doc1, doc1', string: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[1]', code: 'dsc.duplicatedName', value: 'doc1'}
        ]

Element names may consist only of Latin letters and digits, and must necessarily begin with a lowercase letter

      check "element 'name' prop must contain letters or digits, and start from lower char", ->

        sortedMap (result = new Result), list = [{name: 'BigName'}, {name: '4inch'}, {name: 'with space'}]

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[0]', code: 'dsc.invalidName', value: 'BigName'}
          {type: 'error', path: '[1]', code: 'dsc.invalidName', value: '4inch'}
          {type: 'error', path: '[2]', code: 'dsc.invalidName', value: 'with space'}
        ]

        sortedMap (result = new Result), value =
          BigName: {}
          '4inch': {}
          'with space': {}

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'BigName', code: 'dsc.invalidName', value: 'BigName'}
          {type: 'error', path: '4inch', code: 'dsc.invalidName', value: '4inch'}
          {type: 'error', path: 'with space', code: 'dsc.invalidName', value: 'with space'}
        ]

Modifying sortedMap behavior
------------------------------

The third parameter in sortedMap is options, which can contain the following properties
- checkName - the method for checking the spelling of a name
- getValue - allows processing an arbitrary value in a map and assigns the value into the result.
- boolean - true, if true may be specified as a value.  For maps only
- string - true, if a string or an array of strings may be specified as a value.  For lists only
- index - true, adds a $$index property to the elements, with the ordinal number of the element in $$list

      check "'boolean = false' option", ->

        sortedMap (result = new Result),  {
          item1: true
          item2: {}
          item3: true}, string: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'item1', code: 'dsc.invalidValue', value: true}
          {type: 'error', path: 'item3', code: 'dsc.invalidValue', value: true}
        ]

      check "'string = false' option: string value", ->

        sortedMap (result = new Result), val = "item1, item2, item3", boolean: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', code: 'dsc.invalidValue', value: val}
        ]

      check "'string = false' option: array with a string value", ->

        sortedMap (result = new Result), [{name: 'item1'}, 'item2'], boolean: true

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: '[1]', code: 'dsc.invalidValue', value: 'item2'}
        ]

      check "'getValue' option", ->

        actions =

          action1: f1 = ->

          action2: {value: f2 = ->}

The getValue method returns true if this is a supported type of value.  And this value has been transferred to dest - the
object being assembled

        res = sortedMap (result = new Result), actions, getValue: (result, value, res) ->

          expect(isResult result).toBe true
          expect(typeof res == 'object' && res != null && !Array.isArray(res)).toBe true
          expect(arguments.length <= 3)

          expect(value).toBe f1

          if typeof f1 == 'function'

              res.value = f1

              return true

          false

        sortedMap.finish result, res, validate: false

        expect(result.messages).toEqual []

        expect(res).sameStructure
          action1: action1 = {name: 'action1', value: f1}
          action2: action2 = {name: 'action2'}
          $$list: [action1, action2]

      check "'copyProps' option", ->

        actions =

          action1: f1 = ->

          action2: {value: f2 = ->}

The copyProps method copies the properties of the source map into the result

        res = sortedMap (result = new Result), actions,

        getValue: (result, value, res) ->

We do not copy the property in this method

          if typeof f1 == 'function'

            return true

          false

It is possible to add elements to the beginning and the end of the list during processing

      check "add items before and after", ->

        resValue = sortedMap (result = new Result), {field1: {}, field2: {}},
          before: [
            {
              name: 'id',
              type: 'string',
              length: 40,
            }
          ]
          after: [
            {
              name: 'created',
              type: 'timestamp',
            }
            {
              name: 'modified',
              type: 'timestamp',
            }
          ]

        expect(result.messages).toEqual []

        sortedMap.index result, resValue

        expect(result.messages).toEqual []

        expect(resValue).toEqual
          id: id = {name: 'id', $$src: {
            name: 'id',
            type: 'string',
            length: 40,
          }, $$index: 0}
          field1: field1 = {name: 'field1', $$src: {}, $$index: 1}
          field2: field2 = {name: 'field2', $$src: {}, $$index: 2}
          created: created = {name: 'created', $$src: {
            name: 'created',
            type: 'timestamp',
          }, $$index: 3}
          modified: modified = {name: 'modified', $$src: {
            name: 'modified',
            type: 'timestamp',
          }, $$index: 4}
          $$list: [id, field1, field2, created, modified]

        sortedMap.finish result, resValue, validate: false

        expect(result.messages).toEqual []

        expect(resValue).toEqual
          id: id = {name: 'id', $$index: 0}
          field1: field1 = {name: 'field1', $$index: 1}
          field2: field2 = {name: 'field2', $$index: 2}
          created: created = {name: 'created', $$index: 3}
          modified: modified = {name: 'modified', $$index: 4}
          $$list: [id, field1, field2, created, modified]
