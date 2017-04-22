{err: {invalidArg, notEnoughArgs, tooManyArgs}} = require '../utils'

_add = (name, path) ->

  notEnoughArgs() unless arguments.length > 0
  invalidArg 'path', path unless typeof path == 'string'
  tooManyArgs() unless arguments.length <= 2

  path += '.' if path.length > 0

  path += name

  path # _add =

prop = (name, pathFunc) ->

  notEnoughArgs() unless arguments.length > 0
  invalidArg 'name', name unless typeof name == 'string' && name.length > 0
  tooManyArgs() unless arguments.length <= 2

  if arguments.length == 1

    return (path) -> _add name, path

  if typeof pathFunc == 'function'

    return (path) -> _add name, pathFunc path

  invalidArg 'pathFunc', pathFunc

  return # prop =

# ----------------------------

module.exports = prop