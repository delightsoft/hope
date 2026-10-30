Tags.Namespace
==============================

  {Result, tags: {compile: compileTags}, flatMap} = require '../src'

  focusOnCheck = ''
  check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

  describe '044_tags_namespace', ->

A namespace can be added to tag names either by specifying it in the tags field in the tag name or by specifying it in the field name

    check "tags with namespace in tags name", ->

      fields =
        fld1: {type: 'integer', tags: 'user, test.admin'}
        fld2: {type: 'text', tags: ['test.abc', 'json']}
        fld3: {type: 'uuid'}

      fields = flatMap (result = new Result), fields, 'fields', index: true, mask: true, validate: false

      expect(result.messages).toEqual []

      flatMap.index result, fields, 'fields', mask: true

      expect(result.messages).toEqual []

      compileTags (result = new Result), fields

      expect(result.messages).toEqual []

      expect(fields.$$tags.hasOwnProperty('json')).toBe true
      expect(fields.$$tags.hasOwnProperty('test.abc')).toBe true

    check "tags with namespace in tags attr", ->

      fields =
        fld1: {
          type: 'integer',
          tags: 'user'
          'tags.test': 'user'
        }
        fld2: {
          type: 'text',
          tags: ['json']
          'tags.test': ['abc']
        }
        fld3: {type: 'uuid'}

      fields = flatMap (result = new Result), fields, 'fields'

      expect(result.messages).toEqual []

      flatMap.index result, fields, 'fields', mask: true

      expect(result.messages).toEqual []

      compileTags (result = new Result), fields

      expect(result.messages).toEqual []

      expect(fields.$$tags.hasOwnProperty('json')).toBe true
      expect(fields.$$tags.hasOwnProperty('test.abc')).toBe true

In the tags attributes with a namespace it is not allowed to specify tags with a namespace

    check "tags with ambiguous namespaces", ->

      fields =
        fld1: {
          type: 'integer',
          tags: 'user'
          'tags.test': 'test.user'
        }
        fld2: {
          type: 'text',
          tags: ['json']
          'tags.test': ['test.abc']
        }
        fld3: {type: 'uuid'}

      fields = flatMap (result = new Result), fields, 'fields'

      expect(result.messages).toEqual []

      flatMap.index result, fields, 'fields', mask: true

      expect(result.messages).toEqual []

      compileTags (result = new Result), fields

      expect(result.messages).toEqual [
        {type: 'error', path: 'fld1[\'tags.test\']', code: 'dsc.ambiguousNamespaces', value1: 'tags.test', value2: 'test.user'}
        {type: 'error', path: 'fld2[\'tags.test\']', code: 'dsc.ambiguousNamespaces', value1: 'tags.test', value2: 'test.abc'}
      ]
