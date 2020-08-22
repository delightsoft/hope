Result = require '../result'

processCustomValidate = (result, fieldDesc, fieldsLevel, docDesc, validators) ->

  return unless fieldDesc.hasOwnProperty('validate')

  validate = fieldDesc.validate.trim()

  si = validate.indexOf('(')

  ei = validate.indexOf(')')

  unless (not ~si and not ~ei) or (~si and ei == validate.length - 1)

    result.error ((path) -> (Result.prop 'validate') path), 'dsc.invalidValue', value: validate

    return

  else

    if ~si

      name = validate.substr 0, si

      params = validate.substr(si + 1, ei - si - 1)

    else

      name = validate

    unless typeof validators?[name] == 'function'

      result.error ((path) -> (Result.prop 'validate') path), 'dsc.unknownValidator', value: validate

      return

    else

      result.context ((path) -> (Result.prop 'validate') path), =>

        validators[name].call @, result, fieldDesc, params, fieldsLevel, docDesc, validate # processCustomValidate =

# ----------------------------

module.exports = processCustomValidate
