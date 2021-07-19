prettyPrint = require './_prettyPrint'

_argError = (reason, name, value) ->

  new Error "#{reason} '#{name}': #{prettyPrint value}" # _argError =

# ----------------------------

module.exports =

  notEnoughArgs: -> throw new Error "Not enough arguments"; return
  tooManyArgs: -> throw new Error "Too many arguments"; return

  invalidArg: invalidArg = (name, value) -> throw _argError 'Invalid argument', name, value; return

  unknownOption: (name) -> throw new Error "Unknown option: '#{name}'"; return
  missingRequiredOption: (name) -> throw new Error "Missing required option: '#{name}'"; return
  invalidOption: (name, value) -> throw _argError 'Invalid option', name, value; return

  invalidProp: (name) -> throw new Error "Invalid property #{name}"; return
  invalidPropValue: (name, value) -> throw _argError 'Invalid value of propery', name, value; return

  reservedPropName: (name, value) -> throw _argError 'Reserved prop is used', name, value; return

  _argError: _argError

  # Прим.: С instanceof Result возникают проблемы в спецификациях, так как они регулярно сбрасывают require.cache.
  # Так что надо определять result по другим признакам

  # Как result, считаются объекты не только типа Result, но Report

  isResult: isResult = (result) ->

    typeof result == 'object' && result != null && result.hasOwnProperty('isError') # isResult =

  checkResult: (result) ->

    invalidArg 'result', result unless isResult result
