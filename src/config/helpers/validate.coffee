Result = require '../../result'
{unknownOption} = require '../../utils/_err'

{structure: validateStructure} = require '../../validate'

$$validateBuilder = (type, fieldsProp, docLevelValidate) ->

  validate = type["_#{fieldsProp}Validate"] = validateStructure type, fieldsProp

  (result, fields, options) ->

    mask = undefined

    required = undefined

    strict = true

    beforeAction = false

    beforeSave = false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'mask' then mask = optValue

          when 'required' then required = optValue

          when 'strict' then strict = optValue

          when 'beforeSave' then beforeSave = optValue

          when 'beforeAction' then beforeAction = optValue

          else unknownOption optName

    save = true

    goodForAction = beforeAction

    localResult = Object.create result

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply localResult, arguments

      if msg.type == 'error'

        goodForAction = false

        save = false unless msg.code == 'validate.requiredField'

      return # localResult.error = () ->

    validate localResult, fields, undefined, fields, mask, required, (if beforeSave and beforeAction then undefined else fields.$$touched), strict, beforeAction

    oldSave = save

    if goodForAction and beforeAction and typeof docLevelValidate == 'function'

       docLevelValidate localResult, fields # TODO: processs results

       goodForAction = false if localResult.isError

    return {save: oldSave, goodForAction}

# ----------------------------

module.exports = $$validateBuilder
