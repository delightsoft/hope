{invalidArg, invalidOption, unknownOption} = require '../../utils/_err'

moment = require 'moment'

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

  fixFuncs = []

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

        initVal = ((res, options) -> res[name] = init(options); return)

      else

        initVal = ((res) -> res[name] = init; return)

      if field.type == 'structure'

        fix = $$fixBuilder(field.fields)

        copyVal = (res, update, options, fieldsLevel) ->

          if fieldsLevel and fieldsLevel.hasOwnProperty(name)

            res[name] = fix fieldsLevel[name], if update then Object.assign {}, options, {update: update[name]} else options

          else

            res[name] = fix update[name], Object.assign {}, options, {update: undefined}

          return

      else if field.type == 'subtable'

        fix = field.fields.$$fix

        copyVal = (res, update, options, fieldsLevel, copyIndex) ->

          opts = Object.assign {}, options, {update: undefined}

          res[name] =

            if fieldsLevel and fieldsLevel.hasOwnProperty(name)

              src = fieldsLevel[name]

              for row in update[name]

                if Number.isInteger(row._i) and 0 <= row._i < src.length

                  fix src[row._i], Object.assign {}, options, {update: row}

                else

                  fix row, opts

            else

              for row in update[name]

                r = fix row, opts

                r._i = row._i  if copyIndex and row.hasOwnProperty('_i') and not options.noIndex

                r

          if options?.edit

            row._i = i for row, i in res[name]

          return

      else

        copyVal = switch field.type

          when 'date'
            (res, fieldsLevel) ->
              res[name] = if fieldsLevel[name] == null then null else moment(fieldsLevel[name]).format('YYYY-MM-DD')
              return

          when 'time'
            (res, fieldsLevel) ->
              res[name] = if fieldsLevel[name] == null then null else "#{moment(fieldsLevel[name]).utc().format('HH:mm:ss.SSS')}Z"
              return

          when 'timestamp'
            (res, fieldsLevel) ->
              res[name] = if fieldsLevel[name] == null then null else "#{moment(fieldsLevel[name]).utc().format('YYYY-MM-DDTHH:mm:ss.SSS')}Z"
              return

          else
            (res, fieldsLevel) ->
              res[name] = fieldsLevel[name]
              return

      fixFuncs.push (res, fieldsLevel, mask, update, newVal, options) ->

        if not mask or mask.get(index)

          if update and hasOwnProperty.call update, name

            copyVal res, update, options, fieldsLevel

          else if hasOwnProperty.call fieldsLevel, name

            copyVal res, fieldsLevel, options, undefined, true

          else

            initVal res, options if newVal

  (fieldsLevel, options) ->

    invalidArg 'fieldsLevel', fieldsLevel unless typeof fieldsLevel == 'object' and fieldsLevel != null and not Array.isArray(fieldsLevel)

    edit = false

    mask = undefined

    update = undefined

    newVal = true

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'edit' # true, добавить в результат $$touched и _i в строках subtable

            invalidOption 'edit', optValue unless optValue == undefined or typeof optValue == 'boolean'

            edit = optValue if optValue != undefined

          when 'mask' # маска полей, которые надо оставить в результате (по умолчанию undefined - все поля)

            invalidOption 'mask', optValue unless optValue == undefined or (typeof optValue == 'object' and optValue != null and optValue._collection != fields)

            mask = optValue

          when 'update' # обновление накладываемле поверх данных (по умолчанию undefined)

            invalidOption 'update', optValue unless optValue == undefined or (typeof optValue == 'object' and optValue != null and not Array.isArray(optValue))

            update = optValue

          when 'newVal' # true, создавать недостающие поля с начальными значениями (по умолчанию true)

            invalidOption 'newVal', optValue unless optValue == undefined or typeof optValue == 'boolean'

            newVal = optValue if optValue != undefined

          when 'noIndex' # true, не копировать свойство _i в строках subtable (по умолчанию false)

            invalidOption 'noIndex', optValue unless optValue == undefined or typeof optValue == 'boolean'

          else unknownOption optName

    res = {}

    fixFuncs.forEach ((f) -> f(res, fieldsLevel, mask, update, newVal, options); return)

    res.$$touched = {} if edit

    res # () ->

# ----------------------------

module.exports = $$fixBuilder
