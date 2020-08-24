Result = require '../result/index'

processCustomValidate = require './processCustomValidate'

moment = require 'moment'

emptyOnlyFields = Object.freeze({})

validateStructureBuilder = (type, fieldsProp = 'fields') ->

  (value, fieldsLevel, doc, onlyFields) ->

    unless typeof value == 'object' and value != null and not Array.isArray value
      return @result.error 'validate.invalidValue', value: value

    err = undefined
    fieldName = undefined

    @result.context ((path) -> (Result.prop fieldName) path), =>

      for fieldName, fieldValue of value when not (fieldName[0] == '$' or fieldName[0] == '_')

        unless type[fieldsProp].hasOwnProperty(fieldName)
          err = (@result.error 'validate.unknownField', value: fieldValue) or err if @strict
        else
          field = type[fieldsProp][fieldName]
          alwaysValidate = field.type == 'structure' or field.type == 'subtable'
          unless not @mask or @mask.get(field.$$index)
            err = (@result.error 'validate.unexpectedField', value: fieldValue) or err if @strict
          else if not onlyFields or onlyFields[field.name] or alwaysValidate
            err = (field._validate.call @, fieldValue, value, doc, (if onlyFields then if typeof fieldValue == 'object' and fieldValue != null and not Array.isArray(fieldValue) then fieldValue.$$touched else emptyOnlyFields)) or err

    if (@beforeAction)
      field = undefined
      @result.context ((path) -> (Result.prop field.name) path), =>
        for field in type[fieldsProp].$$list when (
          (not @mask or @mask.get(field.$$index)) and
          @required?.get(field.$$index) and
          (not value.hasOwnProperty(field.name)) and
          (not onlyFields or onlyFields[field.name]))
            err = (@result.error 'validate.requiredField') or err

    err # (value, fieldsLevel, doc, onlyFields) ->

addValidate = (fields, doc, validators) ->

  fields.$$list.forEach (f) ->

    f._validate = validate f, fields, doc, validators

    addValidate f.fields, doc, validators if f.fields

    return

  fields # addValidate =

cvResult = new Result

validate = (fieldDesc, fieldsLevelDesc, docDesc, validators) ->

  f = switch fieldDesc.type

    when 'string'
      do (len = fieldDesc.length) ->
        f = (value) ->
          return @result.error 'validate.invalidValue', value: value unless typeof value == 'string'
          return @result.error 'validate.tooLong', value: value, max: len unless value.length <= len
          return @result.error 'validate.requiredField' if @beforeAction and value.length == 0 and @required?.get(fieldDesc.$$index)
          return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooShort', value: value, min: min if @beforeAction and not (min <= value.length)
            return
          return
      if fieldDesc.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = fieldDesc.regexp
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless value.length == 0 or regexp.test value
            return
          return
      f # when 'string'

    when 'text'
      f = (value) ->
        return @result.error 'validate.invalidValue', value: value unless typeof value == 'string'
        return @result.error 'validate.requiredField' if @beforeAction and value.length == 0 and @required?.get(fieldDesc.$$index)
        return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooShort', value: value, min: min if @beforeAction and not (min <= value.length)
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooLong', value: value, max: max if @beforeAction and not (value.length <= max)
            return
          return
      if fieldDesc.hasOwnProperty('regexp')
        do (pf = f) ->
          regexp = fieldDesc.regexp
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.invalidValue', value: value, regexp: regexp.toString() unless value.length == 0 or regexp.test value
            return
          return
      f # when 'text'

    when 'boolean'
      (value) -> @result.error 'validate.invalidValue', value: value unless typeof value == 'boolean'

    when 'integer'
      f = (value) ->
        return @result.error 'validate.invalidValue', value: value unless typeof value == 'number' && Number.isInteger(value)
        return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (value, fieldsLevel, doc, onlyFields) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooSmall', value: value, min: min if @beforeAction and not (min <= value)
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
          f = (value, fieldsLevel, doc, onlyFields) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooBig', value: value, max: max if @beforeAction and not (value <= max)
            return
          return
      f # when 'integer'

    when 'double'
      f = (value) ->
        @result.error 'validate.invalidValue', value: value unless typeof value == 'number'
        return
      if fieldDesc.hasOwnProperty('min')
        do (pf = f) ->
          min = fieldDesc.min
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooSmall', value: value, min: min if @beforeAction and not (min <= value)
            return
          return
      if fieldDesc.hasOwnProperty('max')
        do (pf = f) ->
          max = fieldDesc.max
          f = (value) ->
            return r if r = pf.apply @, arguments
            return @result.error 'validate.tooBig', value: value, max: max if @beforeAction and not (value <= max)
            return
          return
      f # when 'double'

    when 'decimal'
      f = (value) ->
#        @result.error 'validate.invalidValue', value: value unless typeof value == 'number' and Number.isInteger(value)
#        return
#      if fieldDesc.hasOwnProperty('min')
#        do (pf = f) ->
#          min = fieldDesc.min
#          f = (value, fieldsLevel, doc, onlyFields) ->
#            return r if r = pf.apply @, arguments
#            return @result.error 'validate.tooSmall', value: value, min: min if @beforeAction and not (min <= value)
#            return
#          return
#      if fieldDesc.hasOwnProperty('max')
#        do (pf = f) ->
#          max = fieldDesc.max
#          f = (value, fieldsLevel, doc, onlyFields) ->
#            return r if r = pf.apply @, arguments
#            return @result.error 'validate.tooBig', value: value, max: max if @beforeAction and not (value <= max)
#            return
#          return
#      f # when 'double'

    when 'date'
      (value) -> @result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment(value, 'YYYY-MM-DD').isValid()

    when 'time'
      (value) -> @result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment(value, ['HH:mm', 'HH:mm:ss', 'HH:mm:ss.SSS'], true).isValid()

    when 'timestamp'
      (value) -> @result.error 'validate.invalidValue', value: value unless typeof value == 'string' and moment(value, ['YYYY-MM-DDTHH:mm', 'YYYY-MM-DDTHH:mm:ss', 'YYYY-MM-DDTHH:mm:ss.SSS']).isValid()

    # TODO: Add timetz, timestamptz

    when 'enum'
      (value) -> @result.error 'validate.invalidValue', value: value unless typeof value == 'string' && fieldDesc.enum.hasOwnProperty(value)

    when 'structure'
      validateStructureBuilder fieldDesc

    when 'subtable'
      do ->
        validateStructure = validateStructureBuilder fieldDesc
        (value, fieldsLevel, doc, onlyFields) ->
          unless Array.isArray value
            return @result.error 'validate.invalidValue', value: value
          return @result.error 'validate.invalidValue', value: value if @required?.get(fieldDesc.$$index) and value.length == 0
          i = undefined
          err = undefined
          @result.context ((path) -> (Result.index i) path), =>
            for row, i in value
              err = (validateStructure.call @, row, undefined, doc, (if onlyFields then row.$$touched else undefined)) or err
          err # (@result, value, fieldsLevel, doc, mask) ->

    when 'nanoid'
      (value) -> @result.error 'validate.invalidValue', value: value unless typeof value == 'string' and value.length == 21

    when 'json'
      (value) ->
        return @result.error 'validate.invalidValue', value: value unless typeof value == 'string'
        try
          JSON.parse value
        catch
          return @result.error 'validate.invalidValue', value: value
        return

    when 'refers'

      # nothing TODO:

    else throw new Error("Unexpected type: #{JSON.stringify(fieldDesc)}")

  if fieldDesc.null
    do (pf = f) ->
     f = (value) ->
        if value != null
          pf.apply @, arguments
        else if @beforeAction and @required?.get(fieldDesc.$$index)
          @result.error 'validate.requiredField', value: value

  # если нет docDesc, значит это вызов из _processExtraProp, когда customValidator не используется
  customValidator = docDesc and processCustomValidate cvResult, fieldDesc, fieldsLevelDesc, docDesc, validators
  cvResult.throwIfError()

  if customValidator

    do (pf = f) ->
      f = (value, fieldsLevel, doc, onlyFields) ->
        return r if r = pf.apply @, arguments
        if @beforeAction or customValidator.basic
          customValidator @result, value, fieldsLevel, doc, @beforeAction
        return @result.isError;

  f # index =

# ----------------------------

module.exports = validate

validate.structure = validateStructureBuilder

validate.addValidate = addValidate
