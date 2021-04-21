{err: {tooManyArgs, invalidArg, isResult}} = require '../utils'

Result = require '../result'

processUdtypes = require './_processUdtypes'

processUdtypeFields = require './_processUdtypeFields'

processDocs = require './_processDocs'

processAPI = require './_processAPI'

compile = (result, sourceConfig, noSystemItems) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'sourceConfig', sourceConfig unless typeof sourceConfig == 'object' && sourceConfig != null

  config = $$src: sourceConfig

  processUdtypes result, config

  console.info 24, result, config

  processUdtypeFields result, config

  processDocs result, config, noSystemItems

  processAPI result, config, noSystemItems

  unless result.isError

    delete config.$$src

    delete config.udtypes

    config # compile =

# ----------------------------

module.exports = compile

module.exports._processFields = require './_processFields'

module.exports._processActions = require './_processActions'

module.exports._processStates = require './_processStates'

module.exports._processUdtypes = require './_processUdtypes'
