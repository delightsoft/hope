Result = require '../result'

processFields = require './_processFields'

processUdtypeFields = (result, config) ->

  console.info 5, config.udtypes == 'failed'

  return if config.udtypes == 'failed'

  stack = []

  order = []

  _buildOrder = (udType, level = 0) =>

    if ~stack.indexOf(udType)

      result.error 'dsc.cycledUdtypeDefinition', type: udType

      return

    stack.push udType.name

    result.context (Result.prop if level == 0 then 'udtypes' else 'fields'), ->

      result.context ((path) -> (Result.prop udType.name) path), ->

        _processLevel item, level + 1 for item in udType.fields when item.hasOwnProperty('fields')

    order.push udType # udtype с fields используемые в этом типе должны идти раньше

    stack.pop()

  for udType in config.udtypes.$$list when udType.hasOwnProperty('fields')

    _buildOrder udType if not ~order.indexOf(udType.name)

  console.info 35, order

  udType = undefined

  result.context (Result.prop 'udtypes'), ->

    result.context ((path) -> (Result.prop udType.name) path), ->

      for udType in order

        processFields result, udType, config, 'fields', true

        delete fields.$$flat # это не самостатоятельная структура.  она будет вставляться в иерархию полей

        delete fields.$$tags

  return

# ----------------------------

module.exports = processUdtypeFields
