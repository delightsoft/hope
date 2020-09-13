Result = require '../../result'

calc = require '../../tags/_calc'

$$calcBuilder = (collection) ->

  cache = Object.create(null)

  buildCalc = (useCache) ->

    (result) ->

      unless typeof result == 'object' && result != null && result.hasOwnProperty('isError')
        s = 0
        options = expr
        expr = result
        localResult = true
        result = new Result()
      else
        s = 1

      options = arguments[arguments.length - 1]
      if typeof options == 'object'
        if arguments.length == (1 + s)
          return collection.$$tags.none
        else if arguments.length == (2 + s)
          expr = arguments[s]
          invalidArg 'expr', exprArray unless typeof expr == 'string'
        else
          exprArray = Array::slice.call arguments, s, arguments.length - 1
          invalidArg 'expr', exprArray unless exprArray.every v -> typeof v == 'string'
          expr = exprArray.join(',')
        invalidArg 'options', options unless options != null and not Array.isArray(options)
      else
        options = undefined
        if arguments.length == s
          return collection.$$tags.none
        else if arguments.length == (1 + s)
          expr = arguments[s]
          invalidArg 'expr', exprArray unless typeof expr == 'string'
        else
          exprArray = Array::slice.call arguments, s
          invalidArg 'expr', exprArray unless exprArray.every v -> typeof v == 'string'
          expr = exprArray.join(',')

      if useCache

        return cache[expr] if hasOwnProperty.call cache, expr

        r = cache[expr] = calc result, collection, expr, options

        r.lock()

      else

        r = calc result, collection, expr, options

      result.throwIfError() if localResult

      r # (useCache) ->

  $$calc = buildCalc true

  $$calc.noCache = buildCalc false

  $$calc # (fields) ->

# ----------------------------

module.exports = $$calcBuilder

