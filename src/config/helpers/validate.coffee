Result = require '../../result'

{structure: validateStructure} = require '../../validate'

$$validateBuilder = (type, fieldsProp, access, businessValidate) ->

  validate = type["#{fieldsProp}Validate"] = validateStructure type, fieldsProp

  (result, fields, options) ->

    localResult = Object.create result

    save = true

    submit = true

    localResult.error = () -> # перехватываем сообщения об ошибках

      msg = Result::error.apply result, arguments

      if msg.type == 'error'

        submit = false

        save = false unless msg.code == 'validate.requiredField'

      return # localResult.error = () ->

    r = access.call this, fields

    validate localResult, fields, r.view, r.required, fields.$$touched, typeof options == 'object' && options != null and options.strict

    oldSave = save

    if submit && typeof businessValidate == 'function' then businessValidate localResult, fields

    return {save: oldSave, submit}

# ----------------------------

module.exports = $$validateBuilder
