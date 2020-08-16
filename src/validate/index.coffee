Result = require '../result/index'

processCustomValidate = require './processCustomValidate'

moment = require 'moment'

emptyOnlyFields = Object.freeze({})

validateStructureBuilder = (type, fieldsProp = 'fields') ->

  (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeActiom) ->

    unless typeof value == 'object' and value != null and not Array.isArray value
      return result.error 'validate.invalidValue', value: value

    err = undefined
    fieldName = undefined

    result.context ((path) -> (Result.prop fieldName) path), ->

      for fieldName, fieldValue of value when not (fieldName[0] == '$' or fieldName[0] == '_')

        unless type[fieldsProp].hasOwnProperty(fieldName)
          err = (result.error 'validate.unknownField', value: fieldValue) or err if strict
        else
          field = type[fieldsProp][fieldName]
          alwaysValidate = field.type == 'structure' or field.type == 'subtable'
          unless not mask or mask.get(field.$$index)
            err = (result.error 'validate.unexpectedField', value: fieldValue) or err if strict
          else if not onlyFields or onlyFields[field.name] or alwaysValidate
            err = (field._validate result, fieldValue, value, mask, requiredMask, (if onlyFields then if typeof fieldValue == 'object' and fieldValue != null and not Array.isArray(fieldValue) then fieldValue.$$touched else emptyOnlyFields), strict, beforeActiom) or err

    if (beforeActiom)
      field = undefined
      result.context ((path) -> (Result.prop field.name) path), ->
        for field in type[fieldsProp].$$list when (
          (not mask or mask.get(field.$$index)) and
          (field.required or (requiredMask and requiredMask.get(field.$$index))) and
          (not value.hasOwnProperty(field.name) or value[field.name] == null) and
          (not onlyFields or onlyFields[field.name]))
            err = (result.error 'validate.requiredField') or err

    err # (result, value, mask, onlyFields) ->

addValidate = (fields, validators) ->

  fields.$$list.forEach (f) ->

    f._validate = validate f, fields, validators

    addValidate f.fields, validators if f.fields

    return

  fields # addValidate =

cvResult = new Result

validate = (fieldDesc, fields, validators) ->

  f = switch fieldDesc.type

    when 'string'
      do (len = fieldDesc.length) ->
        f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
          return result.error 'validate.invalidValue', value: value unless typeof value == 'string'
          return result.error 'validate.tooLong', value: value, max: len unless value.length <= len
          return result.error 'validate.requiredField' if beforeAction and value.length == 0 and (fieldDesc.required or ((requiredMask and requiredMask.get(fieldDesc.$$index))))
          return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
            return r if r = pf(result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction)
            return result.error 'validate.tooShort', value: value, min: min unless min <= value.length
            return
          return
      if fieldDesc.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = fieldDesc.regexp
          f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
            return r if r = pf(result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction)
            return result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless regexp.test value
            return
          return
      f # when 'string'

    when 'text'
      f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
        return result.error 'validate.invalidValue', value: value unless typeof value == 'string'
        return result.error 'validate.requiredField' if beforeAction and value.length == 0 and (fieldDesc.required or ((requiredMask and requiredMask.get(fieldDesc.$$index))))
        return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
            return r if r = pf(result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction)
            return result.error 'validate.tooShort', value: value, min: min unless min <= value.length
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
          f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
            return r if r = pf(result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction)
            return result.error 'validate.tooLong', value: value, max: max unless value.length <= max
            return
          return
      if fieldDesc.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = fieldDesc.regexp
          f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
            return r if r = pf(result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction)
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
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment(value, 'YYYY-MM-DD').isValid()

    when 'time'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment(value, ['HH:mm', 'HH:mm:ss', 'HH:mm:ss.SSS'], true).isValid()

    when 'timestamp'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment(value, ['YYYY-MM-DDTHH:mm', 'YYYY-MM-DDTHH:mm:ss', 'YYYY-MM-DDTHH:mm:ss.SSS']).isValid()

    # TODO: Add timetz, timestamptz

    when 'enum'
      (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' && fieldDesc.enum.hasOwnProperty(value)

    when 'structure'
      validateStructureBuilder fieldDesc

    when 'subtable'
      do ->
        validateStructure = validateStructureBuilder fieldDesc
        (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict, beforeAction) ->
          unless Array.isArray value
            return result.error 'validate.invalidValue', value: value
          return result.error 'validate.invalidValue', value: value if (fieldDesc.required or (requiredMask and requiredMask.get(fieldDesc.$$index))) and value.length == 0
          result.isError = false
          i = undefined
          err = undefined
          result.context ((path) -> (Result.index i) path), ->
            for row, i in value
              err = (validateStructure result, row, undefined, mask, requiredMask, (if onlyFields then row.$$touched else undefined), strict, beforeAction) or err
          err # (result, value, fieldsLevel, mask) ->

    else (result, value, mask, requiredMask, strict) -> {}

  if fieldDesc.null
    do (pf = f) ->
      f = (result, value) ->
        if value != null
          return pf result, value
        return
      return

  customValidator = processCustomValidate cvResult, fieldDesc, fields, validators
  cvResult.throwIfError()

  if customValidator
    do (pf = f) ->
      f = (result, value, fieldsLevel, mask, requiredMask, onlyFields, strict) ->
        return r if r = pf(result, value, fieldsLevel, mask, requiredMask, onlyFields, strict)
        result.isError = false;
        customValidator result, value, fieldsLevel
        return result.isError;

  f # index =

# ----------------------------

module.exports = validate

validate.structure = validateStructureBuilder

validate.addValidate = addValidate
