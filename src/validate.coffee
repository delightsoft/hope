Result = require '../src/result'

_moment = undefined
momentLdr = -> _moment || (_moment = require 'moment')

# type - structure или subtable
validateStructure = (type) ->
  # mask - поля, которые нужно прверять
  # onlyFields - необязательный map, только поля которые нужно проверять
  (result, value, viewMask, requiredMask, onlyFields) ->

    unless typeof value == 'object' and value != null and not Array.isArray value
      return result.error 'validate.invalidValue', value: value

    err = undefined
    fieldName = undefined

    result.context ((path) -> (Result.prop fieldName) path), ->
      for fieldName, fieldValue of value
        unless type.fields.hasOwnProperty(fieldName)
          err = (result.error 'validate.unknownField', name: fieldName, value: fieldValue) or err
        else
          field = type.fields[fieldName]
          if viewMask and not viewMask.get(field.$$index)
            err = (result.error 'validate.unexpectedField', name: fieldName, value: fieldValue) or err
          else if not onlyFields or onlyFields[field.name]
            err = (field.validate result, fieldValue, viewMask, requiredMask, if typeof field == 'object' and field != null and not Array.isArray(field) then field.$$touched) or err

    for field in type.fields.$$list when (field.required or (requiredMask and requiredMask.get(field.$$index))) and not value.hasOwnProperty(field.name) and (not onlyFields or onlyFields[field.name])
      err = (result.error 'validate.missingField', value: field.name) or err

    err # (result, value, mask, onlyFields) ->

addValidate = (fields) ->

  fields.$$list.forEach (f) ->

    f.validate = validate f

    addValidate f.fields if f.fields

    return

  fields # addValidate =

validate = (type) ->

  f = switch type.type

    when 'string'
      f = (result, value) ->
        return result.error 'validate.invalidValue', value: value unless typeof value == 'string'
        return
      if type.hasOwnProperty('min') or type.required
        do (pf = f) ->
          min = type.min || 1
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooShort', value: value, min: min unless min <= value.length
            return
          return
      if type.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = type.regexp
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless regexp.test value
            return
          return
      f # when 'string'

    when 'text'
      f = (result, value) ->
        result.error 'validate.invalidValue', value: value unless typeof value == 'string'
        return
      if type.hasOwnProperty('min') || type.required
        do (pf = f) ->
          min = type.min || 1
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooShort', value: value, min: min unless min <= value.length
            return
          return
      if type.hasOwnProperty('max')
        do (pf = f) ->
          max = type.max
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooLong', value: value, max: max unless value.length <= max
            return
          return
      if type.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = type.regexp
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless regexp.test value
            return
          return
      f # when 'text'

    when 'boolean'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'boolean'

    when 'integer'
      f = (result, value) ->
        return result.error 'validate.invalidValue', value: value unless typeof value == 'number' && Number.isInteger(value)
        return
      if type.hasOwnProperty('min')
        do (pf = f) ->
          min = type.min
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooSmall', value: value, min: min unless min <= value
            return
          return
      if type.hasOwnProperty('max')
        do (pf = f) ->
          max = type.max
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooBig', value: value, max: max unless value <= max
            return
          return
      f # when 'integer'

    when 'double'
      f = (result, value) ->
        result.error 'validate.invalidValue', value: value unless typeof value == 'number'
        return
      if type.hasOwnProperty('min')
        do (pf = f) ->
          min = type.min
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooSmall', value: value, min: min unless min <= value
            return
          return
      if type.hasOwnProperty('max')
        do (pf = f) ->
          max = type.max
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooBig', value: value, max: max unless value <= max
            return
          return
      f # when 'double'

    when 'time'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and momentLdr()(value, 'HH:mm', true).isValid()

    when 'date'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and momentLdr()(value, 'YYYY-MM-DD HH:mm').isValid()

    when 'dateonly'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and momentLdr()(value, 'YYYY-MM-DD').isValid()

    when 'enum'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' && type.enum.hasOwnProperty(value)

    when 'structure'
      validateStructure(type)

    when 'subtable'
      (result, value, viewMask, requiredMask) ->
        unless Array.isArray value
          return result.error 'validate.invalidValue', value: value
        return result.error 'validate.invalidValue', value: value if result.isError or (type.required and value.length == 0)
        result.isError = false
        i = undefined
        err = undefined
        result.context ((path) -> (Result.index i) path), ->
          for row, i in value
            err = (validateStructure result, row, viewMask, requiredMask, row.$$touched) or err
            return
        err # (result, value, mask) ->

  if type.null
    do (pf = f) ->
      f = (result, value) ->
        if value != null
          return pf result, value
        return
      return

  f # validate =

# ----------------------------

module.exports = validate

validate.structure = validateStructure

validate.addValidate = addValidate
