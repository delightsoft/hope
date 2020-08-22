Result = require '../../result'

cloneDeep = require 'lodash/cloneDeep'

{invalidArg, unknownOption} = require '../../utils/_err'

$$editValidatorBuilder = (type, fieldsProp, access, docLevelValidate) ->

  typeDesc = if type.$$access == access then type else type[fieldsProp]

  (fields, options) ->

    beforeSave = false

    beforeAction = false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'beforeSave' then beforeSave = !!optValue

          when 'beforeAction' then beforeAction = !!optValue

          else unknownOption optName

    validate = type["_#{fieldsProp}Validate"]

    messages = {}

    r = access.call typeDesc, fields

    save = true

    goodForAction = beforeAction

    localResult = new Result

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply localResult, arguments

      if msg.type == 'error'

        goodForAction = false

        save = false if msg.code == 'validate.invalidValue'

      return # localResult.error = () ->

    validate localResult, fields, undefined, fields, r.update, r.required, (if beforeSave or beforeAction then undefined else fields.$$touched), false, beforeAction

    unless localResult.isError

      docLevelValidate?.call type, localResult, fields

    localResult.messages.forEach (msg) ->
      if (path = msg.path) then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
      else (messages[''] or (messages[''] = [])).push msg
      return

    {save, goodForAction, messages} # (fields) ->  # ->

# ----------------------------

module.exports = $$editValidatorBuilder

