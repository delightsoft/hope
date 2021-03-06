{checkUDTypeName, err: {tooManyArgs, invalidArg, isResult}} = require '../utils'

Result = require '../result'

{checkEnumName} = require '../utils'

sortedMap = require '../sortedMap'

processExraProps = require './_processExraProps'

copyExtra = require '../config/_copyExtra'

typeProps = ['length', 'enum', 'precision', 'scale', 'fields', 'refers', 'valueClass', 'null', 'required']

extraProps = ['min', 'max', 'regexp', 'init', 'validate']

builtInTypes = [
  'nanoid',
  'string', 'text', 'boolean',
  'integer', 'double'
  'decimal'
  'time', 'date', 'timestamp'
  'json', 'blob', 'uuid', 'enum'
  'structure', 'subtable'
  'refers'
]

reservedTypes = ['long', 'float', 'timetz', 'timestamptz']

compile = (result, fieldDesc, res, opts) ->
  invalidArg 'result', result unless isResult result
  invalidArg 'fieldDesc', fieldDesc unless typeof fieldDesc == 'object' && fieldDesc != null
  invalidArg 'res', fieldDesc unless res == undefined || (typeof res == 'object' && res != null && !Array.isArray(res))
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))
  tooManyArgs() unless arguments.length <= 4

  unless opts?.hasOwnProperty('context') # list of prop that should not be reported in validation
    optsContext = null # any
  else
    invalidArg 'opts.context', opts.context unless (optsContext = opts.context) == 'field' || optsContext == 'udtype'

  optsUdtype = opts?.udType

  throw new Error "fieldDesc was already process by tags/compile()" unless not fieldDesc.hasOwnProperty '$$tags'

  result.isError = false

  # Определяем тип.  То что в скобках выделяем в options.

  if fieldDesc.hasOwnProperty('type')

    if (optionsIndex = (type = sourceType = fieldDesc.type.trim()).indexOf '(') != -1

      unless (optionsEnd = (options = type.indexOf ')')) > optionsIndex # missing ) or it's before (
        result.error 'dsc.invalidTypeValue', value: type
        return

      unless optionsEnd == type.length - 1 # something after )
        result.error 'dsc.invalidTypeValue', value: type
        return

      if (optionsLen = optionsEnd - optionsIndex - 1) == 0
        result.error 'dsc.invalidTypeValue', value: type
        return

      options = type.substr optionsIndex + 1, optionsLen
      type = type.substr(0, optionsIndex).trim()

    unless checkUDTypeName type

      result.error 'dsc.invalidTypeValue', value: type;
      return

# Если тип не указан, пробуем его определить по косвенному признаку

  else if fieldDesc.hasOwnProperty('enum')

    type = 'enum'

  else if fieldDesc.hasOwnProperty('fields')

    type = 'structure'

  else if fieldDesc.hasOwnProperty('refers')

    type = 'refers'

  else
    result.error 'dsc.missingProp', value: 'type';
    return

  # Заменяем короткие имена типов на полные

  switch type

    when 'str' then type = 'string'

    when 'bool' then type = 'boolean'

    when 'int' then type = 'integer'

    when 'struct' then type = 'structure'

    when 'ref' then type = 'refers'

  # Проверяем, что тип входит в список типов

  unless builtInTypes.indexOf(type) >= 0

    if reservedTypes.indexOf(type) >= 0 # reserved type name

      result.error 'dsc.reservedType', value: sourceType

    else if options # udType cannot have an option

      result.error 'dsc.unknownType', value: sourceType

    else # user defined type

      res.udType = type

      res.required = true if typeof requiredProp == 'boolean' and requiredProp

      res.null = true if typeof nullProp == 'boolean' and nullProp

      return res unless result.isError

    return

  # Проверяем, наличие всех свойств относящихся к типу.  Если свойство не должно быть у данного типа, добавляем ошибку

  prop = lengthProp = enumProp = precisionProp = scaleProp = fieldsProp = nullProp = requiredProp = refersProp = valueClass = undefined

  if fieldDesc.hasOwnProperty('udType')

    result.error 'dsc.reservedAttr', value: 'udType'

  result.context ((path) -> (Result.prop prop) path), ->

    for prop in typeProps when fieldDesc.hasOwnProperty(prop)

      ok = false

      switch prop

        when 'length' then if (ok = type == 'string') then lengthProp = takePositiveInt result, fieldDesc.length

        when 'enum' then if (ok = type == 'enum') then enumProp = takeEnum result, fieldDesc.enum

        when 'precision' then if (ok = type == 'decimal') then precisionProp = takePositiveInt result, fieldDesc.precision

        when 'scale' then if (ok = type == 'decimal') then scaleProp = takeNoneNegativeInt result, fieldDesc.scale

        when 'fields' then ok = (type == 'structure' || type == 'subtable') # this prop is already taken during flatMap

        when 'null'

          ok = true

          if optsContext == null || optsContext == 'field'

            nullProp = takeBoolean result, fieldDesc.null

          else

            result.error 'dsc.notApplicableInUdtype'

        when 'required'

          ok = true

          if optsContext == null || optsContext == 'field'

            requiredProp = takeBoolean result, fieldDesc.required

          else

            result.error 'dsc.notApplicableInUdtype'

        when 'refers' then if (ok = (type == 'refers')) then refersProp = takeStringOrArrayOfStrings result, fieldDesc.refers

      unless ok or extraProps.indexOf(prop) >= 0

        result.error 'dsc.notApplicableForTheTypeProp', nameValue: prop, typeValue: type

  # работаем с length для string

  if result.isError

    delete fieldDesc.type

    delete fieldDesc[prop] for prop in typeProps

    return

  if options

    result.context ((path) -> (Result.prop "(#{options})") path), ->
      switch type

        when 'string'

          lengthPropFromOptions = takePositiveInt result, parseFloat options

          if lengthProp

            result.error 'dsc.ambiguousProp',
              name: 'length', value1: (lengthPropFromOptions || options), value2: lengthProp

          else
            lengthProp = lengthPropFromOptions

        when 'refers'

          if (refersPropFromOptions = options.trim()).length == 0

            result.error 'dsc.invalidValue', value: options

          else if refersProp

            result.error 'dsc.ambiguousProp',
              name: 'refers', value1: (refersPropFromOptions || options), value2: refersProp

          else
            refersProp = refersPropFromOptions

        else

          result.error 'dsc.unknownType', value: sourceType

  # собираем результирующую структуру

  if result.isError

    delete fieldDesc.type

    delete fieldDesc[prop] for prop in typeProps

    return

  res.type = type

  res.required = true if typeof requiredProp == 'boolean' and requiredProp

  res.null = true if typeof nullProp == 'boolean' and nullProp

  switch type

    when 'string' then setRequiredProp result, res, 'length', lengthProp

    when 'enum' then setRequiredProp result, res, 'enum', enumProp

    when 'decimal'

      res.precision =

        if typeof precisionProp == 'number'

          unless 1 <= precisionProp <= 15

            result.error (Result.prop 'precision'), 'dsc.precisionOutOfRange', value: precisionProp, min: 1, max: 15

          else

            res.precision = precisionProp

        else 15

      unless result.isError

        res.scale =

          if typeof scaleProp == 'number'

            unless 0 <= scaleProp <= res.precision

              result.error (Result.prop 'scale'), 'dsc.scaleOutOfRange', value: scaleProp, min: 0, max: res.precision

            else

              res.scale = scaleProp

          else 0

    when 'structure'

      unless fieldDesc.hasOwnProperty('fields')

        result.error 'dsc.missingProp', value: 'fields'

      unless optsUdtype or res.hasOwnProperty('fields')

        result.error (Result.prop 'fields'), 'dsc.invalidValue', value: fieldDesc.fields

    when 'subtable'

      unless fieldDesc.hasOwnProperty('fields')

        result.error 'dsc.missingProp', value: 'fields'

      unless optsUdtype or res.hasOwnProperty('fields')

        result.error (Result.prop 'fields'), 'dsc.invalidValue', value: fieldDesc.fields

    when 'refers' then setRequiredProp result, res, 'refers', refersProp

  processExraProps result, fieldDesc, res unless result.isError

  res # compile =

# пропускаем целое позитивное число

takePositiveInt = (result, value) ->
  unless typeof value == 'number' && !isNaN(value) && Number.isInteger(value) && value > 0

    result.error 'dsc.invalidValue', value: value;
    return

  value # parseLength =

takeNoneNegativeInt = (result, value) ->
  unless typeof value == 'number' && !isNaN(value) && Number.isInteger(value) && value >= 0

    result.error 'dsc.invalidValue', value: value;
    return

  value # parseLength =

takeBoolean = (result, value) ->
  unless typeof value == 'boolean'

    result.error 'dsc.invalidValue', value: value;
    return

  value # takeBoolean =

takeString = (result, value) ->
  if typeof value == 'string'

    return value

  result.error 'dsc.invalidValue', value: value;
  return # takeString =

takeStringOrArrayOfStrings = (result, value) ->
  if typeof value == 'string'

    return value

  else if Array.isArray value

    return value unless value.some (s) -> typeof s != 'string'

  result.error 'dsc.invalidValue', value: value;
  return # takeStringOrArrayOfStrings =

# enum может быть или массив строк или строка, со значениями разделеннымм запятыми.
# массив должен быть не пустой. значения в нем уникальными. пустых строк быть не должно.

takeEnum = (result, value) ->

  return value if typeof value == 'object' and value != null and value.hasOwnProperty('$$list') # это случается при использовании enum в udTypes

  res = sortedMap result, value, string: true, boolean: true

  copyExtra result, res unless result.isError

  sortedMap.finish result, res unless result.isError

  res

# присваиваем значение в res, если оно есть.  а если значения нет - добавляем ошибку

setRequiredProp = (result, res, propName, value) ->
  if typeof value == 'undefined'

    result.error 'dsc.missingProp', value: propName;

    return

  res[propName] = value

  return # setRequiredProp =

# ----------------------------

module.exports = compile

compile._builtInTypes = builtInTypes

compile._reservedTypes = reservedTypes

compile._typeProps = typeProps

compile._extraProps = extraProps
