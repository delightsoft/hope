bit array
==============================

    {Result, BitArray, sortedMap, flatMap} = require '../src'
    calc = require '../src/tags/_calc'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

Для операций с группами элементов (fields, actions etc.) удобно представить выбранные поля, в виде битовой маски.  И тогда
можно быстро и уверенно выполнять операции по объединению групп, вычитанию или нахождению общих элементов.  При этом
в результате сохраняется исходная последовательность элементов.

Входящая для BitArray может быть как одноуровневая - просто sortedMap

    _sortedMapCollection = ->

      res = sortedMap (result = new Result), (@["item#{i}"] = {name: "item#{i}", $$index: i} for i in [0...50]), index: true

      sortedMap.finish result, res

      expect(result.messages).sameStructure []

      res # _sortedMapCollection =

Так и многоуровневая - flatMap

    _flatMapCollection = ->

      srcCol = []

      index = 0

      for i in [0...12] by 2 # in result got to be more then 32 items

        srcCol.push # element with subitems
          name: "item#{i}"
          $$index: index++
          subitems: (@["item#{i}x#{j}"] = {name: "item#{i}x#{j}", fullname: "item#{i}.item#{i}x#{j}", $$index: index++} for j in [0...3]) # always three subitems

        srcCol.push # no subitems element
          name: "item#{i + 1}"
          $$index: index++

      res = flatMap (result = new Result), srcCol, 'subitems', index: true

      flatMap.finish result, res, 'subitems'

      expect(result.messages).sameStructure []

      res # _flatMapCollection =

    describe '008_bitArray:', ->

      check 'general: sortedMap', ->

        arr = new BitArray _sortedMapCollection.call @

        arr.set 1, true

        arr.set 3, true

        expect(arr.list).sameStructure [@item1, @item3]

        expect(arr.get 0).toBe false
        expect(arr.get 1).toBe true
        expect(arr.get 2).toBe false
        expect(arr.get 3).toBe true

      check 'general: flatMap', ->

        arr = new BitArray _flatMapCollection.call @

        arr.set 1, true

        arr.set 3, true

        expect(arr.list).sameStructure [@item0x0, @item0x2]

        expect(arr.get 0).toBe false
        expect(arr.get 1).toBe true
        expect(arr.get 2).toBe false
        expect(arr.get 3).toBe true

set()
------------------------------

При вызове метода set проверяется, что index попадает в размер данной коллекции

      check "set(): index range", ->

        arr = new BitArray _sortedMapCollection.call @

        expect(-> arr.set -1, true).toThrow new Error 'index out of range: -1'
        expect(-> arr.set 100, true).toThrow new Error 'index out of range: 100'

Второй параметр в методе set не обязательный.  Если не указан, то он считается true

      check "set(): default - true", ->

        arr = new BitArray _sortedMapCollection.call @

        arr.set 1

        expect(arr.list).sameStructure [@item1]

Можно указывать маску

#      check "set(): mask", ->
#
#        arr = new BitArray _sortedMapCollection.call @
#
#        arr.set 'item1,item2'
#
#        expect(arr.list).sameStructure [@item1, @item2]

Метод set делает новую копию объекта если заблокирован методом lock()

      check "set() clone object after .lock()", ->

        arr = new BitArray _sortedMapCollection.call @

        expect(arr.set 1).toBe(arr)

        arr.lock()

        expect(arr.set 2).not.toBe(arr)

and, or ...
------------------------------

Есть несколько логических операций, которые можно выполнить над bitArray:
- and - пересечение

      check "add(): sortedMap", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        arr1.set item.$$index for item in map.$$list by 3

        arr2 = new BitArray map

        arr2.set item.$$index for item in map.$$list by 2

        arr3 = arr1.and arr2

        expect(arr3.list).sameStructure (item for item in map.$$list by 6)

      check "add(): flatMap", ->

        arr1 = new BitArray map = _flatMapCollection.call @

        arr1.set item.$$index for item in map.$$flat.$$list by 3

        arr2 = new BitArray map

        arr2.set item.$$index for item in map.$$flat.$$list by 2

        arr3 = arr1.and arr2

        expect(arr3.list).sameStructure (item for item in map.$$flat.$$list by 6)

- or - объединение

      check "or(): sortedMap", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        arr1.set item.$$index for item in map.$$list by 3

        arr2 = new BitArray map

        arr2.set item.$$index for item in map.$$list by 2

        arr3 = arr1.or arr2

        expect(arr3.list).sameStructure (item for item, i in map.$$list when i %% 2 == 0 || i %% 3 == 0)

      check "or(): flatMap", ->

        arr1 = new BitArray map = _flatMapCollection.call @

        arr1.set item.$$index for item in map.$$flat.$$list by 3

        arr2 = new BitArray map

        arr2.set item.$$index for item in map.$$flat.$$list by 2

        arr3 = arr1.or arr2

        expect(arr3.list).sameStructure (item for item, i in map.$$flat.$$list when i %% 2 == 0 || i %% 3 == 0)

- invert - получение обратной коллекции

      check "subtract(): sortedMap", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        arr1.set item.$$index for item in map.$$list by 3

        arr2 = arr1.invert()

        expect(arr2.list).sameStructure (item for item, i in map.$$list when i %% 3 != 0)

      check "subtract(): flatMap", ->

        arr1 = new BitArray map = _flatMapCollection.call @

        arr1.set item.$$index for item in map.$$flat.$$list by 3

        arr2 = arr1.invert()

        expect(arr2.list).sameStructure (item for item, i in map.$$flat.$$list when i %% 3 != 0)

- subtract - получение коллекции элменетов, которые есть в левом bitArray, но нет в правом

      check "subtract(): sortedMap", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        arr1.set item.$$index for item in map.$$list by 3

        arr2 = new BitArray map

        arr2.set item.$$index for item in map.$$list by 2

        arr3 = arr1.subtract arr2

        expect(arr3.list).sameStructure (item for item, i in map.$$list when i %% 2 != 0 && i %% 3 == 0)

      check "subtract(): flatMap", ->

        arr1 = new BitArray map = _flatMapCollection.call @

        arr1.set item.$$index for item in map.$$flat.$$list by 3

        arr2 = new BitArray map

        arr2.set item.$$index for item in map.$$flat.$$list by 2

        arr3 = arr1.subtract arr2

        expect(arr3.list).sameStructure (item for item, i in map.$$flat.$$list when i %% 2 != 0 && i %% 3 == 0)

Можно проверить что маска не содержит ни одного элемента

      check "empty", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        expect(arr1.isEmpty()).toBe true

        arr1.set 2

        expect(arr1.isEmpty()).toBe false

Важно, чтобы после invert в маскве не появлялись лишние биты, которые будут влиять на результат операции isEmpty()

      check "empty after invert", ->

        map = sortedMap (result = new Result), ({name: "item#{i}"} for i in [0...50]), index: true

        expect(result.messages).toEqual []

        arr1 = new BitArray map

        arr1.set item.$$index for item in map.$$list

        arr2 = arr1.invert()

        expect(arr2.isEmpty()).toBe true

-- Все операции над группами immutable - то есть каждый раз возвращается новые объект.
!!! TODO: переписать под lock()

      check "immutable", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        expect(arr2 = arr1.invert()).toBe arr1

        expect(arr1.and arr2).toBe arr1
        expect(arr1.and arr2).toBe arr2

        expect(arr1.or arr2).toBe arr1
        expect(arr1.or arr2).toBe arr2

        expect(arr1.subtract arr2).toBe arr1
        expect(arr1.subtract arr2).toBe arr2

BitArray привязан к исходной коллекции.  Если по ошибке выполнить операции над bit array'ями для разных исходных
коллекций - будет exception.

      check "must have the same collection", ->

        arr1 = new BitArray map1 = _sortedMapCollection.call @

        arr2 = new BitArray map2 = _sortedMapCollection.call @

        expect(-> arr1.and arr2).toThrow new Error 'given bitArray is different collection'
        expect(-> arr1.or arr2).toThrow new Error 'given bitArray is different collection'
        expect(-> arr1.subtract arr2).toThrow new Error 'given bitArray is different collection'

Если запрашивается список элементов, то он формируется при первом вызове.  При повторных вызовах возвращает ранее
созданный список, так как он не мог поменяться у immutable объекта.

      check "always same list", ->

        arr1 = new BitArray _sortedMapCollection.call @

        arr1.set 2

        list = arr1.list

        expect(arr1.list).toBe list

На вход можно подавать пустые коллекции, это создает работоспособные маски, который для любого get возвращают exception

      check "empty map", ->

        arr1 = new BitArray sortedMap.empty
        arr2 = new BitArray sortedMap.empty

        expect(arr1.valueOf()).toEqual []
        expect(arr1.invert().valueOf()).toEqual []
        expect(arr1.or(arr2).valueOf()).toEqual []
        expect(arr1.and(arr2).valueOf()).toEqual []
        expect(arr1.subtract(arr2).valueOf()).toEqual []
        expect(-> arr1.get(0)).toThrow new Error 'index out of range: 0'

      check "edit/lock", ->

        collection = _sortedMapCollection.call @
        collection.$$tags = {none: new BitArray collection}
        collection.$$calc = ->
          last = arguments[arguments.length - 1]
          result = new Result
          r =
            if typeof last == 'object'
              if arguments.length == 1
                collection.$$tags.none
              else if arguments.length == 2
                calc result, collection, arguments[0], last
              else
                calc result, collection, (Array::slice.call arguments, 0, arguments.length - 1).join(','), last
            else
              if arguments.length == 0
                collection.$$tags.none
              else if arguments.length == 1
                calc result, collection, arguments[0]
              else
                calc result, collection, (Array::slice.call arguments).join(',')
          result.throwIfError()
          r

        arr1 = new BitArray collection
        arr2 = new BitArray collection

        expect(arr1.and(arr2)).toBe(arr1)

        arr1.lock()

        expect(arr1.and(arr2)).not.toBe(arr1)

        arr1.and('item1,item2', 'item10', {fixVertical: true})

        arr1.and('item1,item2', 'item10')
