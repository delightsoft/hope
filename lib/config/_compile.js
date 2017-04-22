var Result, compile, invalidArg, isResult, processDocs, processUdtypes, ref, tooManyArgs;

ref = require('../utils').err, tooManyArgs = ref.tooManyArgs, invalidArg = ref.invalidArg, isResult = ref.isResult;

Result = require('../result');

processUdtypes = require('./_processUdtypes');

processDocs = require('./_processDocs');

compile = function(result, sourceConfig) {
  var config;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof sourceConfig === 'object' && sourceConfig !== null)) {
    invalidArg('sourceConfig', fieldDesc);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  config = {
    $$src: sourceConfig
  };
  processUdtypes(result, config);
  processDocs(result, config);
  if (!result.isError) {
    delete config.$$src;
    return config;
  }
};

module.exports = compile;

module.exports._processFields = require('./_processFields');

module.exports._processActions = require('./_processActions');

module.exports._processStates = require('./_processStates');

module.exports._processUdtypes = require('./_processUdtypes');
