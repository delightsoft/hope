i18n = require './i18n'

{err: {tooManyArgs, invalidArg, isResult}} = require './utils'

Result = require './Result'

class Reporter

  # i18n - не обязательный параметр.

  # TODO: Implement context() with only one argument, without Result

  constructor: (@i18n) ->

    throw new Error "Invalid argument 'i18n'" unless typeof @i18n == 'undefined' || (typeof @i18n == 'object' && @i18n != null)

    @isError = @_err = false

    @pathFunc = -> ''

    @messages = 0

    @errors = 0

    @warnings = 0

    return

  log: (typeOrMsg, pathFunc, code, args) ->

    if typeof typeOrMsg == 'object' && typeOrMsg != null

      invalidArg 'typeOrMsg', typeOrMsg unless typeOrMsg.hasOwnProperty('code')

      msg = typeOrMsg

    else

      unless typeof pathFunc == 'function'

        [args, code, pathFunc] = [code, pathFunc, null]

      path = @pathFunc path

      path = pathFunc path if pathFunc

      msg = Result._combineMsg typeOrMsg, path, code, args

    switch msg.type

      when 'error'

        @errors++

        @isError = @_err = true

      when 'warn' then @warnings++

    @_print (if msg.type then msg.type else 'info'), i18n.format @i18n, msg

    msg # log: (arg1, arg2, arg3) ->

  error: Result::error

  warn: Result::warn

  info: Result::info

  # Выводит содержимое result.  Если указан msgCode - то в начале пишется общее название операции.  При этом type
  # выбирается как наихудщий из типов сообщений в result

  logResult: (result, pathFunc, msgCode, args) ->

    invalidArg 'result', result unless isResult result
    tooManyArgs() unless arguments.length <= 4

    if pathFunc

      unless typeof pathFunc == 'function'

        [args, msgCode, pathFunc] = [msgCode, pathFunc, null]

      invalidArg 'msgCode', msgCode unless (typeof msgCode == 'undefined') || (typeof msgCode == 'string' && msgCode.length > 0)
      invalidArg 'args', args unless (typeof args == 'undefined') || (msgCode && typeof args == 'object' && args != null)

      type = 'info'

      for msg in result.messages

        switch msg.type

          when 'error' then type = 'error'

          when 'warn' then if type == 'info' then type = 'warn'

      path = if pathFunc then pathFunc '' else ''

      @_print type, i18n.format @i18n, Result._combineMsg type, path, msgCode, args

    for msg in result.messages by 1

      @_print (if msg.type then msg.type else 'info'), i18n.format @i18n, msg

    @ # log:

  context: Result::context

# ----------------------------

module.exports = Reporter
