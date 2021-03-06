Result = require '../result'

validateBuilder = require '../validate'

processExtraProps = (result, fieldDesc, res) ->

  validator = undefined

  copyAndValidateProp = (prop) ->

    result.context (Result.prop prop), ->

      opts =

        result: result

        strict: true

        beforeAction: true

      (validator || (validator = validateBuilder res)).call opts, fieldDesc[prop], undefined, undefined, undefined

    res[prop] = fieldDesc[prop]

  if ~['string', 'text'].indexOf(res.type)

     if fieldDesc.hasOwnProperty('regexp') then do ->

       regexp = fieldDesc.regexp

       ok = false

       if typeof regexp == 'string'

         if (i = regexp.lastIndexOf('/')) > 0

           try

             res.regexp = new RegExp (regexp.substr 1, i - 1), (regexp.substr i + 1)

             ok = true

           catch err

             result.error ((path) -> (Result.prop 'regexp') path), 'dsc.invalidRegexp', value: regexp, msg: err.message

       else if regexp instanceof RegExp

         res.regexp = regexp

         ok = true

       result.error ((path) -> (Result.prop 'regexp') path), 'dsc.invalidValue', value: regexp unless ok

     if fieldDesc.hasOwnProperty('min')

      unless typeof fieldDesc.min == 'number' and Number.isInteger(fieldDesc.min) and fieldDesc.min > 0

        result.error ((path) -> (Result.prop 'min') path), 'dsc.invalidValue', value: fieldDesc.min

      unless fieldDesc.type == 'text' or fieldDesc.min <= res.length

        result.error ((path) -> (Result.prop 'min') path), 'dsc.tooBig', value: fieldDesc.min

      res.min = fieldDesc.min

    if fieldDesc.type == 'text'

      if fieldDesc.hasOwnProperty('max')

        unless typeof fieldDesc.max == 'number' and Number.isInteger(fieldDesc.max) and fieldDesc.max > 0

          result.error ((path) -> (Result.prop 'max') path), 'dsc.invalidValue', value: fieldDesc.max

        if res.hasOwnProperty('min') and res.min > fieldDesc.max

          result.error ((path) -> (Result.prop 'max') path), 'dsc.tooSmall', value: fieldDesc.max

        res.max = fieldDesc.max

  else if ~['integer', 'double', 'decimal'].indexOf(res.type)

    copyAndValidateProp 'min' if fieldDesc.hasOwnProperty('min')

    copyAndValidateProp 'max' if fieldDesc.hasOwnProperty('max')

#    if res.type == 'decimal'
#
#      unless res.hasOwnProperty('max')
#
#        res.max = Math.pow(10, res.precision) - 1
#
#      else
#
#        if res.max > (Math.pow(10, res.precision) - 1)
#
#          result.error ((path) -> (Result.prop 'max') path), 'dsc.tooLongForThisPrecision', value: fieldDesc.max, precision: res.precision
#
#      unless res.hasOwnProperty('min')
#
#        res.min = -(Math.pow(10, res.precision) - 1)
#
#      else
#
#        if res.min < -(Math.pow(10, res.precision) - 1)
#
#          result.error ((path) -> (Result.prop 'min') path), 'dsc.tooLongForThisPrecision', value: fieldDesc.min, precision: res.precision
#
#      res.min = -(Math.pow(10, res.precision) - 1) unless res.hasOwnProperty('min')

    if not result.isError and res.hasOwnProperty('min') and res.hasOwnProperty('max') and res.min > res.max

      result.error ((path) -> (Result.prop 'max') path), 'dsc.tooSmall', value: fieldDesc.max, min: res.min

  validator = undefined

  if fieldDesc.hasOwnProperty('init') and not result.isError and not ~['structure', 'subtable'].indexOf(res.type)

    copyAndValidateProp 'init'

  res # processExtraProps =

# ----------------------------

module.exports = processExtraProps
