Result = require '../result'

validateBuilder = require '../validate'

processExtraProps = (result, fieldDesc, res) ->

  validator = undefined

  copyIfValid = (prop) ->

    if fieldDesc.hasOwnProperty(prop)

      result.isError = false

      result.context ((path) -> (Result.prop prop) path), ->

        (validator || (validator = validateBuilder res)) result, fieldDesc.init

      res[prop] = fieldDescres[prop] unless result.isError

  if fieldDesc.type in ['string', 'text']

    if fieldDesc.hasOwnProperty('min')

      unless typeof fieldDesc.min == 'number' and Number.isInteger(fieldDesc.min) and fieldDesc.min > 0

        result.error ((path) -> (Result.prop 'min') path), 'dsc.invalidValue', value: fieldDesc.min

      unless fieldDesc.min <= res.length

        result.error ((path) -> (Result.prop 'min') path), 'dsc.tooBig', value: fieldDesc.min

      else

        res.min = fieldDesc.min

    if fieldDesc.type == 'text'

      if fieldDesc.hasOwnProperty('max')

        unless typeof fieldDesc.max == 'number' and Number.isInteger(fieldDesc.max) and fieldDesc.max > 0

          result.error ((path) -> (Result.prop 'max') path), 'dsc.invalidValue', value: fieldDesc.max

        unless res.hasOwnProperty('min') and fieldDesc.max < res.min

          result.error ((path) -> (Result.prop 'max') path), 'dsc.tooSmall', value: fieldDesc.max

        else

          res.max = fieldDesc.max

  else if fieldDesc.type in ['integer', 'double', 'decimal']

    result.isError = false

    copyIfValid 'min'

    copyIfValid 'max'

    if !result.isError && res.hasOwnProperty('min') && res.hasOwnProperty('max') && res.min > res.max

      result.error ((path) -> (Result.prop 'max') path), 'dsc.tooSmall', value: fieldDesc.max

  copyIfValid 'init' if fieldDesc.hasOwnProperty('init')

  res # processExtraProps =

# ----------------------------

module.exports = processExtraProps
