{checkItemName, err: {tooManyArgs, invalidArg, invalidArgValue, isResult}} = require '../utils'

Result = require '../result'

sortedMap = require '../sortedMap'

#typeProps = ['length', 'enum', 'precision', 'scale', 'fields', 'refers', 'valueClass', 'null']
typeProps = ['length', 'enum', 'fields', 'refers', 'valueClass', 'null']

builtInTypes = [
  'string', 'text', 'boolean'
  # 'integer', 'long', 'float', 'double', 'decimal'
  'integer', 'double'
  'decimal'
  'time', 'date', 'dateonly', 'now'
  'json', 'blob', 'uuid',  'enum'
  'structure',  'subtable'
  'refers'
  'dsvalue'
]

reservedTypes = ['long', 'float']

compile = (result, fieldDesc, res, opts) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'fieldDesc', fieldDesc unless typeof fieldDesc == 'object' && fieldDesc != null
  invalidArg 'res', fieldDesc unless res == undefined || (typeof res == 'object' && res != null && !Array.isArray(res))
  invalidArg 'opts', opts unless opts == undefined || (typeof opts == 'object' && opts != null && !Array.isArray(opts))
  tooManyArgs() unless arguments.length <= 4

  unless opts?.hasOwnProperty('context') # list of prop that should not be reported in validation
    optsContext = null # any
  else
    invalidArgValue 'opts.context', opts.context unless (optsContext = opts.context) == 'field' || optsContext == 'udtype'

  throw new Error "fieldDesc was already process by tags/compile()" unless not fieldDesc.hasOwnProperty '$$tags'

# Определяем тип.  То что в скобках выделяем в options.

  if fieldDesc.hasOwnProperty('type')

    if (optionsIndex = (type = sourceType = fieldDesc.type.trim()).indexOf '(') != -1

      unless (optionsEnd = (options = type.indexOf ')')) > optionsIndex # missing ) or it's before (
        result.error 'dsc.invalidTypeValue', value: type; return

      unless optionsEnd == type.length - 1 # something after )
        result.error 'dsc.invalidTypeValue', value: type; return

      if (optionsLen = optionsEnd - optionsIndex - 1) == 0
        result.error 'dsc.invalidTypeValue', value: type; return

      options = type.substr optionsIndex + 1, optionsLen
      type = type.substr(0, optionsIndex).trim()

    unless checkItemName type

      result.error 'dsc.invalidTypeValue', value: type; return

# Если тип не указан, пробуем его определить по косвенному признаку

  else if fieldDesc.hasOwnProperty('enum')

    type = 'enum'

  else if fieldDesc.hasOwnProperty('fields')

    type = 'structure'

  else if fieldDesc.hasOwnProperty('refers')

    type = 'refers'

  else

    result.error 'dsc.missingProp', value: 'type'; return

# Заменяем короткие имена типов на полные

  switch type

    when 'str' then type = 'string'

    when 'bool' then type = 'boolean'

    when 'int' then type = 'integer'

    when 'struct' then type = 'structure'

    when 'ref' then type = 'refers'

    when 'value' then type = 'dsvalue'

# Проверяем, что тип входит в список типов

  unless builtInTypes.indexOf(type) >= 0

    if reservedTypes.indexOf(type) >= 0 # reserved type name

      result.error 'dsc.reservedType', value: sourceType

    else if options # udType cannot have an option

      result.error 'dsc.unknownType', value: sourceType

    else # user defined type

      result.context ((path) -> (Result.prop prop) path), ->

        for prop in typeProps when fieldDesc.hasOwnProperty(prop) && prop != 'null' # udType can have null in a field definition

          result.error 'dsc.notApplicableForTheTypeProp', name: prop, type: type

      res.udType = type

      if typeof nullProp == 'boolean'

        res.null = nullProp

      return res unless result.isError

    return

  if (optsContext == null || optsContext == 'field') && type == 'dsvalue'

    result.error 'dsc.notAllowedInFieldDef', value: type

    return

# Проверяем, наличие всех свойств относящихся к типу.  Если свойство не должно быть у данного типа, добавляем ошибку

  prop = lengthProp = enumProp = precisionProp = scaleProp = fieldsProp = nullProp = refersProp = valueClass = undefined

  if fieldDesc.hasOwnProperty('udType')

    result.error 'dsc.reservedAttr', value: 'udType'

  result.context ((path) -> (Result.prop prop) path), ->

    for prop in typeProps when fieldDesc.hasOwnProperty(prop)

      ok = false

      switch prop

        when 'length' then if (ok = type == 'string') then lengthProp = takePositiveInt result, fieldDesc.length

        when 'enum' then if (ok = type == 'enum') then enumProp = takeEnum result, fieldDesc.enum

        when 'precision' then if (ok = type == 'decimal') then precisionProp = takePositiveInt result, fieldDesc.precision

        when 'scale' then if (ok = type == 'decimal') then scaleProp = takePositiveInt result, fieldDesc.scale

        when 'fields' then if (ok = (type == 'structure' || type == 'subtable')) then fieldsProp = takeFields result, fieldDesc.fields

        when 'null'

          if optsContext == null || optsContext == 'field'

            if (ok = not (type == 'now' || type == 'structure' || type == 'subtable')) then nullProp = takeBoolean result, fieldDesc.null

          else

            ok = true

            result.error 'dsc.notApplicableInUdtype'

        when 'refers' then if (ok = (type == 'refers')) then refersProp = takeStringOrArrayOfStrings result, fieldDesc.refers

      unless ok

        result.error 'dsc.notApplicableForTheTypeProp', name: prop, type: type

# работаем с length для string

  return if result.isError

  if options

    result.context ((path) -> (Result.prop "(#{options})") path), ->

      switch type

        when 'string'

          lengthPropFromOptions = takePositiveInt result, parseFloat options

          if lengthProp

            result.error 'dsc.ambiguousProp', name: 'length', value1: (lengthPropFromOptions || options), value2: lengthProp

          else

            lengthProp = lengthPropFromOptions

        when 'refers'

          if (refersPropFromOptions = options.trim()).length == 0

            result.error 'dsc.invalidValue', value: options

          else if refersProp

            result.error 'dsc.ambiguousProp', name: 'refers', value1: (refersPropFromOptions || options), value2: refersProp

          else

            refersProp = refersPropFromOptions

        else

          result.error 'dsc.unknownType', value: sourceType

# собираем результирующую структуру

  return if result.isError

  res.type = type

  if typeof nullProp == 'boolean'

    res.null = nullProp if nullProp

  switch type

    when 'string' then setRequiredProp result, res, 'length', lengthProp

    when 'enum' then setRequiredProp result, res, 'enum', enumProp

    when 'decimal'

      setRequiredProp result, res, 'precision', precisionProp

      res.scale = scaleProp if typeof scaleProp == 'number'

    when 'structure' then setRequiredProp result, res, 'fields', fieldsProp

    when 'subtable' then setRequiredProp result, res, 'fields', fieldsProp

    when 'refers' then setRequiredProp result, res, 'refers', refersProp

  res # compile =

# пропускаем целое позитивное число

takePositiveInt = (result, value) ->

  unless typeof value == 'number' && !isNaN(value) && Number.isInteger(value) && value > 0

    result.error 'dsc.invalidValue', value: value; return

  value # parseLength =

takeBoolean = (result, value) ->

  unless typeof value == 'boolean'

    result.error 'dsc.invalidValue', value: value; return

  value # takeBoolean =

takeString = (result, value) ->

  if typeof value == 'string'

    return value

  result.error 'dsc.invalidValue', value: value; return # takeString =

takeStringOrArrayOfStrings = (result, value) ->

  if typeof value == 'string'

    return value

  else if Array.isArray value

    ok = true

    return value unless value.some (s) -> typeof s != 'string'

  result.error 'dsc.invalidValue', value: value; return # takeStringOrArrayOfStrings =

# enum может быть или массив строк или строка, со значениями разделеннымм запятыми.
# массив должен быть не пустой. значения в нем уникальными. пустых строк быть не должно.

takeEnum = (result, value) ->

  sortedMap result, value, string: true, boolean: true

# fields это map элементов, где элементы это описание вложенных полей

takeFields = (result, value) ->

  sortedMap result, value

  # TODO: Add fields processing

# присваиваем значение в res, если оно есть.  а если значения нет - добавляем ошибку

setRequiredProp = (result, res, propName, value) ->

    if typeof value == 'undefined'

      result.error 'dsc.missingProp', value: propName; return

    res[propName] = value

    return # setRequiredProp =

# ----------------------------

module.exports = compile

compile._builtInTypes = builtInTypes

compile._reservedTypes = reservedTypes

compile._typeProps = typeProps
