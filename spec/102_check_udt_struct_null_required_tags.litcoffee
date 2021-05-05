config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    processCustomValidate = require '../src/validate/processCustomValidate'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '102_check_udt_struct_null_required_tags', ->

      check 'tags', ->

        res = compileConfig (result = new Result),

          udtypes:

            str1: fields:

              a: type: 'int', tags: 'tagA'

              b: type: 'string(20)', tags: 'tagB'

          docs:

            Doc1:

              fields:

                s1: type: 'str1'

                s2: type: 'str1', null: true

                s3: type: 'str1', required: true, tags: 'tagB'

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig, true

        expect(linkedConfig).sameStructure res

        expect(linkedConfig.docs['doc.Doc1'].fields.$$tags['tagA'].valueOf()).toEqual [3, 6, 9]

        expect(linkedConfig.docs['doc.Doc1'].fields.$$tags['tagB'].valueOf()).toEqual [4, 7, 8, 10]

      check 'null, required', ->

        res = compileConfig (result = new Result),

          udtypes:

            str1: type: 'struct', fields:

              a: type: 'int'

            st1: type: 'subtable', fields:

              b: type: 'int'

          docs:

            Doc1:

              fields:

                s1: type: 'str1'

                s2: type: 'str1', null: true

                s3: type: 'str1', null: true, required: true

                t1: type: 'st1'

                t2: type: 'st1', null: true

                t3: type: 'st1', null: true, required: true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        doc =
          s1: a: 12
          s2: null
          s3: null
          t1: [{b: 12}]
          t2: null
          t3: null

        linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), doc, beforeSave: true

        expect(result.messages).toEqual []

        linkedConfig.docs['doc.Doc1'].$$validate (result = new Result), doc, beforeAction: true

        expect(result.messages).toEqual [
          {type: 'error', path: 's3', code: 'validate.requiredField', value: null}
          {type: 'error', path: 't3', code: 'validate.requiredField', value: null}
        ]

      check 'init', ->

        res = compileConfig (result = new Result),

          udtypes:

            str1: type: 'struct', fields:

              a: type: 'int'

            st1: type: 'subtable', fields:

              b: type: 'int'

          docs:

            Doc1:

              fields:

                s1: type: 'str1'

                s2: type: 'str1', null: true

                t1: type: 'st1'

                t2: type: 'st1', required: true

                t3: type: 'st1', null: true

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        doc = linkedConfig.docs['doc.Doc1'].fields.$$new()

        expect(doc).toEqual

          s1: {a: 0}

          s2: null

          t1: []

          t2: [{b: 0}]

          t3: null

      check 'init not applicable for struct and subtable', ->

        res = compileConfig (result = new Result),

          udtypes:

            str1: type: 'struct', fields:

              a: type: 'int'

            st1: type: 'subtable', fields:

              b: type: 'int'

          docs:

            Doc1:

              fields:

                s1: type: 'str1', init: {a: 12}

                t1: type: 'st1', init: [{a: 12}]

        expect(result.messages).toEqual [
          {type: 'error', path: "docs['doc.Doc1'].fields.s1.init", code: 'dsc.unexpectedProp', value: {a: 12}}
          {type: 'error', path: "docs['doc.Doc1'].fields.t1.init", code: 'dsc.unexpectedProp', value: [{a: 12}]}
        ]
