invalidArg = (name, value) -> throw new Error "Invalid argument '#{name}': #{value}"; return
tooManyArgs = -> throw new Error "Too many arguments"; return

class BitArray

  constructor: (arg1, arg2, arg3) ->

    if Array.isArray arg1 # it's private constructor

      throw new Error "Invalid arg2: #{arg2}" unless Array.isArray arg2
      throw new Error "Invalid arg3: #{arg3}" unless typeof arg3 == 'object' and arg3.$$list

      @_list = arg1

      @_mask = arg2

      @_collection = arg3

    else

      invalidArg 'arg1', arg1 unless typeof arg1 == 'object' && arg1 != null && arg1.hasOwnProperty('$$list')
      tooManyArgs() unless arguments.length <= 1

      @_list = collection = if arg1.hasOwnProperty('$$flat') then arg1.$$flat.$$list else arg1.$$list

      @_mask = mask = new Array len = Math.trunc (collection.length + 31) / 32

      @_collection = arg1

      mask[i] = 0 for i in [0...len]

    @_edit = true

    return # constructor:

  set: (index, value) ->

    invalidArg 'index' unless typeof index == 'number' && index % 1 == 0
    if value == undefined then value = true
    else invalidArg 'value', value unless typeof value == 'boolean'
    tooManyArgs() unless arguments.length <= 2

    throw new Error "index out of range: #{index}" unless 0 <= index < @_list.length

    mask =
      if @_edit
        @_mask
      else
        r = new Array @_mask.length
        r[i] = v for v, i in @_mask
        r

    m = 1 << index % 32

    if value

      mask[Math.trunc index / 32] |= m

    else

      mask[Math.trunc index / 32] &= ~m

    if @_edit
      delete @_listProp
      @
    else
      new BitArray @_list, mask, @_collection # set:

  get: (index) ->

    invalidArg 'index', index unless typeof index == 'number' && index % 1 == 0
    if value == undefined then value = true
    tooManyArgs() unless arguments.length <= 1

    throw new Error "index out of range: #{index}" unless 0 <= index < @_list.length

    (@_mask[Math.trunc index / 32] & (1 << index % 32)) != 0 # get:

  equal: (bitArray) ->

    invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
    tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_list == (collection = bitArray._list)

    rightMask = bitArray._mask

    @_mask.every (v, i) -> rightMask[i] == v # equal:

  clone: () ->

    tooManyArgs() unless arguments.length <= 0

    resMask = new Array (len = (leftMask = @_mask).length)

    for i in [0...len] by 1

      resMask[i] = leftMask[i]

    new BitArray @_list, resMask, @_collection # clone:

  and: (bitArray) ->

    if typeof bitArray == 'string'

      bitArray = @_collection.$$calc.apply undefined, arguments

    else

      invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
      tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_list == bitArray._list

    len = (leftMask = @_mask).length
    resMask = if @_edit then @_mask else new Array len
    rightMask = bitArray._mask

    for i in [0...len] by 1

      resMask[i] = leftMask[i] & rightMask[i]

    if @_edit # and:
      delete @_listProp
      @
    else
      new BitArray @_list, resMask, @_collection

  or: (bitArray) ->

    if typeof bitArray == 'string'

      bitArray = @_collection.$$calc.apply undefined, arguments

    else

      invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
      tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_list == (collection = bitArray._list)

    len = (leftMask = @_mask).length
    resMask = if @_edit then @_mask else new Array len
    rightMask = bitArray._mask

    for i in [0...len] by 1

      resMask[i] = leftMask[i] | rightMask[i]

    if @_edit # or:
      delete @_listProp
      @
    else
      new BitArray @_list, resMask, @_collection

  subtract: (bitArray) ->

    if typeof bitArray == 'string'

      bitArray = @_collection.$$calc.apply undefined, arguments

    else

      invalidArg 'bitArray', bitArray unless typeof bitArray == 'object' && bitArray != null && bitArray.hasOwnProperty('_mask')
      tooManyArgs() unless arguments.length <= 1

    throw new Error 'given bitArray is different collection' unless @_list == (collection = bitArray._list)

    len = (leftMask = @_mask).length
    resMask = if @_edit then @_mask else new Array len
    rightMask = bitArray._mask

    for i in [0...len] by 1

      resMask[i] = leftMask[i] & ~rightMask[i]

    if @_edit # subtract::
      delete @_listProp
      @
    else
      new BitArray @_list, resMask, @_collection

  invert: ->

    tooManyArgs() unless arguments.length == 0

    if @_edit

      mask[i] = ~mask[i] for i in [0...(len = (mask = @_mask).length)] by 1

      if (r = @_list.length % 32) > 0

        mask[len - 1] &= ((1 << r) - 1)

      delete @_listProp

      @

    else

      resMask = new Array (len = (leftMask = @_mask).length)

      resMask[i] = ~v for v, i in leftMask

      if (r = @_list.length % 32) > 0

        resMask[len - 1] &= ((1 << r) - 1)

      new BitArray @_list, resMask, @_collection # invert:

  isEmpty: ->

    for v in @_mask when v != 0

      return false

    true # isEmpty:

  lock: ->

    delete @_edit

    @ # lock:

  locked: ->

    not @_edit # locked:

  fixVertical: ->

    if @_edit

      mask = @_mask

    else

      mask = new Array @_mask.length

      mask[i] = @_mask[i] for i in [0...@_mask.length]

    for item in @_list when item.hasOwnProperty('$$mask')

      itemMask = item.$$mask._mask

      noSubfields = true

      for i in [0...mask.length] by 1 when (mask[i] & itemMask[i]) != 0

        noSubfields = false

        break

      if @get item.$$index

        if noSubfields

          mask[i] |= itemMask[i] for i in [0...mask.length] by 1

      else if not noSubfields

        mask[Math.trunc item.$$index / 32] |= 1 << item.$$index % 32

    if @_edit # fixVertical:
      delete @_listProp
      @
    else
      new BitArray @_list, mask, @_collection

  clearVertical: ->

    if @_edit

      mask = @_mask

    else

      mask = new Array @_mask.length

      mask[i] = @_mask[i] for i in [0...@_mask.length]

    for item in @_list by -1 when item.hasOwnProperty('$$mask') and (mask[Math.trunc item.$$index / 32] | 1 << item.$$index % 32)

      itemMask = item.$$mask._mask

      noSubfields = true

      for i in [0...mask.length] by 1 when (mask[i] & itemMask[i]) != 0

        noSubfields = false

        break

      if noSubfields

        mask[Math.trunc item.$$index / 32] &= ~(1 << item.$$index % 32)

    if @_edit # clearVertical:
      delete @_listProp
      @
    else
      new BitArray @_list, mask, @_collection # fixVertical:

  _buildList: ->

    @_listProp = list = []

    len = (collection = @_list).length

    m = 1

    v = (mask = @_mask)[p = 0]

    for i in [0...len] by 1

      list.push collection[i] if (v & m) != 0

      if (m <<= 1) == 0

        m = 1

        v = mask[++p]

    @ # buildList:

  valueOf: ->

    res = []

    len = @_list.length

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

    @_buildList() unless @.hasOwnProperty('_listProp')

    @_listProp # get: ->

Object.defineProperty BitArray::, 'add', value: BitArray::or, enumerable: false, configurable: true

Object.defineProperty BitArray::, 'remove', value: BitArray::subtract, enumerable: false, configurable: true

# ----------------------------

module.exports = BitArray
