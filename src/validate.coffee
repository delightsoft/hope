_moment = undefined
moment = -> _moment || (_moment = require 'moment')

validateStructure = (type) ->
  (result, value) ->
    unless typeof value == 'object' and value != null and not Array.isArray value
      result.error 'validate.invalidValue', value: value
      return
    fields = type.fields
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

validate = (type) ->

  switch type.type

    when 'string' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string'; return

    when 'text' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'string'; return

    when 'boolean' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'boolean'; return

    when 'integer' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'number' && Number.isInteger(value); return

    when 'double' then f = (result, value) -> result.error 'validate.invalidValue', value: value unless typeof value == 'number'; return

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
      if value == null then return
      else pf result, value

  f # validate =

# ----------------------------

module.exports = validate

validate.structure = validateStructure
