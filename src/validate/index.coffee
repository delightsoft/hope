Result = require '../result/index'

_moment = undefined
momentLdr = -> _moment or (_moment = require 'moment')

validateStructureBuilder = (type, fieldsProp = 'fields') ->

  (result, value, fieldsLevel, viewMask, requiredMask, onlyFields, strict) ->

    unless typeof value == 'object' and value != null and not Array.isArray value
      return result.error 'validate.invalidValue', value: value

    err = undefined
    fieldName = undefined

    result.context ((path) -> (Result.prop fieldName) path), ->
      for fieldName, fieldValue of value when not fieldName.startsWith '$$'
        unless type[fieldsProp].hasOwnProperty(fieldName)
          err = (result.error 'validate.unknownField', value: fieldValue) or err
        else
          field = type[fieldsProp][fieldName]
          alwaysValidate = field.type == 'structure' or field.type == 'subtable'
          if not viewMask.get(field.$$index)
            err = (result.error 'validate.unexpectedField', value: fieldValue) or err if strict
          else if not onlyFields or onlyFields[field.name] or alwaysValidate
            err = (field._validate result, fieldValue, value , viewMask, requiredMask, (if typeof field == 'object' and field != null and not Array.isArray(field) then field.$$touched), strict) or err

    field = undefined
    result.context ((path) -> (Result.prop field.name) path), ->
      for field in type[fieldsProp].$$list when (
        viewMask.get(field.$$index) and
        (field.required or (requiredMask and requiredMask.get(field.$$index))) and
        not value.hasOwnProperty(field.name) and
        (not onlyFields or onlyFields[field.name]))
          err = (result.error 'validate.requiredField') or err

    err # (result, value, mask, onlyFields) ->

addValidate = (fields) ->

  fields.$$list.forEach (f) ->

    f._validate = validate f

    addValidate f.fields if f.fields

    return

  fields # addValidate =

validate = (fieldDesc) ->

  f = switch fieldDesc.type

    when 'string'
      do (len = fieldDesc.length) ->
        f = (result, value, fieldsLevel, viewMask, requiredMask) ->
          return result.error 'validate.invalidValue', value: value unless typeof value == 'string'
          return result.error 'validate.tooLong', value: value, max: len unless value.length <= len
          return result.error 'validate.requiredField' if value.length == 0 and (fieldDesc.required or ((requiredMask and requiredMask.get(fieldDesc.$$index))))
          return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (result, value, fieldsLevel, viewMask, requiredMask) ->
            return r if r = pf(result, value, fieldsLevel, viewMask, requiredMask)
            return result.error 'validate.tooShort', value: value, min: min unless min <= value.length
            return
          return
      if fieldDesc.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = fieldDesc.regexp
          f = (result, value, fieldsLevel, viewMask, requiredMask) ->
            return r if r = pf(result, value, fieldsLevel, viewMask, requiredMask)
            return result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless regexp.test value
            return
          return
      f # when 'string'

    when 'text'
      f = (result, value, fieldsLevel, viewMask, requiredMask) ->
        return result.error 'validate.invalidValue', value: value unless typeof value == 'string'
        return result.error 'validate.requiredField' if value.length == 0 and (fieldDesc.required or ((requiredMask and requiredMask.get(fieldDesc.$$index))))
        return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (result, value, fieldsLevel, viewMask, requiredMask) ->
            return r if r = pf(result, value, fieldsLevel, viewMask, requiredMask)
            return result.error 'validate.tooShort', value: value, min: min unless min <= value.length
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
          f = (result, value, fieldsLevel, viewMask, requiredMask) ->
            return r if r = pf(result, value, fieldsLevel, viewMask, requiredMask)
            return result.error 'validate.tooLong', value: value, max: max unless value.length <= max
            return
          return
      if fieldDesc.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = fieldDesc.regexp
          f = (result, value, fieldsLevel, viewMask, requiredMask) ->
            return r if r = pf(result, value, fieldsLevel, viewMask, requiredMask)
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
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooSmall', value: value, min: min unless min <= value
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
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
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooSmall', value: value, min: min unless min <= value
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
          f = (result, value) ->
            return r if r = pf(result, value)
            return result.error 'validate.tooBig', value: value, max: max unless value <= max
            return
          return
      f # when 'double'

    when 'date'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and momentLdr()(value, 'YYYY-MM-DD').isValid()

    when 'time'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and momentLdr()(value, 'HH:mm', true).isValid()

    when 'timestamp'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and momentLdr()(value, 'YYYY-MM-DD HH:mm').isValid()

    # TODO: Add timetz, timestamptz

    when 'enum'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' && fieldDesc.enum.hasOwnProperty(value)

    when 'structure'
      validateStructureBuilder(fieldDesc)

    when 'subtable'
      do ->
        validateStructure = validateStructureBuilder fieldDesc
        (result, value, fieldsLevel, viewMask, requiredMask, strict) ->
          unless Array.isArray value
            return result.error 'validate.invalidValue', value: value
          return result.error 'validate.invalidValue', value: value if (fieldDesc.required or (requiredMask and requiredMask.get(fieldDesc.$$index))) and value.length == 0
          result.isError = false
          i = undefined
          err = undefined
          result.context ((path) -> (Result.index i) path), ->
            for row, i in value
              err = (validateStructure result, row, undefined, viewMask, requiredMask, row.$$touched, strict) or err
          err # (result, value, fieldsLevel, mask) ->

    else (result, value, viewMask, requiredMask, strict) -> {}

  if fieldDesc.null
    do (pf = f) ->
      f = (result, value) ->
        if value != null
          return pf result, value
        return
      return

  f # index =

# ----------------------------

module.exports = validate

validate.structure = validateStructureBuilder

validate.addValidate = addValidate
