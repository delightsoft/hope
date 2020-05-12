flat map masks
==============================

    {Result, flatMap, BitArray} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '009_flatMap_masks:', ->

При работе с иерархической структурой, полезно для элементов содержащих вложенные элементы, помимо $$index, заранее
посчитать маски, включающие поле, со всеми вложенными в него полями.

Эта функциональность - опция метода flatMap, но вынесена в отдельную спецификацию, так как для этого используется
bitArray, который в свою очередь специфицирован через базовую функциональность flatMap.

      beforeEach ->

        doc =
          fld1: {}
          fld2:
            fields:
              fld2a: {}
              fld2b:
                fields:
                  fld2b1: {}
          fld3: {}

        @map = flatMap (result = new Result), doc, 'fields', index: true, mask: true

        flatMap.finish result, @map, 'fields'

        expect(result.messages).sameStructure []

      check "general", ->

        expect(@map.fld1.$$mask).not.toBeDefined()
        expect(@map.fld2.$$mask.valueOf()).toEqual [2, 3, 4]
        expect(@map.fld2.fields.fld2a.$$mask).not.toBeDefined()
        expect(@map.fld2.fields.fld2b.$$mask.valueOf()).toEqual [4]
        expect(@map.fld2.fields.fld2b.fields.fld2b1.$$mask).not.toBeDefined()
        expect(@map.fld3.$$mask).not.toBeDefined()

      check "mask requires index", ->

        expect(-> flatMap (result = new Result), {}, 'fields', mask: true).toThrow new Error 'opts.mask requires opts.index to be true'

Для работы с вложенными полями, мы придерживаемся следующих правил:
- если отмеченно хотя бы одно вложенное поле, то надо отместить в маске и поле в которое оно входит
- и наоборот, если в отмеченном поле не ни одного отмеченного вложенного поля - то надо отметить все

      check "fix items vertical", ->

        mask = new BitArray @map

        mask.set @map.fld2.fields.fld2b.$$index

        mask.fixVertical()

        expect(mask.valueOf()).toEqual [1,3,4]

Однако это правильно верно, когда мы собираем данные по доступности полей перед началом логических операций с масками

Есть обратная задача, если после логических операций с масками, у нас выбраны поля с вложенными полями, у которых
не выбранно ни одного вложенного поля, то такое поле надо убрать из результата

      check "clear items vertical", ->

        mask = new BitArray @map

        mask.set @map.fld2.$$index

        mask.set @map.fld2.fields.fld2b.$$index

        mask.clearVertical()

        expect(mask.valueOf()).toEqual []
