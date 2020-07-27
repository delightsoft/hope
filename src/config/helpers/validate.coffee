Result = require '../../result'

{structure: validateStructure} = require '../../validate'

$$validateBuilder = (type, fieldsProp, $$access, businessValidate) ->

  validate = type["#{fieldsProp}Validate"] = validateStructure type, fieldsProp

  (result, fields, options) ->

    access = undefined

    strict = true

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'access' then access = optValue

          when 'strict' then strict = optValue

          else unknownOption optName

    access = $$access.call @, fields unless access

    save = true

    submit = true

    localResult = Object.create result

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply localResult, arguments

      if msg.type == 'error'

        submit = false

        save = false unless msg.code == 'validate.requiredField'

      return # localResult.error = () ->

    validate localResult, fields, undefined, access.view, access.required, fields.$$touched, typeof options == 'object' && options != null and options.strict

    oldSave = save

    if submit && typeof businessValidate == 'function' then businessValidate localResult, fields

    return {save: oldSave, submit}

# ----------------------------

module.exports = $$validateBuilder
