Result = require '../result'

copyOptions = (result, map) ->

  item = undefined

  result.context ((path) -> (Result.prop 'options', (Result.item item.name)) path), ->

    for item in map.$$list when item.$$src.hasOwnProperty 'options'

      value = item.$$src.options

      unless typeof value == 'object' && value != null && !Array.isArray value

        result.error 'dsc.invalidValue', value: value

      else

        item.options = value

#---------------------------

module.exports = copyOptions
