var _argError, invalidArg, isResult, prettyPrint;

prettyPrint = require('./_prettyPrint');

_argError = function(reason, name, value) {
  return new Error(reason + " '" + name + "': " + (prettyPrint(value)));
};

module.exports = {
  notEnoughArgs: function() {
    throw new Error("Not enough arguments");
  },
  tooManyArgs: function() {
    throw new Error("Too many arguments");
  },
  invalidArg: invalidArg = function(name, value) {
    throw _argError('Invalid argument', name, value);
  },
  invalidArgValue: function(name, value) {
    throw _argError('Invalid value of argument', name, value);
  },
  unknownOption: function(name) {
    throw new Error("Unknown option; '" + name + "'");
  },
  missingRequiredOption: function(name) {
    throw new Error("Missing required option; '" + name + "'");
  },
  invalidProp: function(name) {
    throw new Error("Invalid property " + name);
  },
  invalidPropValue: function(name, value) {
    throw _argError('Invalid value of propery', name, value);
  },
  reservedPropName: function(name, value) {
    throw _argError('Reserved prop is used', name, value);
  },
  _argError: _argError,
  isResult: isResult = function(result) {
    return typeof result === 'object' && result !== null && result.hasOwnProperty('isError');
  },
  checkResult: function(result) {
    if (!isResult(result)) {
      invalidArg('result', result);
    }
    if (!!result.isError) {
      throw new Error("Argument 'result' already has error");
    }
  }
};
