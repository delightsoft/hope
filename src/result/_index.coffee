{err: {invalidArg, notEnoughArgs, tooManyArgs}} = require '../utils'

_add = (index, path) ->

  notEnoughArgs() unless arguments.length > 0
  invalidArg 'path', name unless typeof path == 'string'
  tooManyArgs() unless arguments.length <= 2

  path += "[#{index}]"

  path # _add =

index = (index, pathFunc) ->

  notEnoughArgs() unless arguments.length > 0
  invalidArg 'index', index unless typeof index == 'number'
  tooManyArgs() unless arguments.length <= 2

  if arguments.length == 1

    return (path) -> _add index, path

  if typeof pathFunc == 'function'

    return (path) -> _add index, pathFunc path

  invalidArg 'pathFunc', pathFunc

  return # index =

# ----------------------------

module.exports = index