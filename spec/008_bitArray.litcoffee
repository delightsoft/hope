bit array
==============================

    {Result, BitArray, sortedMap, flatMap} = require '../src'
    calc = require '../src/tags/_calc'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

For operations with groups of elements (fields, actions etc.) it is convenient to represent the selected fields as a bit mask.  Then one
can quickly and confidently perform operations of merging groups, subtracting them, or finding common elements.  At the same time
the original sequence of elements is preserved in the result.

The input for BitArray can be single-level - just a sortedMap

    _sortedMapCollection = ->

      res = sortedMap (result = new Result), (@["item#{i}"] = {name: "item#{i}", $$index: i} for i in [0...50])

      sortedMap.index result, res

      sortedMap.finish result, res

      expect(result.messages).sameStructure []

      res.$$tags = {none: new BitArray res}
      res.$$calc = ->
        last = arguments[arguments.length - 1]
        result = new Result
        r =
          if typeof last == 'object'
            if arguments.length == 1
              res.$$tags.none
            else if arguments.length == 2
              calc result, res, arguments[0], last
            else
              calc result, res, (Array::slice.call arguments, 0, arguments.length - 1).join(','), last
          else
            if arguments.length == 0
              res.$$tags.none
            else if arguments.length == 1
              calc result, res, arguments[0]
            else
              calc result, res, (Array::slice.call arguments).join(',')
        result.throwIfError()
        r

      res # _sortedMapCollection =

And also multi-level - flatMap

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

      res = flatMap (result = new Result), srcCol, 'subitems'

      flatMap.index result, res, 'subitems'

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

When the set method is called, it is checked that index falls within the size of the given collection

      check "set(): index range", ->

        arr = new BitArray _sortedMapCollection.call @

        expect(-> arr.set -1, true).toThrow new Error 'index out of range: -1'
        expect(-> arr.set 100, true).toThrow new Error 'index out of range: 100'

The second parameter of the set method is optional.  If it is not specified, then it is considered true

      check "set(): default - true", ->

        arr = new BitArray _sortedMapCollection.call @

        arr.set 1

        expect(arr.list).sameStructure [@item1]

A mask can be specified

      check "set(): mask", ->

        arr = new BitArray _sortedMapCollection.call @

        arr.set 'item1,item2'

        expect(arr.list).sameStructure [@item1, @item2]

The set method makes a new copy of the object if it is locked by the lock() method

      check "set() clone object after .lock()", ->

        arr = new BitArray _sortedMapCollection.call @

        expect(arr.set 1).toBe(arr)

        arr.lock()

        expect(arr.set 2).not.toBe(arr)

and, or ...
------------------------------

There are several logical operations that can be performed on a bitArray:
- and - intersection

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

- or - union

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

- invert - obtaining the inverted collection

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

- subtract - obtaining the collection of elements that are present in the left bitArray but not in the right one

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

One can check that the mask contains no elements

      check "empty", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        expect(arr1.isEmpty()).toBe true

        arr1.set 2

        expect(arr1.isEmpty()).toBe false

It is important that after invert no extra bits appear in the mask, which would affect the result of the isEmpty() operation

      check "empty after invert", ->

        map = sortedMap (result = new Result), ({name: "item#{i}"} for i in [0...50])

        sortedMap.index result, map

        sortedMap.finish result, map

        expect(result.messages).toEqual []

        arr1 = new BitArray map

        arr1.set item.$$index for item in map.$$list

        arr2 = arr1.invert()

        expect(arr2.isEmpty()).toBe true

-- All operations on groups are immutable - that is, each time a new object is returned.
!!! TODO: rewrite to use lock()

      check "immutable", ->

        arr1 = new BitArray map = _sortedMapCollection.call @

        expect(arr2 = arr1.invert()).toBe arr1

        expect(arr1.and arr2).toBe arr1
        expect(arr1.and arr2).toBe arr2

        expect(arr1.or arr2).toBe arr1
        expect(arr1.or arr2).toBe arr2

        expect(arr1.subtract arr2).toBe arr1
        expect(arr1.subtract arr2).toBe arr2

BitArray is bound to the original collection.  If operations on bit array's are erroneously performed for different original
collections - there will be an exception.

      check "must have the same collection", ->

        arr1 = new BitArray map1 = _sortedMapCollection.call @

        arr2 = new BitArray map2 = _sortedMapCollection.call @

        expect(-> arr1.and arr2).toThrow new Error 'given bitArray is different collection'
        expect(-> arr1.or arr2).toThrow new Error 'given bitArray is different collection'
        expect(-> arr1.subtract arr2).toThrow new Error 'given bitArray is different collection'

If the list of elements is requested, it is formed on the first call.  On repeated calls the previously
created list is returned, since it could not have changed in an immutable object.

      check "always same list", ->

        arr1 = new BitArray _sortedMapCollection.call @

        arr1.set 2

        list = arr1.list

        expect(arr1.list).toBe list

Empty collections can be supplied as input; this creates workable masks, which for any get return an exception

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

        arr1 = new BitArray collection
        arr2 = new BitArray collection

        expect(arr1.and(arr2)).toBe(arr1)

        arr1.lock()

        expect(arr1.and(arr2)).not.toBe(arr1)

        arr1.and('item1,item2', 'item10', {fixVertical: true})

        arr1.and('item1,item2', 'item10')
