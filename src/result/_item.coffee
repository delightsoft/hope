{err: {invalidArg, notEnoughArgs, tooManyArgs}} = require '../utils'

_add = (name, path) ->

  notEnoughArgs() unless arguments.length > 0
  invalidArg 'path', name unless typeof path == 'string'
  tooManyArgs() unless arguments.length <= 2

  path += "[#{name}]"

  path # _add =

item = (name, pathFunc) ->

  notEnoughArgs() unless arguments.length > 0
  invalidArg 'name', name unless typeof name == 'string' && name.length > 0
  tooManyArgs() unless arguments.length <= 2

  if arguments.length == 1

    return (path) -> _add name, path

  if typeof pathFunc == 'function'

    return (path) -> _add name, pathFunc path

  invalidArg 'pathFunc', pathFunc

  return # item =

# ----------------------------

module.exports = item