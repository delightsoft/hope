Result = require '../../result'

calc = require '../../tags/_calc'

$$calcBuilder = (fields) ->

  cache = Object.create(null)

  noCache = (result, expr, options) ->

    unless typeof result == 'object' && result != null && result.hasOwnProperty('isError')

      options = expr

      expr = result

      localResult = true

      result = new Result()

    r = calc result, fields, expr, options

    result.throwIfError() if localResult

    r # noCache =

  $$calc = (result, expr, options) ->

    cacheExpr = if typeof result == 'object' && result != null && result.hasOwnProperty('isError') then expr else result

    return cache[expr] if hasOwnProperty.call cache, cacheExpr

    cache[expr] = noCache result, expr, options # res.$$calc =

  $$calc.noCache = noCache

  $$calc # (fields) ->

# ----------------------------

module.exports = $$calcBuilder

