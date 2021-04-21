Result = require '../result'

{checkUDTypeName} = require '../utils'

sortedMap = require '../sortedMap'

copyExtra = require './_copyExtra'

{compile: compileType,
compile: {_builtInTypes: builtInTypes, _reservedTypes: reservedTypes, _typeProps: typeProps, _extraProps: extraProps}} = require '../types'

processUdtypes = (result, config) ->

  unless config.$$src.udtypes

    config.udtypes = {$$list: []}

    return

  result.context (Result.prop 'udtypes'), -> # processUdtypes =

    res = sortedMap result, config.$$src.udtypes, checkName: checkUDTypeName

    return if result.isError

    item.fields = item.$$src.fields for item in res.$$list when item.$$src.fields

    copyExtra result, res

    udType = undefined

    result.context ((path) -> (Result.prop udType.name) path), ->

      for t in builtInTypes when res.hasOwnProperty(t)

        udType = res[t]

        result.error 'dsc.builtInTypeName'

      for t in reservedTypes when res.hasOwnProperty(t)

        udType = res[t]

        result.error 'dsc.reservedTypeName'

      unless result.isError

        for udType in res.$$list

          compileType result, udType.$$src, udType, context: 'udtype'

    return if result.isError

    cycledTypes = []

    processUdtype = (udt, stack) -> # recurrent types processing

      if stack && stack.indexOf(udt.name) >= 0
        unless cycledTypes.hasOwnProperty(udt.name)
          result.error 'dsc.cycledUdtypes', value: stack
          cycledTypes[t] = true for t in stack
        return

      unless udt.hasOwnProperty 'type'

        unless res.hasOwnProperty(udt.udType)
          result.error code: 'dsc.unknownType', value: udt.udType
          return

        parent = res[udt.udType]

        if not parent.hasOwnProperty('type')

          processUdtype parent, (if stack then (stack.push udt.name; stack) else [udt.name])

        if parent.hasOwnProperty('type') # processed successfully

          src = Object.assign {}, parent

          delete src.udType

          for prop in typeProps when udt.$$src.hasOwnProperty(prop) # derive type props

            src[prop] = udt.$$src[prop]

          for prop in extraProps when udt.$$src.hasOwnProperty(prop) # derive type props

            src[prop] = udt.$$src[prop]

          delete udt[prop] for prop of udt when not ~['name', 'extra'].indexOf(prop)

          compileType result, src, udt, context: 'udtype' # перекомпилируем, на случай если переопределены свойства базового типа

          udt.udType = parent.name

          if parent.hasOwnProperty('extra')

            if udt.hasOwnProperty('extra')

              udt.extra = Object.assign {}, parent.extra, udt.extra

            else

              udt.extra = parent.extra

    processUdtype udt for udt in res.$$list

    unless result.isError

      copyExtra result, res

      config.udtypes = if result.isError then 'failed' else res

      return # processUdtypes = (result, config) ->

# ----------------------------

module.exports = processUdtypes
