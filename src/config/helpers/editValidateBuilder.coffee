Result = require '../../result'

$$editValidatorBuilderBuilder = (type, fieldsProp, access, businessValidate) ->

  ->

    prevModel = undefined

    prevBusinessResult = undefined

    (fields) =>

      prevBusinessResult = undefined if fields != prevModel

      validate = type["#{fieldsProp}Validate"]

      messages = {}

      r = access.call this, fields

      localResult = new Result

      save = true

      submit = true

      localResult.error = () -> # перехватываем сообщения об ошибках

        msg = Result::error.apply this, arguments

        if msg.type == 'error'

          submit = false

          save = false unless msg.code == 'validate.requiredField'

        return # localResult.error = () ->

      validate localResult, fields, r.view, r.required, fields.$$touched

      oldSave = save

      localResult.messages.forEach (msg) ->
        if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
        else (messages[''] or (messages[''] = [])).push Object.freeze(msg)
        return

      if localResult.isError

        if prevBusinessResult

          prevBusinessResult.messages.forEach (msg) ->
            if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
            else (messages[''] or (messages[''] = [])).push Object.freeze(msg)
            return
      else

        if typeof businessValidate == 'function'

          localResult.messages.length = 0

          businessValidate localResult, fields

          localResult.messages.forEach (msg) ->
            if path = msg.path then (messages[path] = msg if not messages[path] or (msg.type == 'error' and messages[path].type != 'error'))
            else (messages[''] or (messages[''] = [])).push Object.freeze(msg)
            return

          prevBusinessResult = localResult

      Object.freeze({save: oldSave, submit, messages: Object.freeze(messages)}) # (fields) ->  # ->

# ----------------------------

module.exports = $$editValidatorBuilderBuilder

