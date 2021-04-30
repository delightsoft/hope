Result = require '../result'

sortedMap = require '../sortedMap'

processFields = require './_processFields'

processUdtypeFields = (result, config) ->

  return if result.isError

  stack = []

  order = []

  _buildOrder = (udType, level = 0) =>

    if ~stack.indexOf(udType)

      result.error 'dsc.cycledUdtypeDefinition', type: udType

      return

    stack.push udType.name

    result.context (Result.prop if level == 0 then 'udtypes' else 'fields'), ->

      item = undefined

      result.context ((path) -> (Result.prop item.name) path), ->

        _buildOrder item, level + 1 for item in udType.fields when item.hasOwnProperty('fields')

    order.push udType # udtype с fields используемые в этом типе должны идти раньше

    stack.pop()

  for udType in config.udtypes.$$list when udType.hasOwnProperty('fields')

    _buildOrder udType if not ~order.indexOf(udType.name)

  udType = undefined

  result.context (Result.prop 'udtypes'), ->

    result.context ((path) -> (Result.prop udType.name) path), ->

      for udType in order

        result.isError = false

        udType.fields = processFields result, {$$src: udType}, config, 'fields', true

        unless result.isError

          delete udType.fields.$$flat # это не самостоятельная структура.  она будет вставляться в иерархию полей

          delete udType.fields.$$tags

          _clearIndex = (list) =>

            for item in list

              delete item.$$index

              delete item.$$mask

              _clearIndex item.fields.$$list if item.fields

          _clearIndex udType.fields.$$list

  unless result.isError

    sortedMap.finish result, config.udtypes

  return

# ----------------------------

module.exports = processUdtypeFields
