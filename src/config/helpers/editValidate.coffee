Result = require '../../result'

cloneDeep = require 'lodash/cloneDeep'

{invalidArg, unknownOption} = require '../../utils/_err'

$$editValidatorBuilder = (type, fieldsProp, access, docLevelValidate) ->

  typeDesc = if type.$$access == access then type else type[fieldsProp]

  (fields, options) ->

    opts =

      mask: undefined

      required: undefined

      strict: false

      beforeSave: false

      beforeAction: false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'strict' then opts.strict = optValue

          when 'beforeSave' then opts.beforeSave = !!optValue

          when 'beforeAction' then opts.beforeAction = !!optValue

          else unknownOption optName

    validate = type["_#{fieldsProp}Validate"]

    messages = {}

    save = true

    goodForAction = opts.beforeAction

    r = access.call typeDesc, fields, null

    opts.mask = if opts.beforeAction then r.view.or(r.update) else r.update

    opts.required = r.required

    opts.result = localResult = new Result

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply localResult, arguments

      if msg.type == 'error'

        goodForAction = false

        save = false if ~['validate.invalidValue', 'validate.unknownField', 'validate.unexpectedField'].indexOf(msg.code)

      msg # localResult.error = () ->

    validate.call opts, fields, undefined, fields, (if opts.beforeSave or opts.beforeAction then undefined else fields.$$touched)

    oldSave = save

    if save and opts.beforeAction and typeof docLevelValidate == 'function'

      docLevelValidate?.call type, localResult, fields

    localResult.messages.forEach (msg) ->
      if (path = msg.path)
        if not messages[path] or (msg.type == 'error' and messages[path].type != 'error')
          messages[path] = msg
      else
        (messages[''] or (messages[''] = [])).push msg
      return

    {save: oldSave, goodForAction, messages} # (fields) ->  # ->

# ----------------------------

module.exports = $$editValidatorBuilder

