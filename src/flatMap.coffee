Result = require './result'

sortedMap = require './sortedMap'

BitArray = require './bitArray'

{deepClone, err: {invalidArg, isResult}} = require './utils'

index = (result, resValue, subitemsField, opts) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'resValue', resValue unless typeof resValue == 'object' && resValue != null
  invalidArg 'subitemsField', subitemsField unless typeof subitemsField == 'string' && subitemsField.length > 0
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))

  if opts

    opts = deepClone opts

    opts.index = false # turn indexing off for sortedMap()

  unless opts?.hasOwnProperty('mask') # true - val could be list of masks or a comma delimited mask

    optsMask = false

  else

    invalidArg 'opts.mask', opts.mask unless typeof (optsMask = opts.mask) == 'boolean'

  index = 0

  name = []

  resList = []

  resMap = {}

  _indexLevel = (level) ->

    for item in level.$$list

      resList.push item

      name.push item.name

      resMap[if name.length > 1 then (item.fullname = name.join '.') else item.name] = item

      item.$$index = index++

      _indexLevel item[subitemsField] if item[subitemsField]

      name.pop()

  _indexLevel resValue

  (resValue.$$flat = resMap).$$list = resList

  if optsMask

    masks = []

    buildMask = (list) ->

      for item in list

        v.set item.$$index for v in masks

        if item.hasOwnProperty(subitemsField)

          masks.push (item.$$mask = new BitArray resValue)

          buildMask item[subitemsField].$$list

          (masks.pop()).lock()

      return # buildMask =

    buildMask resValue.$$list

  return # index =

finish = (result, resValue, subitemsField, opts) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'resValue', resValue unless typeof resValue == 'object' && resValue != null && resValue.hasOwnProperty('$$flat')
  invalidArg 'subitemsField', subitemsField unless typeof subitemsField == 'string' && subitemsField.length > 0
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))

  _processSublevel = (level) ->

    item = undefined

    result.context ((path) -> (Result.prop item.name) path), -> # _processSublevel =

      for item in level.$$list

        if item.hasOwnProperty(subitemsField)

          result.context (Result.prop subitemsField), ->

            value = item[subitemsField]

            unless (typeof value == 'object' && value != null) || typeof value == 'string'

              result.error 'dsc.invalidValue', value: value

            else

              _processSublevel value

              sortedMap.finish result, value, opts

            return # result.context

      return # result.context

    return # _processLevel

  _processSublevel resValue

  sortedMap.finish result, resValue, opts

  return # finish =

flatMap = (result, value, subitemsField, opts) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'subitemsField', subitemsField unless typeof subitemsField == 'string' && subitemsField.length > 0
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))

  _processLevel = (parentItem) ->

    for item in parentItem.$$list

      if item.$$src?.hasOwnProperty(subitemsField)

        result.context (Result.prop item.name, Result.prop(subitemsField)), ->

          item[subitemsField] = resLevel = sortedMap result, item.$$src[subitemsField], opts

          _processLevel resLevel unless result.isError # result.context

          return # result.context

    return # _processLevel =

  result.context -> # flatMask

    res = sortedMap result, value, opts

    if opts and (opts.hasOwnProperty('before') or opts.hasOwnProperty('after'))

      opts = deepClone opts

      delete opts.before

      delete opts.after

    unless result.isError

      _processLevel res

      unless result.isError

        res # result.context

# ----------------------------

module.exports = flatMap

flatMap.index = index

flatMap.finish = finish

flatMap.empty =

  $$list: []

  $$flat:

    $$list: []
