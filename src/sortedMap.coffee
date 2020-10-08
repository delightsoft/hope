Result = require './result'

{checkItemName, err: {invalidArg, isResult}} = require './utils'

finish = (result, resValue, opts) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'resValue', resValue unless typeof resValue == 'object' && resValue != null && resValue.hasOwnProperty('$$list')
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))

  unless opts?.hasOwnProperty('skipProps') # list of prop that should not be reported in validation
    optsSkipProps = undefined
  else
    unless (optsSkipProps = opts.skipProps) == undefined || optsSkipProps == null || Array.isArray(optsSkipProps)
      invalidArg 'opts.skipProps', opts.skipProps

  unless opts?.hasOwnProperty('validate') # false - exclude validation for extra props
    optsValidate = true
  else
    invalidArg 'opts.validate', opts.validate unless typeof (optsValidate = opts.validate) == 'boolean'

  optsValidate = false if result.isError # just remove $$src in case of prev error

  if optsValidate

    item = undefined

    result.context ((path) -> (Result.prop item.name) path), ->

      for item in resValue.$$list

        if optsValidate && item.hasOwnProperty('$$src')

          k = undefined

          result.context ((path) -> (Result.prop k) path), ->

            for k of item.$$src when not (item.hasOwnProperty(k) || k.startsWith('$') || optsSkipProps?.indexOf(k) >= 0)

              result.error 'dsc.unexpectedProp', value: item.$$src[k]

            return

        delete item.$$src

      return # result.context

  else

    delete item.$$src for item in resValue.$$list

  return # finish =

sortedMap = (result, value, opts) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))

  unless opts?.hasOwnProperty('checkName') # function that checks names of items. Default: 'checkItemName' is used
    optsCheckName = null
  else
    invalidArg 'opts.checkName', opts.checkName unless typeof (optsCheckName = opts.checkName) == 'function'

  unless opts?.hasOwnProperty('getValue') # function that creates new item out of non-object value
    optsGetValue = null
  else
    invalidArg 'opts.getValue', opts.getValue unless typeof (optsGetValue = opts.getValue) == 'function'

  unless opts?.hasOwnProperty('string') # true - val could be list of strings or a comma delimited string
    optsString = false
  else
    invalidArg 'opts.string', opts.string unless typeof (optsString = opts.string) == 'boolean'

  unless opts?.hasOwnProperty('boolean') # true - map, can express presents of an item, by using true as a value
    optsBoolean = false
  else
    invalidArg 'opts.boolean', opts.boolean unless typeof (optsBoolean = opts.boolean) == 'boolean'

  unless opts?.hasOwnProperty('index') # true - add to every result item $$index, with the index of item within result $$list
    optsIndex = false
  else
    invalidArg 'opts.index', opts.index unless typeof (optsIndex = opts.index) == 'boolean'

  unless opts?.hasOwnProperty('before')
    optsBefore = []
  else
    invalidArg 'opts.before', opts.before unless Array.isArray(optsBefore = opts.before)

  unless opts?.hasOwnProperty('after')
    optsAfter = []
  else
    invalidArg 'opts.after', opts.after unless Array.isArray(optsAfter = opts.after)

  unless opts?.hasOwnProperty('reservedNames')
    optsReservedNames = undefined
  else
    invalidArg 'opts.reservedNames', opts.reservedNames unless Array.isArray(optsReservedNames = opts.reservedNames)

  res = {}

  list = []

  for item in optsBefore

    newItem = {name: item.name, $$src: item}

    newItem.$$index = list.length if optsIndex

    res[item.name] = newItem

    list.push newItem

  if optsString && typeof value == 'string' && value.length > 0 # на вход дали строку

    items = (v.trim() for v in value.split(',') when v.trim())

    if items.length == 0

      result.error 'dsc.invalidValue', value: value

    else

      for v,  i in items

        unless (if optsCheckName then fixedName = optsCheckName v else checkItemName v)

          result.error 'dsc.invalidName', value: v

          continue

        v = fixedName if typeof fixedName == 'string'

        if optsReservedNames and optsReservedNames.indexOf(v) != -1

          result.error 'dsc.reservedName', value: v

          continue

        if res.hasOwnProperty v

          result.error (Result.index i), 'dsc.duplicatedName', value: v

          continue

        clone.$$index = list.length if optsIndex

        list.push (res[v] = {name: v})

  else if typeof value == 'object' && value != null # на вход дали map или массив

    if Array.isArray value

      i = undefined

      result.context ((path) -> (Result.index i) path), ->

        for v, i in value

          if optsString && typeof v == 'string' && v.length > 0

            unless (if optsCheckName then (fixedName = optsCheckName v) else checkItemName v)

              result.error 'dsc.invalidName', value: v

              continue

            v.name = fixedName if typeof fixedName == 'string'

            if optsReservedNames and optsReservedNames.indexOf(v.name) != -1

              result.error 'dsc.reservedName', value: v.name

              continue

            res[v] = clone = {name: v}

          else

            unless typeof v == 'object' && v != null && !Array.isArray(v)

              result.error 'dsc.invalidValue', value: v

              continue

            else unless v.hasOwnProperty('name')

              result.error 'dsc.missingProp', value: 'name'

              continue

            unless (if optsCheckName then (fixedName = optsCheckName v.name) else checkItemName v.name)

              result.error 'dsc.invalidName', value: v.name

              continue

            v.name = fixedName if typeof fixedName == 'string'

            if optsReservedNames and optsReservedNames.indexOf(v.name) != -1

              result.error 'dsc.reservedName', value: v.name

            unless not res.hasOwnProperty v.name

              result.error 'dsc.duplicatedName', value: v.name

              continue

            res[v.name] = clone = {name: v.name, $$src: v}

          clone.$$index = list.length if optsIndex

          list.push clone

        return # result.context

    else # if Array.isArray value

      if value.hasOwnProperty('$$list')

        throw new Error 'Value was already processed by sortedMap()'

      k = undefined

      result.context ((path) -> (Result.prop k) path), ->

        for k, v of value

          unless (if optsCheckName then fixedName = optsCheckName k else checkItemName k)

            result.error 'dsc.invalidName', value: k

            continue

          k = fixedName if typeof fixedName == 'string'

          if optsReservedNames and optsReservedNames.indexOf(k) != -1

            result.error 'dsc.reservedName', value: k

            continue

          res[k] = clone = {name: k}

          if typeof v == 'object' && v != null && !Array.isArray(v)

            unless not v.hasOwnProperty('name') || k == v.name

              result.error 'dsc.keyAndNameHasDifferenValues', value1: k, value2: v.name

              continue

            else

              clone.$$src = v

          else if optsGetValue && optsGetValue(result, v, clone)

            undefined

          else if optsBoolean && typeof v == 'boolean' && v == true

            res[k] = clone = {name: k}

          else

            result.error 'dsc.invalidValue', value: v

            continue

          clone.$$index = list.length if optsIndex

          list.push clone

        return # result.context

  else # if typeof value == 'object' && object != null

    result.error 'dsc.invalidValue', value: value

  unless result.isError

    for item in optsAfter

      newItem = {name: item.name, $$src: item}

      newItem.$$index = list.length if optsIndex

      res[item.name] = newItem

      list.push newItem

    res.$$list = list

    res # sortedMap =

# ----------------------------

module.exports = sortedMap

sortedMap.finish = finish

sortedMap.empty =

  $$list: []
