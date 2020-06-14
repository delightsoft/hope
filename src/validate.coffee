Result = require '../src/result'

_moment = undefined
moment = -> _moment || (_moment = require 'moment')

validateStructure = (type) ->
  (result, value) ->
    unless typeof value == 'object' and value != null and not Array.isArray value
      result.error 'validate.invalidValue', value: value
      return
    fields = type.fields.$$list
    result.isError = false
    name = undefined
    result.context ((path) -> (Result.prop name) path), ->
      for field in fields
        name = field.name
        if value.hasOwnProperty(name)
          field.validate result, value[name]
        else if field.required
          result.error 'validate.missingField', value: name
    result.error 'validate.invalidValue', value: value if result.isError
    return

addValidate = (fields) ->

  fields.$$list.forEach (f) ->

    f.validate = validate f

    addValidate f.fields if f.fields

    return

  fields # addValidate =

validate = (type) ->

  switch type.type

    when 'string'
      f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string'; return
      if type.hasOwnProperty('min') then do (pf = f) ->
        min = type.min
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.tooShort', value: value, min: min unless !result.isError and min <= value.length
          return
        return
      if type.hasOwnProperty('max') then do (pf = f) ->
        max = type.max
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.tooLong', value: value, max: max unless !result.isError and value.length <= max
          return
        return
      if type.hasOwnProperty('regexp') then do (pf = f) ->
        regexp = type.regexp
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless !result.isError and regexp.test value
          return
        return

    when 'text'
      f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string'
      if type.hasOwnProperty('regexp') then do (pf = f) ->
        regexp = type.regexp
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless !result.isError and regexp.test value
          return
        return

    when 'boolean' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'boolean'; return

    when 'integer'
      f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'number' && Number.isInteger(value)
      if type.hasOwnProperty('min') then do (pf = f) ->
        min = type.min
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.tooSmall', value: value, min: min unless !result.isError and min <= value
          return
        return
      if type.hasOwnProperty('max') then do (pf = f) ->
        max = type.max
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.tooBig', value: value, max: max unless !result.isError and value <= max
          return
        return

    when 'double'
      f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'number'; return
      if type.hasOwnProperty('min') then do (pf = f) ->
        min = type.min
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.tooSmall', value: value, min: min unless !result.isError and min <= value
          return
        return
      if type.hasOwnProperty('max') then do (pf = f) ->
        max = type.max
        f = (result, value) ->
          pf(result, value)
          result.error 'validate.tooBig', value: value, max: max unless !result.isError and value <= max
          return
        return

    when 'time' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment()(value, 'HH:MM').isValid(); return

    when 'date' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment()(value, 'YYYY-MM-DD HH:MM').isValid(); return

    when 'dateonly' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment()(value, 'YYYY-MM-DD').isValid(); return

    when 'enum' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string' && type.enum.hasOwnProperty(value); return

    when 'structure' then f = validateStructure(type)

    when 'subtable' then f = (result, value) ->
      unless Array.isArray value
        result.error 'validate.invalidValue', value: value
        return
      result.isError = false
      i = undefined
      result.context ((path) -> (Result.item i) path), ->
        for row, i in value
          validateStructure result, row
      result.error 'validate.invalidValue', value: value if result.isError or (type.required and value.length == 0)
      return

  if type.null then do (pf = f) ->
    f = (result, value) ->
      if value != null then pf result, value
      return
    return

  f # validate =

# ----------------------------

module.exports = validate

validate.structure = validateStructure

validate.addValidate = addValidate
