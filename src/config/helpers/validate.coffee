Result = require '../../result'
{unknownOption} = require '../../utils/_err'

{structure: validateStructure} = require '../../validate'

$$validateBuilder = (type, fieldsProp, docLevelValidate) ->

  validate = type["_#{fieldsProp}Validate"] = validateStructure type, fieldsProp

  access = undefined

  (result, fields, options) ->

    opts =

      result: result

      mask: undefined

      required: type[fieldsProp].$$tags.required

      strict: true

      beforeAction: false

      beforeSave: false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'access' then access = optValue

          when 'mask' then opts.mask = optValue

          when 'strict' then opts.strict = optValue

          when 'beforeSave' then opts.beforeSave = optValue

          when 'beforeAction' then opts.beforeAction = optValue

          else unknownOption optName

    save = true

    goodForAction = opts.beforeAction

    access = (if fieldsProp == 'fields' then type else type[fieldsProp]).$$access fields unless access

    opts.mask = (if opts.beforeAction then access.view.or(access.update) else access.update) unless opts.mask

    opts.required = access.required

    try

      result.error = () -> # перехватываем сообщения об ошибках

        msg = Result::error.apply result, arguments

        if msg.type == 'error'

          goodForAction = false

          save = false unless msg.code == 'validate.requiredField'

        msg # result.error = () ->

      validate.call opts, fields, undefined, fields, (if opts.beforeSave and opts.beforeAction then undefined else fields.$$touched)

      oldSave = save

      if goodForAction and opts.beforeAction and typeof docLevelValidate == 'function'

         docLevelValidate.call opts, result, fields

         goodForAction = false if result.isError

    finally

      result.error = Result::error

    return {save: oldSave, goodForAction}

# ----------------------------

module.exports = $$validateBuilder
