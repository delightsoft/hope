{err: {tooManyArgs, invalidArg, isResult}} = require '../utils'

Result = require '../result'

BitArray = require '../bitArray'

_tokenizer = (result, expression) ->

  p = -1

  s = 0 # - начало строки,
    # 1 - пробел после имени элемента, тега или закрывающей скобки
    # 10 - имя элемента,
    # 20 - начало имени тега,
    # 21 - имя тега,
    # 22 - начало имени тега после namespace,
    # 23 - имя тега после namespace,
    # 30 - запятая, плюс или минус
    # 31 - после восклицательного знака
    # 100 - end

  m = null

  nextToken = ->

    loop

      if (p + 1) == expression.length
        switch s
          when 10, 21, 23
            s = 1; return expression.substr m, p - m + 1 # push back
          when 20, 30, 31
            result.error 'dsc.invalidExpression', value: expression, position: p + 1
            s = 100
            return
        s = 100
        return null

      char = expression.charAt(++p)
      wrong = false

      switch s
        when 100
          return null
        when 0
          if /\s/i.test char then undefined
          else if /[a-z0-9]/i.test char then s = 10; m = p
          else if char == '!' then s = 31; return '!'
          else if char == '#' then s = 20; m = p
          else if char == '(' then s = 0; return '('
          else wrong = true
        when 1
          if /\s/i.test char then undefined
          else if char == ',' then s = 30; return '+'
          else if char == '+' || char == '-' || char == '&' then s = 30; return char
          else if char == ')' then s = 1; m = p; return ')'
          else wrong = true
        when 10
          if /[a-z0-9\.]/i.test char then undefined
          else p--; s = 1; return expression.substr m, p - m + 1 # push back
        when 20
          if /[a-z0-9]/.test char then s = 21
          else wrong = true
        when 21
          if /[a-z0-9]/i.test char then undefined
          else if char == '.' then s = 22
          else p--; s = 1; return expression.substr m, p - m + 1 # push back
        when 22
          if /[a-z0-9]/.test char then s = 23
          else wrong = true
        when 23
          if /[a-z0-9]/i.test char then undefined
          else p--; s = 1; return expression.substr m, p - m + 1 # push back
        when 30
          if /\s/i.test char then undefined
          else if /[a-z0-9]/i.test char then s = 10; m = p
          else if char == '#' then s = 20; m = p
          else if char == '(' then s = 0; return '('
          else if char == '!' then s = 31; return '!'
          else wrong = true
        when 31
          if /\s/i.test char then undefined
          else if /[a-z0-9]/i.test char then s = 10; m = p
          else if char == '#' then s = 20; m = p
          else if char == '(' then s = 0; return '('
          else wrong = true
        else throw new Error "Unexpected s: #{s}" # Just in case

      if wrong
        result.error 'dsc.invalidExpression', value: expression, position: p
        s = 100
        return

    return # return ->

  Object.defineProperty nextToken, 'position', get: ->  if s == 1 then m else p

  nextToken # _tokenizer =

calc = (result, collection, expression) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'collection', collection unless typeof collection == 'object' && collection != null && collection.hasOwnProperty('$$list')
  invalidArg 'expression', expression unless typeof expression == 'string'
  tooManyArgs() unless arguments.length <= 3

  nextToken = _tokenizer result, expression

  expr = []
  levels = []

  map = if (isFlat = collection.hasOwnProperty('$$flat')) then collection.$$flat else collection

  while token = nextToken()

    switch token
      when '+', '-', '&', '!'
        expr.push token
      when '('
        expr.push level = []
        levels.push expr
        expr = level
      when ')'
        unless levels.length > 0
          result.error 'dsc.unmatchParenthesis', position: nextToken.position, value: expression
        else
          expr = levels.pop()
      else
        if token.startsWith('#') # tag
          if token == '#all'
            expr.push collection.$$tags.all
          else if collection.$$tags.hasOwnProperty(tag = token.substr 1)
            expr.push collection.$$tags[tag]
          else
            result.error 'dsc.unknownTag', value: tag, position: nextToken.position
        else # field
          unless map.hasOwnProperty(token)
            result.error 'dsc.unknownItem', value: token, position: nextToken.position
          else if map[token].hasOwnProperty('$$mask')
            expr.push map[token].$$mask
          else
            fieldMask = new BitArray collection
            fieldMask.set map[token].$$index
            expr.push fieldMask

  return if result.isError

  if levels.length > 0
    result.error 'dsc.unmatchParenthesis', position: expression.length, value: expression
    return

  _calcExpr = (expr) ->

    for v, i in expr when Array.isArray(v)
     expr[i] = _calcExpr v

    for v, i in expr by -1 when v == '!'
      expr[i + 1] = expr[i + 1].invert()
      expr.splice i, 1

    p = 1
    while p < expr.length

      if (v = expr[p]) == '+'
        expr[p - 1] = expr[p - 1].or expr[p + 1]
        expr.splice p, 2

      else if v == '-'
        expr[p - 1] = expr[p - 1].subtract expr[p + 1]
        expr.splice p, 2

      else
        p += 2

    p = expr.length - 2
    while p > 0

      if expr[p] == '&'
        expr[p - 1] = expr[p - 1].and expr[p + 1]

      p -= 2

    return expr[0]

  res = _calcExpr expr

  # res.clearVertical() if isFlat

  res # calc =

# ----------------------------

module.exports = calc

module.exports._tokenizer = _tokenizer # for spec purposes
