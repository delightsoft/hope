Result = require '../../result'
{unknownOption} = require '../../utils/_err'

{structure: validateStructure} = require '../../validate'

$$validateBuilder = (type, fieldsProp, docLevelValidate) ->

  validate = type["_#{fieldsProp}Validate"] = validateStructure type, fieldsProp

  (result, fields, options) ->

    opts =

      mask: undefined

      requiredMask: undefined

      strict: true

      beforeAction: false

      beforeSave: false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'mask' then opts.mask = optValue

          when 'required' then opts.requiredMask = optValue

          when 'strict' then opts.strict = optValue

          when 'beforeSave' then opts.beforeSave = optValue

          when 'beforeAction' then opts.beforeAction = optValue

          else unknownOption optName

    save = true

    goodForAction = opts.beforeAction

    opts.result = localResult = Object.create result # inherit given result object, to intercept it's 'error' method calls

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply localResult, arguments

      if msg.type == 'error'

        goodForAction = false

        save = false unless msg.code == 'validate.requiredField'

      return # localResult.error = () ->

    validate.call opts, fields, undefined, fields, (if opts.beforeSave and opts.beforeAction then undefined else fields.$$touched)

    oldSave = save

    if goodForAction and opts.beforeAction and typeof docLevelValidate == 'function'

       docLevelValidate.call opts, localResult, fields

       goodForAction = false if localResult.isError

    return {save: oldSave, goodForAction}

# ----------------------------

module.exports = $$validateBuilder
