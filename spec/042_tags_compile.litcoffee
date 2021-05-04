Tags.Compile
==============================

    {Result, tags: {compile: compileTags}, sortedMap, flatMap} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '042_tags_compile', ->

Тегирование нужно для работы с группами элементов.  Например, через теги можно указать в свойствах *doc.state.view* и
*doc.state.update* группу полей.

Теги назначаются на элементы (например, поля), через свойство *tags*.

Теги могут быть указаны как:
* массив строчных значений
* строка, с названиями тегов разделенными запятыми

Теги не могут нести в себе дополнительную информацию

В результатет обработки результата работы utils.sortedMap, в него добавляется объект *$$tags*, в котором каждому
ключу-тегу, соотвествует список элементов sortedMap

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

Можно тегировать элементы в иерархической структуре, которую готовить flatMap.

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

-- При этом теги нормализуются методом BitArray.fixVertical() --

        expect(fields.$$tags.admin.valueOf()).toEqual [0, 3]
        expect(fields.$$tags.user.valueOf()).toEqual [0, 2]

Если поле tag одного из элементов содержит недопустимое значение.  Возвращается ошибка с указанием неправильного
значения.  К какому элементу односится значение и к какому свойству элемента - указано в контексте ошибки.

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

Если в списке tags содержится неверное значение - возвращается соотвествующее сообщение, с указанием индекса
неправильного значения в списке

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

Если список тего содержит повторяющиеся значени - возвращается предупреждение

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

Все имена тегов должны соотвествовать соглашению об именование элементов.  Иначе ошибка.

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

Имя тега 'all' зарезервировано, и не может явно использоваться

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
