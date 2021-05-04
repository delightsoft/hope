Result = require '../result'

sortedMap = require '../sortedMap'

processFields = require './_processFields'

processUdtypeFields = (result, config) ->

  return if result.isError

  stack = []

  order = []

  _buildOrder = (udType, level = 0) =>

    return unless typeof (fields = udType.fields) == 'object' and fields != null

    if ~stack.indexOf(udType.name)

      result.error 'dsc.cycledUdtypes', value: Object.assign [], stack

      return

    stack.push udType.name

    _processFields = (fields) ->

      return unless typeof fields == 'object' and fields != null

      itemName = undefined

      result.context ((path) -> (Result.prop itemName) ((Result.prop 'fields') path)), ->

        if Array.isArray(fields)

          for item in fields when typeof (itemName = item.name) == 'string'

            if typeof item.type == 'string' and (udt = config.udtypes[item.type])

              _buildOrder udt, level + 1

            else if item.fields

              _processFields item.fields

        else

          for itemName, item of fields

            if typeof item.type == 'string' and (udt = config.udtypes[item.type])

              _buildOrder udt, level + 1

            else if item.fields

              _processFields item.fields

        return

      return

    _processFields fields

    unless ~order.indexOf(udType) # чтоб не пропустить зацикленность обрабаываем повторно udType даже когда он уже в order

        order.push udType # udType с fields используемые в этом типе должны идти раньше

    stack.pop()

  udType = undefined

  result.context ((path) -> (Result.prop udType.name) ((Result.prop 'udtypes') path)), ->

    for udType in config.udtypes.$$list when udType.fields

      _buildOrder udType unless ~order.indexOf(udType)

  unless result.isError

    udType = undefined

    result.context (Result.prop 'udtypes'), ->

      result.context ((path) -> (Result.prop udType.name) path), ->

        for udType in order

          result.isError = false

          udType.fields = processFields result, {$$src: udType}, config, 'fields', true, true

  unless result.isError

    sortedMap.finish result, config.udtypes

  return

# ----------------------------

module.exports = processUdtypeFields
