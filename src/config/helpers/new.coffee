{invalidArg, unknownOption} = require '../../utils/_err'

defaultInit =
  string: ''
  text: ''
  boolean: false
  integer: 0
  double: 0
#  decimal: '0'
#  time:
#  date:
#  dateonly:
#  timestamp:
#  json:
#  blob:
#  uuid:
#  enum:

$$newBuilder = (fields) ->

  newFuncs = []

  for field in fields.$$list

    do ->

      name = field.name

      init = undefined

      if field.type == 'structure'

        init = $$newBuilder(field.fields)

      else if field.type == 'subtable'

        if field.required

          do ->

            $$new = field.fields.$$new

            init = (options) -> [$$new options]

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

        newFuncs.push ((res, options) ->

          res[name] = init(options); return)

      else

        newFuncs.push ((res) -> res[name] = init; return)

  (options) ->

    edit = false

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'edit' then edit = !!optValue

          else unknownOption optName

    res = {}

    newFuncs.forEach ((f) -> f(res, options); return)

    res.$$touched = {} if edit

    res # () ->

# ----------------------------

module.exports = $$newBuilder
