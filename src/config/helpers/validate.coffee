Result = require '../../result'

{structure: validateStructure} = require '../../validate'

$$validateBuilder = (type, fieldsProp, $$access, docLevelValidate) ->

  validate = type["_#{fieldsProp}Validate"] = validateStructure type, fieldsProp

  (result, fields, options) ->

    access = undefined

    strict = true

    beforeAction = false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'access' then access = optValue

          when 'strict' then strict = optValue

          when 'beforeAction' then beforeAction = optValue

          else unknownOption optName

    access = $$access.call @, fields unless access

    save = true

    goodForAction = beforeAction

    localResult = Object.create result

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply localResult, arguments

      if msg.type == 'error'

        goodForAction = false

        save = false unless msg.code == 'validate.requiredField'

      return # localResult.error = () ->

    validate localResult, fields, undefined, access.view, access.required, fields.$$touched, strict, beforeAction

    oldSave = save

    if goodForAction and beforeAction and typeof docLevelValidate == 'function'

       docLevelValidate localResult, fields # TODO: processs results

       goodForAction = false if localResult.isError

    return {save: oldSave, goodForAction}

# ----------------------------

module.exports = $$validateBuilder
