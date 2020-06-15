Result = require '../result'

copyExtra = (result, map) ->

  item = undefined

  result.context ((path) -> (Result.prop 'extra', (Result.prop item.name)) path), ->

    for item in map.$$list when item.$$src?.hasOwnProperty 'extra'

      value = item.$$src.extra

      unless typeof value == 'object' && value != null && !Array.isArray value

        result.error 'dsc.invalidValue', value: value

      else

        item.extra = value

#---------------------------

module.exports = copyExtra
