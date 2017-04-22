var _add, index, invalidArg, notEnoughArgs, ref, tooManyArgs;

ref = require('../utils').err, invalidArg = ref.invalidArg, notEnoughArgs = ref.notEnoughArgs, tooManyArgs = ref.tooManyArgs;

_add = function(index, path) {
  if (!(arguments.length > 0)) {
    notEnoughArgs();
  }
  if (typeof path !== 'string') {
    invalidArg('path', name);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  path += "[" + index + "]";
  return path;
};

index = function(index, pathFunc) {
  if (!(arguments.length > 0)) {
    notEnoughArgs();
  }
  if (typeof index !== 'number') {
    invalidArg('index', index);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  if (arguments.length === 1) {
    return function(path) {
      return _add(index, path);
    };
  }
  if (typeof pathFunc === 'function') {
    return function(path) {
      return _add(index, pathFunc(path));
    };
  }
  invalidArg('pathFunc', pathFunc);
};

module.exports = index;
