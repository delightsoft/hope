Result = require '../../result'

cloneDeep = require 'lodash/cloneDeep'

{invalidArg, unknownOption} = require '../../utils/_err'

$$editValidatorBuilderBuilder = (type, fieldsProp, access, docLevelValidate) ->

  ->

    prevModel = undefined

    prevBusinessResult = undefined

    (fields, options) =>

      beforeSave = false

      beforeAction = false

      if options != undefined

        invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

        for optName, optValue of options

          switch optName

            when 'beforeSave' then beforeSave = !!optValue

            when 'beforeAction' then beforeAction = !!optValue

            else unknownOption optName

      if fields != prevModel

        prevBusinessResult = undefined

        prevModel = fields

      validate = type["_#{fieldsProp}Validate"]

      messages = {}

      r = access.call this, fields

      save = true

      goodForAction = beforeAction

      localResult = new Result

      localResult.error = () -> # перехватываем сообщения об ошибках

        msg = Result::error.apply localResult, arguments

        if msg.type == 'error'

          goodForAction = false

          save = false unless msg.code == 'validate.requiredField'

        return # localResult.error = () ->

      validate localResult, fields, undefined, r.update, r.required, (if beforeSave or beforeAction then undefined else fields.$$touched), false, beforeAction

      oldSave = save

      if localResult.isError

        localResult.messages.forEach (msg) ->
          if (path = msg.path) then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
          else (messages[''] or (messages[''] = [])).push msg
          return

        prevBusinessResult?.messages.forEach (msg) ->
          if (path = msg.path)
            (messages[path] = msg unless messages[path])
          else
            (messages[''] or (messages[''] = [])).push msg
          return

      else if beforeAction

        if typeof docLevelValidate == 'function'

          localResult.messages.length = 0

          docLevelValidate.call this, localResult, fields

          goodForAction = false if localResult.isError

          localResult.messages.forEach (msg) ->
            if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
            else (messages[''] or (messages[''] = [])).push msg
            return

          prevBusinessResult = if localResult.messages.length > 0 then localResult else undefined

      {save: oldSave, goodForAction, messages} # (fields) ->  # ->

# ----------------------------

module.exports = $$editValidatorBuilderBuilder

