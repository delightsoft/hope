{err: {tooManyArgs, invalidArg, isResult}} = require '../utils'

Result = require '../result'

processUdtypes = require './_processUdtypes'

processDocs = require './_processDocs'

processAPI = require './_processAPI'

# TODO: Add opts - to add DSValue implementations

compile = (result, sourceConfig) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'sourceConfig', fieldDesc unless typeof sourceConfig == 'object' && sourceConfig != null
  tooManyArgs() unless arguments.length <= 2

  config = $$src: sourceConfig

  processUdtypes result, config

  processDocs result, config

  processAPI result, config

  unless result.isError

    delete config.$$src

    config # compile =

# ----------------------------

module.exports = compile

module.exports._processFields = require './_processFields'

module.exports._processActions = require './_processActions'

module.exports._processStates = require './_processStates'

module.exports._processUdtypes = require './_processUdtypes'
