Tags.Compile
==============================

    {Result, tags: {compile: compileTags}, sortedMap, flatMap} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '042_tags_compile', ->

Tagging is needed for working with groups of elements.  For example, through tags one can specify in the properties *doc.state.view* and
*doc.state.update* a group of fields.

Tags are assigned to elements (for example, fields) via the *tags* property.

Tags can be specified as:
* an array of string values
* a string, with tag names separated by commas

Tags cannot carry any additional information

As a result of processing the result of utils.sortedMap, an object *$$tags* is added to it, in which each
key-tag corresponds to a list of sortedMap elements

      check 'correct work: tags as string', ->

        fields =
          fld1: {type: 'integer', tags: 'user, admin'}
          fld2: {type: 'text', tags: 'user'}
          fld3: {type: 'uuid'}

        fields = sortedMap (result = new Result), fields, validate: false

        expect(result.messages).toEqual []

        sortedMap.index result, fields, mask: true

        expect(result.messages).toEqual []

        compileTags result, fields

        expect(result.messages).toEqual []

        sortedMap.finish result, fields, validate: false

        expect(result.messages).toEqual []

        expect(fields.$$tags.all.valueOf()).toEqual [0, 1, 2]
        expect(fields.$$tags.admin.valueOf()).toEqual [0]
        expect(fields.$$tags.user.valueOf()).toEqual [0, 1]

      check 'correct work: tags as lists', ->

        fields =
          fld1: {type: 'integer', tags: ['user', 'admin']}
          fld2: {type: 'text', tags: ['user']}
          fld3: {type: 'uuid'}

        fields = sortedMap (result = new Result), fields, validate: false

        expect(result.messages).toEqual []

        sortedMap.index result, fields, mask: true

        expect(result.messages).toEqual []

        compileTags result, fields

        expect(result.messages).toEqual []

        sortedMap.finish result, fields, validate: false

        expect(result.messages).toEqual []

        expect(fields.$$tags.all.valueOf()).toEqual [0, 1, 2]
        expect(fields.$$tags.admin.valueOf()).toEqual [0]
        expect(fields.$$tags.user.valueOf()).toEqual [0, 1]

Elements can be tagged in a hierarchical structure, which is prepared by flatMap.

      check 'tags on subelements', ->

        fields =
          fld1: {type: 'integer', tags: 'user, admin'}
          fld2:
            fields:
              fld2a:
                tags: 'user'
                fields:
                  fld2a1: {tags: 'admin'}
                  fld2a2: {}
          fld3: {type: 'uuid'}

        fields = flatMap (result = new Result), fields, 'fields'

        expect(result.messages).toEqual []

        flatMap.index result, fields, 'fields', skipProps: ['tags'], mask: true

        expect(result.messages).toEqual []

        compileTags result, fields

        expect(result.messages).toEqual []

        flatMap.finish result, fields, 'fields', skipProps: ['tags'], validate: false

        expect(result.messages).toEqual []

-- At the same time the tags are normalized by the BitArray.fixVertical() method --

        expect(fields.$$tags.admin.valueOf()).toEqual [0, 3]
        expect(fields.$$tags.user.valueOf()).toEqual [0, 2]

If the tags field of one of the elements contains an invalid value.  An error is returned indicating the incorrect
value.  Which element the value relates to and which property of the element is indicated in the error context.

      for errValue in [undefined, null, false, true, 12, {}]

        do (errValue) -> check "invalid value: #{errValue}", ->

          fields =
            fld1: {type: 'integer', tags: 'user, admin'}
            fld2: {type: 'text', tags: errValue}
            fld3: {type: 'uuid'}

          fields = flatMap (result = new Result), fields, 'fields'

          expect(result.messages).toEqual []

          flatMap.index result, fields, 'fields', skipProps: ['tags'], mask: true

          expect(result.messages).toEqual []

          compileTags result, fields

          expect(result.messages).sameStructure [
            {type: 'error', path: 'fld2.tags', code: 'dsc.invalidValue', value: errValue}
          ]

If the tags list contains an incorrect value - a corresponding message is returned, indicating the index
of the incorrect value in the list

      for errValue in [undefined, null, false, true, 12, {}]

        do (errValue) -> check "invalid value: #{errValue}", ->

          fields =
            fld1: {type: 'integer', tags: 'user, admin'}
            fld2: {type: 'text', tags: ['user', errValue, 'go']}
            fld3: {type: 'uuid'}

          fields = flatMap (result = new Result), fields, 'fields'

          expect(result.messages).toEqual []

          flatMap.index result, fields, 'fields', mask: true

          expect(result.messages).toEqual []

          compileTags result, fields

          expect(result.messages).sameStructure [
            {type: 'error', path: 'fld2.tags', code: 'dsc.invalidTagValue', value: errValue, index: 1}
          ]

If the list of tags contains a duplicated value - a warning is returned

      check "invalid element of tags list", ->

        fields =
          fld1: {type: 'integer', tags: ['user', 'admin']}
          fld2: {type: 'text', tags: ['user', 'a', 'user']}
          fld3: {type: 'uuid'}

        fields = flatMap (result = new Result), fields, 'fields'

        expect(result.messages).toEqual []

        flatMap.index result, fields, 'fields', mask: true

        expect(result.messages).toEqual []

        compileTags result, fields

        expect(result.isError).toBe false

        expect(result.messages).sameStructure [
          {type: 'warn', path: 'fld2.tags', code: 'dsc.duplicatedTag', value: 'user'}
        ]

All tag names must conform to the element naming convention.  Otherwise, an error.

      check "invalid tag name", ->

        fields =
          fld1: {type: 'integer', tags: ['user', 'Admin']}
          fld2: {type: 'text', tags: ['user', 'A', 'A']}
          fld3: {type: 'uuid'}

        fields = flatMap (result = new Result), fields, 'fields'

        expect(result.messages).toEqual []

        flatMap.index result, fields, 'fields', mask: true

        expect(result.messages).toEqual []

        compileTags result, fields

        expect(result.messages).sameStructure [
          {type: 'error', path: 'fld1.tags', code: 'dsc.invalidName', value: 'Admin'}
          {type: 'error', path: 'fld2.tags', code: 'dsc.invalidName', value: 'A'}
          {type: 'warn', path: 'fld2.tags', code: 'dsc.duplicatedTag', value: 'A'}
        ]

The tag name 'all' is reserved, and cannot be used explicitly

      check "reserved tag 'all'", ->

        fields =
          fld1: {type: 'integer', tags: 'user, admin, all'}
          fld2: {type: 'text', tags: ['user', 'all']}
          fld3: {type: 'uuid'}

        fields = flatMap (result = new Result), fields, 'fields'

        expect(result.messages).toEqual []

        flatMap.index result, fields, 'fields', mask: true

        expect(result.messages).toEqual []

        compileTags result, fields

        expect(result.isError).toBe true

        expect(result.messages).sameStructure [
          {type: 'error', path: 'fld1.tags', code: 'dsc.reservedName', value: 'all'}
          {type: 'error', path: 'fld2.tags', code: 'dsc.reservedName', value: 'all'}
        ]
