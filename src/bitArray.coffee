{err: {invalidArg, tooManyArgs}} = require './utils'

class BitArray

  constructor: (arg1, arg2) ->

    if Array.isArray arg1 # it's private constructor

      @_collection = arg1

      @_mask = arg2

    else

      invalidArg 'arg1', arg1 unless typeof arg1 == 'object' && arg1 != null && arg1.hasOwnProperty('$$list')
      tooManyArgs() unless arguments.length <= 1

      @_collection = collection = if arg1.hasOwnProperty('$$flat') then arg1.$$flat.$$list else arg1.$$list

      @_mask = mask = new Array len = Math.trunc (collection.length + 31) / 32

      mask[i] = 0 for i in [0...len]

    return # constructor:

  set: (index, value) ->

    invalidArg 'index' unless typeof index == 'number' && index % 1 == 0
    if value == undefined then value = true
    else invalidArg 'value', value unless typeof value == 'boolean'
    tooManyArgs() unless arguments.length <= 2

    throw new Error "set() is not allowed in this state" if @.hasOwnProperty('_list')
    throw new Error "index out of range: #{index}" unless 0 <= index < @_collection.length

    m = 1 << index % 32

    if value

      @_mask[Math.trunc index / 32] |= m

    else

      @_mask[Math.trunc index / 32] &= ~m

    @ # set:

  get: (index) ->

    invalidArg 'index' unless typeof index == 'number' && index % 1 == 0
    if value == undefined then value = true
    tooManyArgs() unless arguments.length <= 1

    throw new Error "index out of range: #{index}" unless 0 <= index < @_collection.length

    (@_mask[Math.trunc index / 32] & (1 << index % 32)) != 0 # get:

  and: (bitArray) ->

    invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
    tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_collection == (collection = bitArray._collection)

    resMask = new Array (len = (leftMask = @_mask).length)
    rightMask = bitArray._mask

    for i in [0...len] by 1

      resMask[i] = leftMask[i] & rightMask[i]

    new BitArray collection, resMask # and:

  or: (bitArray) ->

    invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
    tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_collection == (collection = bitArray._collection)

    resMask = new Array (len = (leftMask = @_mask).length)
    rightMask = bitArray._mask

    for i in [0...len] by 1

      resMask[i] = leftMask[i] | rightMask[i]

    new BitArray collection, resMask # and:

  subtract: (bitArray) ->

    invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
    tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_collection == (collection = bitArray._collection)

    resMask = new Array (len = (leftMask = @_mask).length)
    rightMask = bitArray._mask

    for i in [0...len] by 1

      resMask[i] = leftMask[i] & ~rightMask[i]

    new BitArray collection, resMask # and:

  invert: ->

    tooManyArgs() unless arguments.length == 0

    resMask = new Array (len = (leftMask = @_mask).length)

    for i in [0...len] by 1

      resMask[i] = ~leftMask[i]

    if (r = @_collection.length % 32) > 0

      resMask[len - 1] &= ((1 << r) - 1)

    new BitArray @_collection, resMask # and:

  isEmpty: ->

    for v in @_mask when v != 0

      return false

    true # isEmpty:

  fixVertical: ->

    for item in @_collection when item.hasOwnProperty('$$mask')

      itemMask = item.$$mask._mask

      mask = @_mask

      noSubfields = true

      for i in [0...mask.length] by 1 when (mask[i] & itemMask[i]) != 0

        noSubfields = false

        break

      if @get item.$$index

        if noSubfields

          mask[i] |= itemMask[i] for i in [0...mask.length] by 1

      else if not noSubfields

        @set item.$$index

    return # fixVertical:

  clearVertical: ->

    for item in @_collection by -1 when item.hasOwnProperty('$$mask')

      itemMask = item.$$mask._mask

      mask = @_mask

      noSubfields = true

      for i in [0...mask.length] by 1 when (mask[i] & itemMask[i]) != 0

        noSubfields = false

        break

      @set item.$$index, !noSubfields

    return # clearVertical:

  valueOf: ->

    res = []

    len = (collection = @_collection).length

    m = 1

    v = (mask = @_mask)[p = 0]

    for i in [0...len] by 1

      res.push i if (v & m) != 0

      if (m <<= 1) == 0

        m = 1

        v = mask[++p]

    res # valueOf:

Object.defineProperty BitArray::, 'list',

  configurable: true

  enumerable: true

  get: ->

    unless @.hasOwnProperty('_list')

      @_list = list = []

      len = (collection = @_collection).length

      m = 1

      v = (mask = @_mask)[p = 0]

      for i in [0...len] by 1

        list.push collection[i] if (v & m) != 0

        if (m <<= 1) == 0

          m = 1

          v = mask[++p]

    @_list # get: ->

# ----------------------------

module.exports = BitArray
