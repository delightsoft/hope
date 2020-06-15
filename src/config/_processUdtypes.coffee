Result = require '../result'

{checkUDTypeName} = require '../utils'

sortedMap = require '../sortedMap'

copyExtra = require './_copyExtra'

{compile: compileType,
compile: {_builtInTypes: builtInTypes, _reservedTypes: reservedTypes, _typeProps: typeProps, _extraProps: extraProps}} = require '../types'

processUdtypes = (result, config) ->

  unless config.$$src.hasOwnProperty('udtypes')

    config.udtypes = {$$list: []}

    return

  result.context (Result.prop 'udtypes'), -> # processUdtypes =

    res = sortedMap result, config.$$src.udtypes, checkName: checkUDTypeName

    return if result.isError

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

        parent = res[udt.udType]

        if not parent.hasOwnProperty('type')

          processUdtype parent, (if stack then (stack.push udt.name; stack) else [udt.name])

        if parent.hasOwnProperty('type') # processed successfully

          udt.type = parent.type

          udt.udType = parent.name

          for prop in typeProps when parent.hasOwnProperty(prop) # derive type props

            udt[prop] = parent[prop]

          for prop in extraProps when parent.hasOwnProperty(prop) # derive type props

            udt[prop] = parent[prop]

    processUdtype udt for udt in res.$$list

    unless result.isError

      copyExtra result, res

      sortedMap.finish result, res

      config.udtypes = if result.isError then 'failed' else res

      return # processUdtypes = (result, config) ->

# ----------------------------

module.exports = processUdtypes
