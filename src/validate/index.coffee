validate = (type) ->

  switch type.type

    when 'string' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'string'; return
    when 'text' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'string'; return
    when 'boolean' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'boolean'; return
    when 'integer' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'number' && Number.isInteger(value); return
    when 'double' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'number'; return
    when 'enum' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'string' && type.enum.hasOwnProperty(value); return
    when 'structure' then f = (result, value) ->
      unless typeof value == 'object' and value != null and not Array.isArray value
        result.error 'dsc.invalidValue', value: value
        return
      result.isError = false
      name = undefined
      result.context ((path) -> (Result.prop name) path), ->
        for field in type.fields
          name = field.name
          field.validate(result, value[name])
      result.error 'dsc.invalidValue', value: value if result.isError
      return

    # TODO: Subtable

#    when 'string' then f = (result, value) -> result.error 'dsc.invalidValue', value: value unless typeof value == 'string'

  f # validate =

# ----------------------------

module.exports = validate
