{invalidArg, unknownOption} = require '../../utils/_err'

defaultInit =
  string: ''
  text: ''
  boolean: false
  integer: 0
  double: 0
#  decimal: '0'
  time: null
  date: null
  timestamp: null
#  json:
#  blob:
#  uuid:
#  enum:

EMPTY = {}

hasOwnProperty = Object::hasOwnProperty

$$fixBuilder = (fields) ->

  newFuncs = []

  for field in fields.$$list

    do ->

      name = field.name

      init = undefined

      index = field.$$index

      if field.type == 'structure'

        init = $$fixBuilder(field.fields)

      else if field.type == 'subtable'

        if field.required

          do (fields = field.fields) ->

            init = (options) -> [fields.$$fix EMPTY, options]

            return

        else

          init = []

      else if field.hasOwnProperty('init')

        init = field.init

      else if field.null

        init = null

      else if defaultInit.hasOwnProperty(field.type)

        init = defaultInit[field.type]

      else if field.type == 'enum'

        init = field.enum.$$list[0].name

      else

        init = null

      if typeof init == 'function'

        newVal = ((res, options) -> res[name] = init(options); return)

      else

        newVal = ((res) -> res[name] = init; return)

      if field.type == 'structure'

        fix = $$fixBuilder(field.fields)

        copyVal = (res, fieldsLevel, options) ->

          res[name] = fix(fieldsLevel[name], options)

          return

      else if field.type == 'subtable'

        fix = field.fields.$$fix

        copyVal = (res, fieldsLevel, options) ->

          res[name] = for row in fieldsLevel[name]

            fix(row, options)

          return

      else

        copyVal = (res, fieldsLevel) ->

          res[name] = fieldsLevel[name]

      newFuncs.push (res, fieldsLevel, mask, options) ->

        if not mask or mask.get(index)

          if hasOwnProperty.call fieldsLevel, name

            copyVal res, fieldsLevel, options

          else

            newVal res, options

  (fieldsLevel, options) ->

    edit = false

    mask = undefined

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'edit' then edit = optValue

          when 'mask' then mask = optValue

          else unknownOption optName

    res = {}

    newFuncs.forEach ((f) -> f(res, fieldsLevel, mask, options); return)

    res.$$touched = {} if edit

    res # () ->

# ----------------------------

module.exports = $$fixBuilder
