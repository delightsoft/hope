Result = require './result'

{combineMsg, flatTree, err: {tooManyArgs, invalidArg, checkResult}} = require './utils'

# ----------------------------

formatNoI18n = (message) ->

  res = """
    #{message.code}#{JSON.stringify message, (name, val) ->
      if Result._reservedAttrs.indexOf(name) >= 0 then undefined else val}
  """

  if res.endsWith '{}' # no attributes, beside reservedAttrs list

    return res.substr 0, res.length - 2 # formatNoI18n =

  res # formatNoI18n =

# ----------------------------

formatPart = (i18nPart, message) ->

  if typeof (template = i18nPart[message.code]) == 'function'

    template message # formatPart =

  else if typeof template != 'undefined'

    "#{template}" # formatPart =

  else

    formatNoI18n message # formatPart =

# ----------------------------

format = (i18n, message) ->

  invalidArg 'i18n', i18n unless typeof i18n == 'undefined' || typeof i18n == 'object'
  invalidArg 'message', message unless typeof message == 'object' && message != null && message.hasOwnProperty('code')
  tooManyArgs() unless arguments.length <= 2

  res = []

  if message.hasOwnProperty('path')

    res.push "#{message.path}: "

  if i18n

    res.push formatPart i18n, message

  else # no i18n

    res.push formatNoI18n message

  res.join '' # format =

# ----------------------------

link = (result, i18n) ->

  checkResult result
  invalidArg 'i18n', config unless typeof i18n == 'object' && i18n != null
  tooManyArgs() unless arguments.length <= 2

  flatTree i18n # link =

# ----------------------------

module.exports =

  link: link

  format: format