Result = require '../../result'

{invalidArg, unknownOption} = require '../../utils/_err'

$$editValidatorBuilderBuilder = (type, fieldsProp, access, businessValidate) ->

  ->

    prevModel = undefined

    prevBusinessResult = undefined

    (fields, options) =>

      beforeSubmit = false

      if options != undefined

        invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

        for optName, optValue of options

          switch optName

            when 'beforeSubmit' then beforeSubmit = !!optValue

            else unknownOption optName

      if fields != prevModel

        prevBusinessResult = undefined

        prevModel = fields

      validate = type["#{fieldsProp}Validate"]

      messages = {}

      r = access.call this, fields

      save = true

      submit = true

      localResult = new Result

      localResult.error = () -> # перехватываем сообщения об ошибках

        msg = Result::error.apply localResult, arguments

        if msg.type == 'error'

          submit = false

          save = false unless msg.code == 'validate.requiredField'

        return # localResult.error = () ->

      validate localResult, fields, r.view, r.required, if beforeSubmit then fields.$$touched else undefined

      oldSave = save

      if localResult.isError

        if prevBusinessResult

          prevBusinessResult.messages.forEach (msg) ->
            if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
            else (messages[''] or (messages[''] = [])).push msg
            return

        localResult.messages.forEach (msg) ->
          if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
          else (messages[''] or (messages[''] = [])).push msg
          return

      else unless beforeSubmit

        if typeof businessValidate == 'function'

          localResult.messages.length = 0

          businessValidate.call this, localResult, fields

          localResult.messages.forEach (msg) ->
            if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
            else (messages[''] or (messages[''] = [])).push msg
            return

          prevBusinessResult = localResult

      {save: oldSave, submit, messages} # (fields) ->  # ->

# ----------------------------

module.exports = $$editValidatorBuilderBuilder

