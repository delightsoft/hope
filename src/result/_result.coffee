{err: {invalidArg, invalidArgValue, tooManyArgs, reservedPropName, isResult}} = require '../utils'

# ----------------------------

reservedAttrs = ['type', 'path', 'code', 'text']

_combineMsg = (type, path, code, args) ->

  invalidArg 'type', type unless (typeof type == 'undefined') || (typeof type == 'string' && type.length > 0)
  if type
    invalidArgValue 'type', type unless type == 'error' || type == 'warn' || type == 'info'
  invalidArg 'path', path unless !path || typeof path == 'string'
  invalidArg 'code', code unless typeof code == 'string' && code.length > 0
  invalidArg 'args', args unless (typeof args == 'undefined') || (typeof args == 'object' && args != null)
  if args
    for arg in reservedAttrs when args.hasOwnProperty(arg)
      reservedPropName "args.#{arg}", args

  msg = {}
  msg.type = type if type && type != 'info'
  msg.path = path if path
  msg.code = code
  if args
    msg[k] = v for k, v of args

  msg # _combineMsg =

class Result

  constructor: (pathFuncOrResult) ->

    tooManyArgs() unless arguments.length <= 1

    if arguments.length == 0 || pathFuncOrResult == null

      @pathFunc = -> ''

    else

      if isResult pathFuncOrResult

        @parent = pathFuncOrResult

        @pathFunc = pathFuncOrResult.pathFunc || -> ''

      else if typeof pathFuncOrResult == 'function' && pathFuncOrResult != Result # with special protection from the case when instead of 'new Result', is written just 'Result'

        @pathFunc = pathFuncOrResult

      else

        invalidArg 'pathFuncOrResult', pathFuncOrResult

    @messages = []

    @isError = @_err = false

    return # constructor:

  log: (typeOrMsg, pathFunc, code, args) ->

    if typeof typeOrMsg == 'object' && typeOrMsg != null

      invalidArg 'typeOrMsg', typeOrMsg unless typeOrMsg.hasOwnProperty('code')

      msg = typeOrMsg

    else

      unless typeof pathFunc == 'function'

        [args, code, pathFunc] = [code, pathFunc, null]

      path = @pathFunc ''

      path = pathFunc path if pathFunc

      msg = _combineMsg typeOrMsg, path, code, args

    @messages.push msg

    @isError = @_err = true if msg.type == 'error'

    msg # log =

  error: (pathFunc, code, args) ->

    @log 'error', pathFunc, code, args # error: (code, args) ->

  warn: (pathFunc, code, args) ->

    @log 'warn', pathFunc, code, args # warn: (code, args) ->

  info: (pathFunc, code, args) ->

    @log 'info', pathFunc, code, args # info: (code, args) ->

  add: (result) ->

    invalidArg 'result', result unless isResult result

    if result.messages.length > 0

      Array::push.apply @messages, result.messages

      @isError = @isError || result.isError

      result.reset()

    @ # add:

  reset: ->

    @isError = false

    @messages.length = 0

    return # reset:

  context: (pathFunc, body) ->

    tooManyArgs() unless arguments.length <= 2

    [body, pathFunc] = [pathFunc, @pathFunc] if arguments.length == 1

    invalidArg 'pathFunc', pathFunc unless typeof pathFunc == 'function'
    invalidArg 'body', body unless typeof body == 'function'

    do (oldIsError = @isError, oldErr = @_err, oldPathFunc = @pathFunc) => # context:

      @isError = @_err = false

      @pathFunc = (path) -> pathFunc oldPathFunc path

      res = body()

      @isError = @_err || oldIsError

      @_err = @_err || oldErr

      @pathFunc = oldPathFunc

      return res

  throwIfError: ->

    if @isError

      err = new Error JSON.stringify @messages

      err.code = 'dsc.result'

      @reset() # so global Result object could be reused in specs

      throw err # throwIfError:

    else

      @reset()

    return # throwIfError: ->

# ----------------------------

module.exports = Result

module.exports._combineMsg = _combineMsg

module.exports._reservedAttrs = reservedAttrs
