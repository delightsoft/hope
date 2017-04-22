Result = require './result'

_compactValue = (v) ->

  if typeof v == 'object'

    if v == null then 'null' else if Array.isArray(v) then '[Array]' else if v.hasOwnProperty('name') then "[Item(#{v.name})]" else '[Object]'

  else

    v # _compactValue =

_compareMap = (result, path, actual, expected) ->

  unless path.indexOf(actual) >= 0

    path.push actual

    k = undefined

    result.context ((path) -> ((if expected.hasOwnProperty('$$list') && not k.startsWith('$') then Result.item else Result.prop) k) path), ->

      for k in Object.keys(expected)

        v = expected[k]

        unless actual.hasOwnProperty k

          result.info 'missing', value: _compactValue v

        else

          _compareValue result, path, actual[k], v

      for k in Object.keys(actual) when not expected.hasOwnProperty k

        result.info 'extra', value: _compactValue actual[k]

    path.pop()

  return # _compareMap =

_compareList = (result, path, actual, expected) ->

  unless path.indexOf(actual) >= 0

    path.push actual

    i = undefined

    result.context ((path) -> (Result.index i) path), ->

      for v, i in expected

        if i < actual.length

          _compareValue result, path, actual[i], v

        else

          result.info 'missing', value: _compactValue v

      for v, i in actual[expected.length...actual.length]

        result.info 'extra', value: _compactValue v

    path.pop()

  return # _compareList =

_compareValue = (result, path, actual, expected) ->

  if (atype = typeof actual) == 'object'

    atype = if actual == null then 'null' else if Array.isArray(actual) then 'array' else 'object'

  if (etype = typeof expected) == 'object'

    etype = if expected == null then 'null' else if Array.isArray(expected) then 'array' else 'object'

  unless atype == etype

    result.info 'diffType', actual: atype, expected: etype

  else

    switch atype

      when 'object'

        _compareMap result, path, actual, expected

      when 'array'

        _compareList result, path, actual, expected

      else

        if actual != expected

          result.info 'diffValue', actual: _compactValue(actual), expected: _compactValue expected

  return # _compareValue =

compareStructures = (result, actual, expected) ->

  _compareValue result, [], actual, expected

  return # compareStructures =

# ----------------------------

module.exports = compareStructures